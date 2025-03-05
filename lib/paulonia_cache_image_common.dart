import 'dart:ui' as ui;

import 'package:paulonia_cache_image/cache_refresh_strategy.dart';

class PCacheImageService {
  PCacheImageService() {
    rConstructor();
  }
  Future<void> rConstructor() async {}

  static Future<void> init({String? proxy}) async {
    return Future.value();
  }

  // get image
  static Future<ui.Codec> getImage(
    String url,
    Duration retryDuration,
    Duration maxRetryDuration,
    bool enableCache, {
    bool clearCacheImage = false,
    required CacheRefreshStrategy cacheRefreshStrategy,
  }) {
    // ignore: null_argument_to_non_null_type
    return Future.value();
  }

  // get directory path
  static Future<dynamic> clearAllImages() {
    return Future.value();
  }
}
