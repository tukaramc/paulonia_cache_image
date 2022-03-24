// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_cache_image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveCacheImageAdapter extends TypeAdapter<HiveCacheImage> {
  @override
  final int typeId = 17;

  @override
  HiveCacheImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCacheImage(
      remotePath: fields[0] as String,
      version: fields[2] as int?,
      binaryImage: fields[1] as Uint8List?,
      localPath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCacheImage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.remotePath)
      ..writeByte(1)
      ..write(obj.binaryImage)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.localPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCacheImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
