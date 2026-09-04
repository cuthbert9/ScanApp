# API Implementation

This document lists the HTTP API endpoints the scanning app requires. Two sections follow: MVP endpoints (urgent, required to demonstrate scanning and load-plan flow) and Other endpoints (useful features and remaining server functionality).

All endpoints use JSON for requests and responses unless noted otherwise. Authentication is via `Authorization: Bearer <token>` header where applicable.

**Response format convention (JSON)**
- Success: HTTP 200 (or 201 for created resources) with a top-level object (not raw array).
- Errors: use consistent error objects: `{ "error": "<error_code>", "message": "Human-friendly explanation", "details": {...} }`

---

## MVP Endpoints (urgent)

These endpoints are the minimum required to demonstrate the scanning app flow: login, fetch load plan (loading queue assigned to an operator), fetch items for a load plan including barcode identifiers, and submit scans that update item status.

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
- Description: Return all active load plans assigned to the given operator (the app presents these as the loading queue).
- Auth: Required
- Response 200:

```json
{
  "loadplans": [
    {
      "id": "lp_001",
      "reference": "LOAD-001",
      "status": "assigned",
      "assigned_at": "2026-09-04T08:00:00Z",
      "station_id": "station_1",
      "expected_items_count": 12
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
- Description: Return the list of items (or picks) for the load plan. Each item includes barcode(s) used for scanning.
- Auth: Required
- Response 200:

```json
{
  "items": [
    {
      "id": "item_001",
      "sku": "SKU-12345",
      "description": "Blue Widget",
      "barcode": "0123456789012",
      "expected_quantity": 5,
      "scanned_quantity": 2,
      "status": "partial"
    }
  ]
}
```

- Notes: If an item has multiple barcode types, return `barcodes: ["...","..."]`.

4) Scan submission (single scan)
- Method: POST
- Path: `/loadplans/{loadPlanId}/scans` (or `/scans` with `loadplan_id` in body)
- Description: Submit a scanned barcode. Server resolves the barcode to an item on the load plan and updates its scanned quantity/status. Returns the updated item state or an informative error when the barcode is unknown or the scan cannot be applied.
- Auth: Required
- Request:

```json
{
  "operator_id": "op_123",
  "device_id": "dev_456",       
  "barcode": "0123456789012",
  "timestamp": "2026-09-04T09:10:00Z",
  "metadata": { "scan_source": "hardware_trigger" }
}
```

- Response 200 (scan accepted and item updated):

```json
{
  "result": "updated",
  "item": {
    "id": "item_001",
    "sku": "SKU-12345",
    "barcode": "0123456789012",
    "expected_quantity": 5,
    "scanned_quantity": 3,
    "status": "partial"
  }
}
```

- Response 201 (if scan completes the expected quantity and transitions item status):

```json
{
  "result": "completed",
  "item": { ... }
}
```

- Error cases:
  - 404 Not Found (barcode not found in system):

```json
{
  "error": "barcode_not_found",
  "message": "Barcode 0123456789012 is not recognised",
  "suggested_action": "Verify barcode or create item in back office"
}
```

  - 400 Bad Request (scan not applicable to this load plan):

```json
{
  "error": "not_on_load",
  "message": "Scanned item does not belong to this load plan",
  "item_ref": null
}
```

  - 409 Conflict (duplicate scan or over-quantity):

```json
{
  "error": "duplicate_scan",
  "message": "Item already scanned at this time",
  "existing_scan": { "timestamp": "...", "operator_id": "..." }
}
```

- Notes: For offline operation, the app may batch scans and POST them to `/sync/scans` (see Other endpoints).

5) Fetch item details by barcode (optional helper used by the client)
- Method: GET
- Path: `/items/by-barcode/{barcode}`
- Description: Resolve a barcode to system item record (global lookup). Useful to show item info when scanning before updating.
- Response 200:

```json
{
  "item": {
    "id": "item_001",
    "sku": "SKU-12345",
    "description": "Blue Widget",
    "barcodes": ["0123456789012"],
    "attributes": { }
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
- Create item, add barcode(s): POST `/items`
- Update item: PATCH `/items/{id}`
- List item history / audit: GET `/items/{id}/history`

5) Station and device management
- GET `/stations` and `/stations/{id}`
- Register device: POST `/devices` (device_id, device_type)

6) Bulk scan sync (offline support)
- Method: POST
- Path: `/sync/scans`
- Description: Upload a batch of scans collected offline. Server reconciles, returns per-scan results.
- Request example:

```json
{
  "operator_id": "op_123",
  "device_id": "dev_456",
  "scans": [
    { "barcode": "0123...", "timestamp": "...", "metadata": {} },
    { "barcode": "..." }
  ]
}
```

- Response 200:

```json
{
  "results": [
    { "index": 0, "status": "updated", "item_id": "item_001" },
    { "index": 1, "status": "barcode_not_found", "message": "..." }
  ]
}
```

7) Search / lookup endpoints
- GET `/items/search?q=...` — fuzzy search on SKU, description, barcode

8) Reconciliation / adjustments
- POST `/items/{id}/adjustments` — manual quantity adjustments with reason

9) Reporting / export
- GET `/reports/loadplan/{id}` — export pick report CSV/JSON

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
- Use consistent error objects as specified above.
- Keep scan endpoint idempotent where reasonable — repeated identical scans should not corrupt counts.
- Return helpful suggestions on errors like unknown barcode (e.g., create item link or admin action id).
- Consider optimistic concurrency or ETags on loadplan/item updates to avoid race conditions when multiple devices scan the same item at once.



--
Generated by developer request to list required server endpoints for the scanning app.
