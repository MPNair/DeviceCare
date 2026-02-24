import 'gadget.dart';

class Folder {
  final String id;
  final String name;
  final String? description;
  final String folderType;
  final String? parentId;
  final List<Folder> subFolders;
  final List<Gadget> gadgets;

  Folder({
    required this.id,
    required this.name,
    this.description,
    this.folderType = 'custom',
    this.parentId,
    this.subFolders = const [],
    this.gadgets = const [],
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      folderType: json['folderType'] ?? 'custom',
      parentId: json['parentId'],
      subFolders: json['subFolders'] != null
          ? (json['subFolders'] as List).map((i) => Folder.fromJson(i)).toList()
          : [],
      gadgets: json['gadgets'] != null
          ? (json['gadgets'] as List).map((i) => Gadget.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'folderType': folderType,
      'parentId': parentId,
    };
  }
}
