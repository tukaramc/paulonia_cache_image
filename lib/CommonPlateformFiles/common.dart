import 'dart:io';

class CommonPlatformService {
  CommonPlatformService() {
    rConstructor();
  }
  Future<void> rConstructor() async {}

  static Future<Directory> getDirectoryPath() {
    return Future.value(Directory.current);
  }
}
