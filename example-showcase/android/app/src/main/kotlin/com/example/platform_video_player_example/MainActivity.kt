package com.example.pro_video_player_example

import io.flutter.embedding.android.FlutterFragmentActivity

// Must extend FlutterFragmentActivity (not FlutterActivity) for Chromecast support.
// MediaRouteButton.showDialog() requires FragmentActivity to show the device picker.
class MainActivity : FlutterFragmentActivity()
