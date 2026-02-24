class MaintenanceLog {
  final String id;
  final String serviceType;
  final String? description;
  final double cost;
  final DateTime serviceDate;
  final String? technicianDetails;
  final String? documentUrl;

  MaintenanceLog({
    required this.id,
    required this.serviceType,
    this.description,
    required this.cost,
    required this.serviceDate,
    this.technicianDetails,
    this.documentUrl,
  });

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) {
    return MaintenanceLog(
      id: json['id'],
      serviceType: json['serviceType'],
      description: json['description'],
      cost: json['cost'].toDouble(),
      serviceDate: DateTime.parse(json['serviceDate']),
      technicianDetails: json['technicianDetails'],
      documentUrl: json['documentUrl'],
    );
  }
}
