import 'dart:async';
import 'dart:io';
// import 'package:paulonia_cache_image/paulonia_cache_image_web.dart';

class CommonPlatformService {
  CommonPlatformService() {
    rConstructor();
  }

  Future<void> rConstructor() async {}

  static Future<Directory> getDirectoryPath() {
    return Future.value(Directory.current);
  }
}
