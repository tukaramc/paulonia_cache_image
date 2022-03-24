// ignore_for_file: constant_identifier_names
enum CacheRefreshStrategy {
  // PROGRESSIVE and NATIVE use the Storage Object updated timestamp as a version
  // number and checks for updates every time.
  NATIVE,
  
  PROGRESSIVE,
  
  // NEVER will never check for any updates. It will still reload a previously-
  // cached version that has been cleaned up by the OS.
  NONE,
}
