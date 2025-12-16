/// The way in which the video was originally loaded.
///
/// This has nothing to do with the video's file type. It's just the place
/// from which the video is fetched from.
///
/// This enum is provided for compatibility with Flutter's video_player library.
enum DataSourceType {
  /// The video was loaded from a remote URL (HTTP/HTTPS).
  network,

  /// The video was loaded from a local file on the device.
  file,

  /// The video was loaded from a Flutter asset bundled with the app.
  asset,

  /// The video was loaded from a content URI (Android only).
  ///
  /// This is treated the same as [file] on our platform.
  contentUri,
}
