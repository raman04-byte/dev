import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? image;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {'category_name': name, 'image': image};
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json[r'$id'] as String,
      name: json['category_name'] as String,
      image: json['image'] as String?,
      createdAt: DateTime.parse(json[r'$createdAt'] as String),
      updatedAt: DateTime.parse(json[r'$updatedAt'] as String),
    );
  }
}
