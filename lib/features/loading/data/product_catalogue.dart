/// One line of the product master.
class CatalogueItem {
  const CatalogueItem({
    required this.gtin,
    required this.name,
    required this.packSize,
    required this.weightKg,
    required this.volumeM3,
    this.isColdChain = false,
  });

  final String gtin;

  /// As printed on the manifest, e.g. `Amoxicillin 250 mg`.
  final String name;

  /// Units per pack — the `× 1000` on a feed row.
  final int packSize;

  /// Gross mass of one pallet of this item. Summed across verified scans to
  /// give the load's weight utilisation.
  final double weightKg;

  /// Volume of one pallet, for the same reason.
  final double volumeM3;

  final bool isColdChain;
}

/// Stand-in for the product master the backend will serve.
///
/// Lookup accepts a GTIN or an SSCC: a pallet label carries the serial shipping
/// container code, and the operator should not have to care which one their
/// scanner produced.
abstract final class ProductCatalogue {
  static const CatalogueItem amoxicillin = CatalogueItem(
    gtin: '03600980000441',
    name: 'Amoxicillin 250 mg',
    packSize: 1000,
    weightKg: 239,
    volumeM3: 1.5,
  );
  static const CatalogueItem ors = CatalogueItem(
    gtin: '03600980000442',
    name: 'ORS Sachets 20.5 g',
    packSize: 500,
    weightKg: 205,
    volumeM3: 1.2,
  );
  static const CatalogueItem paracetamol = CatalogueItem(
    gtin: '03600980000443',
    name: 'Paracetamol 500 mg',
    packSize: 1000,
    weightKg: 260,
    volumeM3: 1.6,
  );
  static const CatalogueItem malariaTest = CatalogueItem(
    gtin: '03600980000444',
    name: 'mRDT Malaria Test',
    packSize: 25,
    isColdChain: true,
    weightKg: 95,
    volumeM3: 0.9,
  );
  static const CatalogueItem zincSulfate = CatalogueItem(
    gtin: '03600980000445',
    name: 'Zinc Sulfate 20 mg',
    packSize: 500,
    weightKg: 214,
    volumeM3: 1.3,
  );
  static const CatalogueItem rutf = CatalogueItem(
    gtin: '03600980000446',
    name: 'RUTF Sachets 92 g',
    packSize: 150,
    weightKg: 310,
    volumeM3: 1.8,
  );
  static const CatalogueItem oxytocin = CatalogueItem(
    gtin: '03600980000447',
    name: 'Oxytocin 10 IU',
    packSize: 100,
    isColdChain: true,
    weightKg: 180,
    volumeM3: 1.1,
  );

  static const List<CatalogueItem> all = <CatalogueItem>[
    amoxicillin,
    ors,
    paracetamol,
    malariaTest,
    zincSulfate,
    rutf,
    oxytocin,
  ];

  /// Pallet SSCC to the product it carries.
  ///
  /// Real SSCCs are allocated per pallet, so in production this is a lookup
  /// against the dispatch system rather than a constant.
  static const Map<String, String> _ssccToGtin = <String, String>{
    '3600980000004401': '03600980000441',
    '3600980000004402': '03600980000442',
    '3600980000004403': '03600980000443',
    '3600980000004404': '03600980000444',
    '3600980000004405': '03600980000445',
    '3600980000004406': '03600980000446',
    '3600980000004407': '03600980000447',
  };

  /// Resolves a GTIN or SSCC to a catalogue line, or null when nothing matches.
  static CatalogueItem? lookup(String? key) {
    if (key == null || key.isEmpty) return null;

    final String gtin = _ssccToGtin[key] ?? key;
    for (final CatalogueItem item in all) {
      if (item.gtin == gtin) return item;
    }

    // Tolerate a GTIN that lost its leading zeros somewhere upstream.
    final String padded = gtin.padLeft(14, '0');
    for (final CatalogueItem item in all) {
      if (item.gtin == padded) return item;
    }
    return null;
  }
}
