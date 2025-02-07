import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:paulonia_cache_image/constants.dart';
import 'package:paulonia_cache_image/hive_cache_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paulonia_cache_image/cache_refresh_strategy.dart';
import 'package:paulonia_cache_image/utils.dart';
import 'package:http/http.dart' as http;

/// Paulonia cache image service for mobile
///
/// This class has all function to download, store and get the images.
class PCacheImageService {
  /// Temporal directory path
  static late String _tempPath;

  /// Codec used to convert the image url to base 64; the id of the images in
  /// the storage.
  static final Codec<String, String> _stringToBase64 = utf8.fuse(base64);

  /// Hive box used to store the image as a persistent storage
  static var _cacheBox = Hive.box(Constants.HIVE_CACHE_IMAGE_BOX);
  static get cacheBox => _cacheBox;

  /// Initialize the service on mobile
  ///
  /// This function initialize the path of the temporal directory
  /// [proxy] is unused in this service.
  static Future<void> init({String? proxy}) async {
    _tempPath = (await getApplicationDocumentsDirectory()).path;
  }

  /// Get the image codec
  ///
  /// This function gets the image codec of [url]. It verifies if the image is
  /// in cache and returns it if [enableCache] is true. If the images is not in cache
  /// then the function download the image and stores in cache if [enableCache]
  /// is true.
  static Future<ui.Codec> getImage(String url, Duration retryDuration,
      Duration maxRetryDuration, bool enableCache,
      {bool clearCacheImage = false,
      required CacheRefreshStrategy cacheRefreshStrategy}) async {
    Uint8List bytes;
    String id = _stringToBase64.encode(url);

    String path = _tempPath + '/' + id;
    final File file = File(path);

    if (cacheRefreshStrategy == CacheRefreshStrategy.NONE) {
      if (clearCacheImage && fileIsCached(file)) {
        file.deleteSync();
        await deleteHiveImage(url);
      }
      if (fileIsCached(file)) {
        bytes = file.readAsBytesSync();
      } else {
        bytes = await downloadImage(url, retryDuration, maxRetryDuration);
        if (bytes.lengthInBytes != 0) {
          if (enableCache) {
            saveFile(url, bytes, 0);
          }
        } else {
          /// TODO The image can't be downloaded
          return ui.instantiateImageCodec(Uint8List(0));
        }
      }
      return ui.instantiateImageCodec(bytes);
    } else {
      HiveCacheImage? cacheImage = getHiveImage(url);

      /// means gcsAdvanceCache is true
      if (cacheImage != null &&
          cacheRefreshStrategy == CacheRefreshStrategy.NATIVE) {
        checkForUpdate(
            hiveCacheImage: cacheImage,
            file: file,
            cacheRefreshStrategy: cacheRefreshStrategy);
      } else {
        await checkForUpdate(
            hiveCacheImage: cacheImage,
            gcsUrl: url,
            file: file,
            cacheRefreshStrategy: cacheRefreshStrategy);
      }

      bytes = file.readAsBytesSync();
      return ui.instantiateImageCodec(bytes);
    }
  }

  /// Clears all the images from the local storage
  static Future<dynamic> clearAllImages() async {
    await _cacheBox.close();
    await _cacheBox.deleteFromDisk();
    _cacheBox = await Hive.openBox(Constants.HIVE_CACHE_IMAGE_BOX);
    Directory directory = await getApplicationDocumentsDirectory();
    directory.deleteSync(recursive: true);
    _tempPath = (await getApplicationDocumentsDirectory()).path;
    return 'success';
  }

  /// Downloads the image
  ///
  /// If the [url] is a Google Cloud Storage url, then the function get the download
  /// url. The function sends a GET requests to [url] and return the binary response.
  /// If there is an error in the requests, then the function retry the download
  /// after [retryDuration]. If the accumulated time of the retry attempts is
  /// greater than [maxRetryDuration] then the function returns an empty list
  /// of bytes.
  @visibleForTesting
  static Future<Uint8List> downloadImage(
    String url,
    Duration retryDuration,
    Duration maxRetryDuration,
  ) async {
    int totalTime = 0;
    Uint8List bytes = Uint8List(0);
    Duration _retryDuration = Duration(microseconds: 1);
    if (Utils.isGsUrl(url)) url = await (_getStandardUrlFromGsUrl(url));
    while (
        totalTime <= maxRetryDuration.inSeconds && bytes.lengthInBytes <= 0) {
      await Future.delayed(_retryDuration).then((_) async {
        try {
          http.Response response = await http.get(Uri.parse(url));
          bytes = response.bodyBytes;
          if (bytes.lengthInBytes <= 0) {
            _retryDuration = retryDuration;
            totalTime += retryDuration.inSeconds;
          }
        } catch (error) {
          _retryDuration = retryDuration;
          totalTime += retryDuration.inSeconds;
        }
      });
    }
    return bytes;
  }

  static Future<void> checkForUpdate(
      {HiveCacheImage? hiveCacheImage,
      String? gcsUrl,
      required File file,
      required CacheRefreshStrategy cacheRefreshStrategy}) async {
    Reference reference = getRefFromGsUrl(
        hiveCacheImage == null ? gcsUrl! : hiveCacheImage.remotePath);

    int remoteVersion =
        (await reference.getMetadata()).updated?.millisecondsSinceEpoch ?? -1;

    // means image exits in cache
    if (hiveCacheImage != null) {
      if (remoteVersion != hiveCacheImage.version) {
        // If true, download new image for next load
        await upsertRemoteFileToCache(
            hiveCacheImage.remotePath, reference, remoteVersion);
      }
    } else {
      // means image not exits in cache
      await upsertRemoteFileToCache(gcsUrl!, reference, remoteVersion);
    }
  }

  // get bytes from firebase storage and save to hive
  static Future<Uint8List?> upsertRemoteFileToCache(
      String gcsUrl, Reference reference, int version) async {
    Uint8List? bytes = await remoteFileBytes(reference);
    saveFile(
      gcsUrl,
      bytes!,
      version,
    );
    return bytes;
  }

  // get bytes from firebase storage
  static Future<Uint8List?> remoteFileBytes(Reference reference) async {
    return await reference.getData();
  }

  // get firebase reference
  static Reference getRefFromGsUrl(String remotePath) {
    Uri uri = Uri.parse(remotePath);
    String bucketName = '${uri.scheme}://${uri.authority}';
    FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: bucketName);
    return storage.ref().child(uri.path);
  }

  /// Verifies if [file] is stored on cache
  @visibleForTesting
  static bool fileIsCached(File file) {
    if (file.existsSync() && file.lengthSync() > 0) {
      return true;
    }
    return false;
  }

  /// Delete the image form the hive storage
  @visibleForTesting
  static Future<void> deleteHiveImage(String url) {
    String id = _stringToBase64.encode(url);
    return _cacheBox.delete(id);
  }

  /// Get the image form the hive storage
  @visibleForTesting
  static HiveCacheImage? getHiveImage(String url) {
    String id = _stringToBase64.encode(url);
    if (!_cacheBox.containsKey(id)) return null;
    return _cacheBox.get(id);
  }

  /// Saves the file in the local storage // version means timestamp
  @visibleForTesting
  static void saveFile(String remotePath, Uint8List bytes, int version) {
    String id = _stringToBase64.encode(remotePath);
    String path = _tempPath + '/' + id;
    final File file = File(path);
    file.create(recursive: true);
    file.writeAsBytesSync(bytes);

    HiveCacheImage cacheImage = HiveCacheImage(
        remotePath: remotePath, version: version, localPath: file.path);
    _cacheBox.put(id, cacheImage);
  }

  /// Get the network from a [gsUrl]
  ///
  /// This function get the download url from a Google Cloud Storage url
  static Future<dynamic> _getStandardUrlFromGsUrl(String gsUrl) async {
    Uri uri = Uri.parse(gsUrl);
    String bucketName = '${uri.scheme}://${uri.authority}';
    FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: bucketName);
    return await storage.ref().child(uri.path).getDownloadURL();
  }
}
