import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:paulonia_cache_image/constants.dart';

part 'hive_cache_image.g.dart';

@HiveType(typeId: Constants.HIVE_ADAPTER_ID)
class HiveCacheImage {
  @HiveField(0)
  String remotePath;

  @HiveField(1)
  Uint8List? binaryImage;

  @HiveField(2)
  int? version;

  @HiveField(3)
  String? localPath;

  HiveCacheImage({
    required this.remotePath,
    required this.version,
    this.binaryImage,
    this.localPath,
  });
}
