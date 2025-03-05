class CommonPlatformService {
  CommonPlatformService() {
    rConstructor();
  }
  Future<void> rConstructor() async {}

  static Future<void> init({String? proxy}) async {
    return Future.value();
  }

  static Future getDirectoryPath() {
    print('calling only common class ****');
    return Future.value();
  }
}
