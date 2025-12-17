import 'mock_js_interop.dart';
import 'web_test_constants.dart';

/// Simulates the `canplay` event on a video element.
///
/// This event fires when enough data is available to start playing.
void simulateCanPlay(MockHTMLVideoElement element) {
  element.readyState = 4; // HAVE_ENOUGH_DATA
  element.triggerEvent('canplay');
}

/// Simulates the `loadedmetadata` event with video metadata.
///
/// This event fires when the video's metadata (duration, dimensions) is loaded.
void simulateLoadedMetadata(MockHTMLVideoElement element, {double? duration, double? width, double? height}) {
  element.duration = duration ?? WebTestMetadata.duration.inMilliseconds / 1000.0;
  element.videoWidth = width ?? WebTestSizes.videoWidth;
  element.videoHeight = height ?? WebTestSizes.videoHeight;
  element.readyState = 1; // HAVE_METADATA
  element.triggerEvent('loadedmetadata');
}

/// Simulates a `timeupdate` event at a specific playback position.
///
/// This event fires periodically as video plays to update current position.
void simulateTimeUpdate(MockHTMLVideoElement element, double timeInSeconds) {
  element.currentTime = timeInSeconds;
  element.triggerEvent('timeupdate');
}

/// Simulates buffering state changes.
///
/// When [isBuffering] is true, fires `waiting` event. When false, fires
/// `canplay` or `playing` event depending on playback state.
void simulateBuffering(MockHTMLVideoElement element, bool isBuffering) {
  if (isBuffering) {
    element.readyState = 2; // HAVE_CURRENT_DATA
    element.triggerEvent('waiting');
  } else {
    element.readyState = 4; // HAVE_ENOUGH_DATA
    if (!element.paused) {
      element.triggerEvent('playing');
    } else {
      element.triggerEvent('canplay');
    }
  }
}

/// Simulates the `ended` event.
///
/// This event fires when video playback reaches the end.
void simulateEnded(MockHTMLVideoElement element) {
  element.ended = true;
  element.paused = true;
  element.currentTime = element.duration;
  element.triggerEvent('ended');
}

/// Simulates an error event.
///
/// [code] is the error code (1-4), [message] is the error message.
void simulateError(MockHTMLVideoElement element, {int code = 2, String message = 'Media error'}) {
  element.triggerEvent('error', {'code': code, 'message': message});
}

/// Simulates a stalled network event.
///
/// This event fires when the browser is trying to get media data but no data
/// is arriving.
void simulateStalled(MockHTMLVideoElement element) {
  element.networkState = 2; // NETWORK_LOADING
  element.triggerEvent('stalled');
}

/// Simulates volume change.
void simulateVolumeChange(MockHTMLVideoElement element, double volume) {
  element.volume = volume;
  element.triggerEvent('volumechange');
}

/// Simulates playback rate change.
void simulateRateChange(MockHTMLVideoElement element, double rate) {
  element.playbackRate = rate;
  element.triggerEvent('ratechange');
}

/// Simulates duration change.
void simulateDurationChange(MockHTMLVideoElement element, double duration) {
  element.duration = duration;
  element.triggerEvent('durationchange');
}

/// Simulates seeking state.
void simulateSeeking(MockHTMLVideoElement element) {
  element.triggerEvent('seeking');
}

/// Simulates seeked (seeking complete) state.
void simulateSeeked(MockHTMLVideoElement element) {
  element.triggerEvent('seeked');
}

/// Simulates entering Picture-in-Picture.
void simulateEnterPip(MockHTMLVideoElement element) {
  element.triggerEvent('enterpictureinpicture');
}

/// Simulates leaving Picture-in-Picture.
void simulateLeavePip(MockHTMLVideoElement element) {
  element.triggerEvent('leavepictureinpicture');
}

/// Simulates entering fullscreen.
void simulateEnterFullscreen(MockHTMLVideoElement element) {
  element.triggerEvent('fullscreenchange');
}

/// Simulates leaving fullscreen.
void simulateLeaveFullscreen(MockHTMLVideoElement element) {
  element.triggerEvent('fullscreenchange');
}

/// Simulates progress event (data buffering).
void simulateProgress(MockHTMLVideoElement element) {
  element.triggerEvent('progress');
}

/// Creates a complete mock video element with sensible defaults.
MockHTMLVideoElement createMockVideoElement({
  String src = '',
  double duration = 60.0,
  double width = 1920.0,
  double height = 1080.0,
  double currentTime = 0.0,
  bool paused = true,
}) {
  final element = MockHTMLVideoElement()
    ..src = src
    ..duration = duration
    ..videoWidth = width
    ..videoHeight = height
    ..currentTime = currentTime
    ..paused = paused;

  return element;
}
