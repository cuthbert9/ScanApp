# API Implementation

This document lists the HTTP API endpoints the scanning app requires. Three sections follow: the data model every endpoint shares, MVP endpoints (urgent, required to demonstrate scanning and load-plan flow) and Other endpoints (useful features and remaining server functionality).

All endpoints use JSON for requests and responses unless noted otherwise. Authentication is via `Authorization: Bearer <token>` header where applicable.

**Response format convention (JSON)**
- Success: HTTP 200 (or 201 for created resources) with a top-level object (not raw array).
- Errors: use consistent error objects: `{ "error": "<error_code>", "message": "Human-friendly explanation", "details": {...} }`. Anything beyond `error` and `message` goes inside `details`.

**Field naming:** `snake_case` everywhere. Note that `seed_data.json` currently uses camelCase for some fields (`loadPlans`, `operatorId`, `batchNumber`, `serialNumber`, `expiryDate`); the API should expose them as `batch_number`, `serial_number`, `expiry_date`, etc.

---

## Data model: one box per item

Read this before the endpoints — every request and response below follows from it.

- A **load plan** is a list of **items** to be loaded onto one truck for one destination.
- Each **item is one physical box** (a container/case), identified by its own unique GS1 serial number. An item has **no quantity** — it is never "partly" scanned. There is no `expected_quantity`, `scanned_quantity` or `remaining_quantity` anywhere in this API.
- An item's `status` is `pending` until its box is scanned, then `scanned`. *(Exact vocabulary to confirm with backend.)*
- **Progress lives only on the load plan**: `expected_items_count`, `completed_items_count`, `remaining_items_count`. Each accepted scan increments `completed_items_count` by exactly 1 and decrements `remaining_items_count` by exactly 1.

### GS1 barcodes

The label on each box is a GS1 barcode made of *element strings*, each an Application Identifier (AI) in brackets followed by its value:

```
(01)29999990000013(17)290128(10)TESTB001(21)TESTSN000001
```

| AI | Name | Identifies | Example |
|---|---|---|---|
| `01` | GTIN (Global Trade Item Number) | The **product** — the same on every box of it | `29999990000013` |
| `17` | Expiry date, `YYMMDD` | — | `290128` → 2029-01-28 |
| `10` | Batch / lot number | The production batch | `TESTB001` |
| `21` | Serial number | **This one box** | `TESTSN000001` |

**The serial (AI 21) is what identifies an item.** The GTIN only says what product a box contains; many boxes on the same load plan can share a GTIN (and a batch). Matching a scan on GTIN alone cannot tell those boxes apart — see the matching rules under *Scan submission*.

---

## MVP Endpoints (urgent)

These endpoints are the minimum required to demonstrate the scanning app flow: login, fetch load plans (loading queue assigned to an operator), fetch the items (boxes) on a load plan including their GS1 data, and submit scans that mark boxes as scanned.

1) Login
- Method: POST
- Path: `/auth/login`
- Description: Authenticate operator and return an access token.
- Request (application/json):

```json
{
  "username": "operator1",
  "password": "secret"
}
```

- Response 200:

```json
{
  "token": "eyJhbGci...",
  "expires_in": 3600,
  "user": {
    "id": "op_123",
    "username": "operator1",
    "name": "Jane Doe",
    "role": "operator"
  }
}
```

- Errors:
  - 401 Unauthorized: `{ "error": "invalid_credentials", "message": "Invalid username or password" }`

2) Fetch operator's Load Plans (Loading Queue)
- Method: GET
- Path: `/operators/{operatorId}/loadplans` (alternatively `/loadplans?operator_id={id}`)
- Description: Return all active load plans assigned to the given operator (the app presents these as the loading queue). Include the progress counters, so the queue can show progress without fetching each load plan separately.
- Auth: Required
- Response 200:

```json
{
  "loadplans": [
    {
      "id": "e574081f-cf1b-465d-9d45-ef10f334d6df",
      "reference": "LP-202609-00001",
      "status": "assigned",
      "assigned_at": "2026-09-10T07:30:00Z",
      "truck": {
        "id": "1152a56d-f435-4894-84db-12b6a43391f7",
        "registration_number": "T 421 DKV"
      },
      "destination": "Dodoma Zonal Store",
      "expected_items_count": 7,
      "completed_items_count": 0,
      "remaining_items_count": 7
    }
  ]
}
```

- Errors:
  - 403 Forbidden (not allowed)
  - 404 Not Found (operator not found)

3) Fetch items for a Load Plan
- Method: GET
- Path: `/loadplans/{loadPlanId}/items`
- Description: Return every item (box) on the load plan, with the GS1 data printed on its label.
- Auth: Required
- Response 200:

```json
{
  "items": [
    {
      "id": "787775b9-6bca-4c89-882b-a7aaf9f1ef30",
      "sku": "PCM-500",
      "description": "Paracetamol 500 mg",
      "barcodes": [
        "29999990000013",
        "(01)29999990000013(17)290128(10)TESTB001(21)TESTSN000001"
      ],
      "status": "pending",
      "batch_number": "TESTB001",
      "serial_number": "TESTSN000001",
      "expiry_date": "2029-01-28",
      "gs1": "(01)29999990000013(17)290128(10)TESTB001(21)TESTSN000001",
      "scanned_at": null,
      "scanned_by": null
    }
  ]
}
```

- Notes:
  - `barcodes` is always an array: the bare GTIN plus the full GS1 string.
  - `gs1` is the full label string; `batch_number`, `serial_number` and `expiry_date` are its decoded values, provided so the client does not have to parse them for display. They must agree with `gs1`.
  - `scanned_at` / `scanned_by` are `null` while `pending`, and set when the box is scanned.

4) Scan submission (single scan)
- Method: POST
- Path: `/loadplans/{loadPlanId}/scans` (or `/scans` with `loadplan_id` in body)
- Description: Submit one scanned barcode. The server resolves it to one box on the load plan, marks that box `scanned`, and updates the load plan's counters.
- Auth: Required. The operator is taken from the token, not the request body.
- Request:

```json
{
  "client_scan_id": "5b1f7c2e-8a4d-4c1e-9f3a-2d6e8b0a7c41",
  "device_id": "dev_456",
  "barcode": "(01)29999990000013(17)290128(10)TESTB001(21)TESTSN000001",
  "timestamp": "2026-09-10T09:10:00Z",
  "metadata": { "scan_source": "hardware_trigger" }
}
```

- Request fields:
  - `client_scan_id` — a UUID the app generates once per physical scan. A retry of the same scan (after a timeout, or from offline sync) sends the same id, and the server returns the original result instead of applying it again.
  - `barcode` — **the raw string exactly as scanned**, not a value the app has normalised. It may be a full GS1 string (bracketed, or concatenated with FNC1 separators) or a bare GTIN.

- Matching rules (server side), in order:
  1. If the barcode contains a serial (AI 21): match the item with that serial. This is the normal case.
  2. Else, if it contains GTIN and batch (AI 01 + AI 10): match the single `pending` item with that GTIN and batch.
  3. Else, if it is a bare GTIN: match only if **exactly one** `pending` item on this load plan has that GTIN.
  4. If rule 2 or 3 matches more than one pending box, return `ambiguous_barcode` — never pick one at random.

- Response 200 (box accepted and marked scanned):

```json
{
  "result": "scanned",
  "item": {
    "id": "787775b9-6bca-4c89-882b-a7aaf9f1ef30",
    "sku": "PCM-500",
    "serial_number": "TESTSN000001",
    "status": "scanned",
    "scanned_at": "2026-09-10T09:10:00Z",
    "scanned_by": "c77e4c35-3c09-4046-b7e6-717279ff8ab6"
  },
  "loadplan": {
    "id": "e574081f-cf1b-465d-9d45-ef10f334d6df",
    "status": "assigned",
    "expected_items_count": 7,
    "completed_items_count": 1,
    "remaining_items_count": 6
  }
}
```

- Notes: Every accepted scan returns 200 — scanning the last box is not a different status code. The client knows the load is complete when `remaining_items_count` reaches 0. Returning the load plan counters means the app does not need a second request after each scan.

- Error cases:
  - 404 Not Found (barcode matches no item in the system):

```json
{
  "error": "barcode_not_found",
  "message": "This barcode is not recognised.",
  "details": {
    "barcode": "(01)29999990000013(17)290128(10)TESTB001(21)TESTSN999999",
    "suggested_action": "Set the box aside and report it to the supervisor."
  }
}
```

  - 400 Bad Request (box exists but belongs to another load plan):

```json
{
  "error": "not_on_load",
  "message": "This box belongs to a different load plan.",
  "details": {
    "item_id": "582652fd-7a08-42aa-984a-81e638ce6469",
    "belongs_to_loadplan": {
      "id": "0b4243a7-9e30-4a51-981d-8236dc8b3a9c",
      "reference": "LP-202609-00002"
    }
  }
}
```

  - 409 Conflict (this box is already scanned — at any time, by anyone):

```json
{
  "error": "already_scanned",
  "message": "This box has already been scanned.",
  "details": {
    "item_id": "787775b9-6bca-4c89-882b-a7aaf9f1ef30",
    "scanned_at": "2026-09-10T09:10:00Z",
    "scanned_by": "c77e4c35-3c09-4046-b7e6-717279ff8ab6"
  }
}
```

  - 422 Unprocessable Entity (barcode matches more than one pending box — typically a bare GTIN):

```json
{
  "error": "ambiguous_barcode",
  "message": "Several boxes match this code. Scan the full GS1 label.",
  "details": {
    "gtin": "29999990000013",
    "matching_pending_items": 3
  }
}
```

- Notes: For offline operation, the app may batch scans and POST them to `/sync/scans` (see Other endpoints).

5) Fetch item details by barcode (optional helper used by the client)
- Method: GET
- Path: `/items/by-barcode?code={barcode}` (URL-encoded)
- Description: Resolve a barcode to an item record (global lookup, independent of any load plan). Useful to show what a box is before or after scanning it.
- Notes:
  - The barcode is a query parameter rather than part of the path, because a raw GS1 string can contain `(`, `)`, `/` and the invisible FNC1 separator.
  - Uses the same matching rules as scan submission. A full GS1 string with a serial returns that one box. A bare GTIN identifies a product, not a box: the response describes the product and may match many boxes.
- Response 200 (serial matched one box):

```json
{
  "item": {
    "id": "787775b9-6bca-4c89-882b-a7aaf9f1ef30",
    "sku": "PCM-500",
    "description": "Paracetamol 500 mg",
    "barcodes": [
      "29999990000013",
      "(01)29999990000013(17)290128(10)TESTB001(21)TESTSN000001"
    ],
    "status": "pending",
    "batch_number": "TESTB001",
    "serial_number": "TESTSN000001",
    "expiry_date": "2029-01-28",
    "gs1": "(01)29999990000013(17)290128(10)TESTB001(21)TESTSN000001",
    "loadplan_id": "e574081f-cf1b-465d-9d45-ef10f334d6df"
  }
}
```

- Errors:
  - 404 with `barcode_not_found` as above.


---

## Other Endpoints (future / non-MVP)

These endpoints are useful for full product functionality, reporting, admin and offline sync.

1) Logout
- Method: POST
- Path: `/auth/logout`
- Description: Invalidate refresh tokens / server-side session.
- Request: `{ "token": "..." }` or use current Authorization header
- Response 200: `{ "result": "ok" }`

2) User profile
- Method: GET
- Path: `/operators/{operatorId}`
- Description: Fetch operator profile and permissions.

3) LoadPlan CRUD
- Create: POST `/loadplans`
- Read: GET `/loadplans/{id}`
- Update: PATCH `/loadplans/{id}`
- Delete: DELETE `/loadplans/{id}`

4) Item CRUD / management
- Create item (one box, with its GS1 data): POST `/items`
- Update item: PATCH `/items/{id}`
- List item history / audit: GET `/items/{id}/history`

5) Station and device management
- GET `/stations` and `/stations/{id}`
- Register device: POST `/devices` (device_id, device_type)

6) Bulk scan sync (offline support)
- Method: POST
- Path: `/sync/scans`
- Description: Upload a batch of scans collected offline. The server applies each one with the same matching rules as single scan submission, in order, and returns a result per scan. Each scan keeps the `client_scan_id` it was given when it was scanned, so re-uploading a batch after a dropped connection never counts a box twice.
- Request example:

```json
{
  "device_id": "dev_456",
  "loadplan_id": "e574081f-cf1b-465d-9d45-ef10f334d6df",
  "scans": [
    {
      "client_scan_id": "5b1f7c2e-8a4d-4c1e-9f3a-2d6e8b0a7c41",
      "barcode": "(01)29999990000013(17)290128(10)TESTB001(21)TESTSN000001",
      "timestamp": "2026-09-10T09:10:00Z",
      "metadata": { "scan_source": "hardware_trigger" }
    },
    {
      "client_scan_id": "9e4a0d3b-1c7f-4b2a-8e5d-6f0c3a9b2e17",
      "barcode": "(01)29999990000020(17)300228(10)TESTB002(21)TESTSN000002",
      "timestamp": "2026-09-10T09:10:12Z",
      "metadata": { "scan_source": "hardware_trigger" }
    }
  ]
}
```

- Response 200:

```json
{
  "results": [
    {
      "client_scan_id": "5b1f7c2e-8a4d-4c1e-9f3a-2d6e8b0a7c41",
      "result": "scanned",
      "item_id": "787775b9-6bca-4c89-882b-a7aaf9f1ef30"
    },
    {
      "client_scan_id": "9e4a0d3b-1c7f-4b2a-8e5d-6f0c3a9b2e17",
      "result": "already_scanned",
      "message": "This box has already been scanned."
    }
  ],
  "loadplan": {
    "id": "e574081f-cf1b-465d-9d45-ef10f334d6df",
    "expected_items_count": 7,
    "completed_items_count": 1,
    "remaining_items_count": 6
  }
}
```

- Notes: `result` is `scanned` or one of the single-scan error codes (`barcode_not_found`, `not_on_load`, `already_scanned`, `ambiguous_barcode`).

7) Search / lookup endpoints
- GET `/items/search?q=...` — fuzzy search on SKU, description, GTIN, batch or serial number

8) Manual item status override
- POST `/items/{id}/status-override` — manually mark a box `scanned` or back to `pending`, with a required reason (e.g. label damaged and unreadable, box scanned by mistake). Moves the load plan counters by exactly one, like a scan, and is recorded in the audit log.
- Request: `{ "status": "scanned", "reason": "label_unreadable", "note": "Serial checked by eye" }`

9) Reporting / export
- GET `/reports/loadplan/{id}` — export load report CSV/JSON, one row per box with its serial, batch, expiry and scan time

10) Audit logs
- GET `/audit?entity=item&entity_id={id}`

11) Notifications / real-time
- WebSocket / Webhook endpoints to notify client of loadplan reassignments or cancellations.

12) App settings / configuration
- GET `/app/config` — returns settings, allowed scan types, allowed status transitions

13) Health & version
- GET `/health` — simple service health
- GET `/version` — server version and API version

14) Error codes documentation
- Provide a machine-readable `/errors` or include codes in API docs.

---

## Authentication & Headers
- `Authorization: Bearer <token>` — required for protected endpoints
- `Content-Type: application/json`
- `Accept: application/json`

## Notes & Recommendations
- Use consistent error objects as specified above, with extra fields inside `details`.
- **Idempotency:** the scan endpoints are idempotent per `client_scan_id`. A repeated request with the same id returns the original result and never moves the counters again. A *new* scan of a box that is already scanned (different `client_scan_id`) returns `already_scanned`.
- **Counters:** `completed_items_count` and `remaining_items_count` change only when an item's status changes, by exactly one, in the same transaction as the item update — so they can never disagree with the items.
- **Concurrent devices:** if two devices scan the same box at the same moment, exactly one gets `scanned` and the other gets `already_scanned`. Enforce this in the database (e.g. a conditional update on `status = 'pending'`), not only in application code.
- Return helpful suggestions on errors like unknown barcode (e.g., an admin action id), inside `details`.



--
Generated by developer request to list required server endpoints for the scanning app.
