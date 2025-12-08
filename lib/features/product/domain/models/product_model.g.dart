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
      productCode: fields[2] as String,
      barcode: fields[3] as String,
      photos: (fields[4] as List).cast<String>(),
      hsnCode: fields[5] as String,
      unit: fields[6] as String,
      description: fields[7] as String,
      saleGst: fields[8] as double,
      purchaseGst: fields[9] as double,
      mrp: fields[10] as double,
      reorderPoint: fields[11] as int,
      packagingSize: fields[12] as String,
      sizes: (fields[13] as List).cast<ProductSize>(),
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
      categoryId: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.productCode)
      ..writeByte(3)
      ..write(obj.barcode)
      ..writeByte(4)
      ..write(obj.photos)
      ..writeByte(5)
      ..write(obj.hsnCode)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.saleGst)
      ..writeByte(9)
      ..write(obj.purchaseGst)
      ..writeByte(10)
      ..write(obj.mrp)
      ..writeByte(11)
      ..write(obj.reorderPoint)
      ..writeByte(12)
      ..write(obj.packagingSize)
      ..writeByte(13)
      ..write(obj.sizes)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.categoryId);
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
      sizeName: fields[0] as String,
      price: fields[1] as double,
      stock: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProductSize obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sizeName)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.stock);
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
