import 'dart:async';
// import 'package:paulonia_cache_image/paulonia_cache_image_web.dart';

class CommonPlatformService {
  CommonPlatformService() {
    rConstructor();
  }

  Future<void> rConstructor() async {}

  static Future<dynamic> getDirectoryPath() {
    print('calling only web class ****');
    return Future.value();
  }
}
