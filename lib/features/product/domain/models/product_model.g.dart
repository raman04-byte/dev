// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 1;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      photos: (fields[2] as List).cast<String>(),
      hsnCode: fields[3] as String,
      unit: fields[4] as String,
      description: fields[5] as String,
      saleGst: fields[6] as double,
      purchaseGst: fields[7] as double,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      categoryId: fields[10] as String?,
      sizes: (fields[11] as List).cast<ProductSize>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.photos)
      ..writeByte(3)
      ..write(obj.hsnCode)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.saleGst)
      ..writeByte(7)
      ..write(obj.purchaseGst)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.categoryId)
      ..writeByte(11)
      ..write(obj.sizes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductSizeAdapter extends TypeAdapter<ProductSize> {
  @override
  final int typeId = 2;

  @override
  ProductSize read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductSize(
      id: fields[0] as String?,
      sizeName: fields[1] as String,
      productCode: fields[2] as String,
      barcode: fields[3] as String,
      mrp: fields[4] as double,
      stockQuantity: fields[5] as int,
      reorderPoint: fields[6] as int,
      packagingSize: fields[7] as int,
      weight: fields[8] as double,
      productId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductSize obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sizeName)
      ..writeByte(2)
      ..write(obj.productCode)
      ..writeByte(3)
      ..write(obj.barcode)
      ..writeByte(4)
      ..write(obj.mrp)
      ..writeByte(5)
      ..write(obj.stockQuantity)
      ..writeByte(6)
      ..write(obj.reorderPoint)
      ..writeByte(7)
      ..write(obj.packagingSize)
      ..writeByte(8)
      ..write(obj.weight)
      ..writeByte(9)
      ..write(obj.productId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductSizeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
