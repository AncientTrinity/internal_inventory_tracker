class AssetStats {
  final int totalAssets;
  final int inUse;
  final int inStorage;
  final int inRepair;
  final int retired;
  final int needsService;
  final int assetTypesCount;

  AssetStats({
    required this.totalAssets,
    required this.inUse,
    required this.inStorage,
    required this.inRepair,
    required this.retired,
    required this.needsService,
    required this.assetTypesCount,
  });

  factory AssetStats.fromJson(Map<String, dynamic> json) {
    return AssetStats(
      totalAssets: json['total_assets'],
      inUse: json['in_use'],
      inStorage: json['in_storage'],
      inRepair: json['in_repair'],
      retired: json['retired'],
      needsService: json['needs_service'],
      assetTypesCount: json['asset_types_count'],
    );
  }

  double get inUsePercentage => totalAssets > 0 ? inUse / totalAssets : 0;
  double get needsServicePercentage => totalAssets > 0 ? needsService / totalAssets : 0;
}