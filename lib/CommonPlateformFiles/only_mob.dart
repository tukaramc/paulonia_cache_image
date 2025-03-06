import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;

class CommonPlatformService {
  CommonPlatformService() {
    rConstructor();
  }

  Future<void> rConstructor() async {}

  // get directory path
  static Future<Directory> getDirectoryPath() async {
    return await path_provider.getApplicationDocumentsDirectory();
  }
}
