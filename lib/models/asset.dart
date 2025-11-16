class Asset {
  final int id;
  final String internalId;
  final String assetType;
  final String manufacturer;
  final String model;
  final String modelNumber;
  final String serialNumber;
  final String status;
  final int? inUseBy;
  final DateTime? datePurchased;
  final DateTime? lastServiceDate;
  final DateTime? nextServiceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Asset({
    required this.id,
    required this.internalId,
    required this.assetType,
    required this.manufacturer,
    required this.model,
    required this.modelNumber,
    required this.serialNumber,
    required this.status,
    this.inUseBy,
    this.datePurchased,
    this.lastServiceDate,
    this.nextServiceDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      internalId: json['internal_id'],
      assetType: json['asset_type'],
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      modelNumber: json['model_number'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      status: json['status'],
      inUseBy: json['in_use_by'],
      datePurchased: json['date_purchased'] != null 
          ? DateTime.parse(json['date_purchased']) 
          : null,
      lastServiceDate: json['last_service_date'] != null 
          ? DateTime.parse(json['last_service_date']) 
          : null,
      nextServiceDate: json['next_service_date'] != null 
          ? DateTime.parse(json['next_service_date']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isAssigned => inUseBy != null;
  bool get needsService => nextServiceDate != null && 
      nextServiceDate!.isBefore(DateTime.now());
}