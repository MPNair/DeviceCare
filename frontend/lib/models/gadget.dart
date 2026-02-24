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
    this.cost = 0.0,
    required this.serviceDate,
    this.technicianDetails,
    this.documentUrl,
  });

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) {
    return MaintenanceLog(
      id: json['id'],
      serviceType: json['serviceType'],
      description: json['description'],
      cost: (json['cost'] ?? 0.0).toDouble(),
      serviceDate: DateTime.parse(json['serviceDate']),
      technicianDetails: json['technicianDetails'],
      documentUrl: json['documentUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceType': serviceType,
      'description': description,
      'cost': cost,
      'serviceDate': serviceDate.toIso8601String().split(
        'T',
      )[0], // Backend expects YYYY-MM-DD
      'technicianDetails': technicianDetails,
      'documentUrl': documentUrl,
    };
  }
}

class Gadget {
  final String id;
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime purchaseDate;
  final double purchasePrice;
  final DateTime? warrantyExpiryDate;
  final int conditionScore;
  final String status;
  final List<String> imageUrls;
  final double? currentEstimatedValue;
  final double? depreciationAdjustedValue;

  // New Fields
  final String? storageCapacity;
  final String? color;
  final String? purchaseStore;
  final Map<String, dynamic>? technicalSpecs;
  final List<Map<String, dynamic>>
  documents; // [{name: string, url: string, folderId?: string}]
  final int? warrantyPeriod;
  final String? folderId;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? ownershipStatus;
  final String? room;
  final List<MaintenanceLog> logs;

  Gadget({
    required this.id,
    required this.name,
    required this.category,
    this.brand,
    this.model,
    this.serialNumber,
    required this.purchaseDate,
    required this.purchasePrice,
    this.warrantyExpiryDate,
    this.conditionScore = 10,
    this.status = 'active',
    this.imageUrls = const [],
    this.currentEstimatedValue,
    this.depreciationAdjustedValue,
    this.storageCapacity,
    this.color,
    this.purchaseStore,
    this.technicalSpecs,
    this.documents = const [],
    this.warrantyPeriod,
    this.folderId,
    this.tags = const [],
    this.customFields = const {},
    this.ownershipStatus,
    this.room,
    this.logs = const [],
  });

  factory Gadget.fromJson(Map<String, dynamic> json) {
    return Gadget(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      brand: json['brand'],
      model: json['model'],
      serialNumber: json['serialNumber'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      purchasePrice: json['purchasePrice'].toDouble(),
      warrantyExpiryDate: json['warrantyExpiryDate'] != null
          ? DateTime.parse(json['warrantyExpiryDate'])
          : null,
      conditionScore: json['conditionScore'] ?? 10,
      status: json['status'] ?? 'active',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      currentEstimatedValue: json['currentEstimatedValue']?.toDouble(),
      depreciationAdjustedValue: json['depreciationAdjustedValue']?.toDouble(),
      storageCapacity: json['storageCapacity'],
      color: json['color'],
      purchaseStore: json['purchaseStore'],
      technicalSpecs: json['technicalSpecs'],
      documents: json['documents'] != null
          ? List<Map<String, dynamic>>.from(json['documents'])
          : [],
      warrantyPeriod: json['warrantyPeriod'],
      folderId: json['folderId'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      customFields: json['customFields'] ?? {},
      ownershipStatus: json['ownershipStatus'],
      room: json['room'],
      logs: json['logs'] != null
          ? (json['logs'] as List)
                .map((i) => MaintenanceLog.fromJson(i))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'warrantyExpiryDate': warrantyExpiryDate?.toIso8601String(),
      'conditionScore': conditionScore,
      'status': status,
      'imageUrls': imageUrls,
      'currentEstimatedValue': currentEstimatedValue,
      'depreciationAdjustedValue': depreciationAdjustedValue,
      'storageCapacity': storageCapacity,
      'color': color,
      'purchaseStore': purchaseStore,
      'technicalSpecs': technicalSpecs,
      'documents': documents,
      'warrantyPeriod': warrantyPeriod,
      'folderId': folderId,
      'tags': tags,
      'customFields': customFields,
      'ownershipStatus': ownershipStatus,
      'room': room,
    };
  }
}
