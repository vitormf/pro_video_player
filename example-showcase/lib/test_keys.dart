// ignore_for_file: avoid_classes_with_only_static_members - Necessary: provides namespace organization for test keys, alternative would pollute global namespace

import 'package:flutter/material.dart';

/// Test keys for UI elements in the example app.
///
/// These keys are used by integration tests to find and interact with
/// specific widgets in the app.
abstract final class TestKeys {
  // ---------------------------------------------------------------------------
  // Home Screen
  // ---------------------------------------------------------------------------
  static const homeScreenPlayerFeaturesCard = Key('home_player_features_card');
  static const homeScreenVideoSourcesCard = Key('home_video_sources_card');
  static const homeScreenAdvancedFeaturesCard = Key('home_advanced_features_card');
  static const homeScreenLayoutModesCard = Key('home_layout_modes_card');
  static const homeScreenEventsLogCard = Key('home_events_log_card');
  static const homeScreenPlatformDemoCard = Key('home_platform_demo_card');
  static const homeScreenStreamSelectionCard = Key('home_stream_selection_card');
  static const homeScreenPlaylistCard = Key('home_playlist_card');
  static const homeScreenQualitySelectionCard = Key('home_quality_selection_card');
  static const homeScreenSubtitleConfigCard = Key('home_subtitle_config_card');
  static const homeScreenThemesGesturesCard = Key('home_themes_gestures_card');
  static const homeScreenCustomThemesCard = Key('home_custom_themes_card');
  static const homeScreenBackgroundPlaybackCard = Key('home_background_playback_card');
  static const homeScreenScalingModesCard = Key('home_scaling_modes_card');
  static const homeScreenMediaControlsCard = Key('home_media_controls_card');
  static const homeScreenPipActionsCard = Key('home_pip_actions_card');
  static const homeScreenNetworkResilienceCard = Key('home_network_resilience_card');
  static const homeScreenPlayerToolbarConfigCard = Key('home_player_toolbar_config_card');
  static const homeScreenCastingCard = Key('home_casting_card');
  static const homeScreenChaptersCard = Key('home_chapters_card');

  // ---------------------------------------------------------------------------
  // Player Features Screen
  // ---------------------------------------------------------------------------
  static const playerFeaturesPlayPauseButton = Key('player_features_play_pause');
  static const playerFeaturesSeekBackwardButton = Key('player_features_seek_backward');
  static const playerFeaturesSeekForwardButton = Key('player_features_seek_forward');
  static const playerFeaturesVolumeSlider = Key('player_features_volume_slider');
  static const playerFeaturesSpeedDropdown = Key('player_features_speed_dropdown');
  static const playerFeaturesLoopSwitch = Key('player_features_loop_switch');
  static const playerFeaturesFullscreenTile = Key('player_features_fullscreen_tile');
  static const playerFeaturesPipTile = Key('player_features_pip_tile');
  static const playerFeaturesProgressSlider = Key('player_features_progress_slider');
  static const playerFeaturesPositionText = Key('player_features_position_text');
  static const playerFeaturesDurationText = Key('player_features_duration_text');
  static const playerFeaturesStateText = Key('player_features_state_text');
  static const playerFeaturesVideoPlayer = Key('player_features_video_player');
  static const playerFeaturesFullscreenExitButton = Key('player_features_fullscreen_exit');

  // ---------------------------------------------------------------------------
  // Video Sources Screen
  // ---------------------------------------------------------------------------
  static const videoSourcesVideoPlayer = Key('video_sources_video_player');
  static const videoSourcesPlayButton = Key('video_sources_play_button');
  static const videoSourcesLoadingIndicator = Key('video_sources_loading');
  static const videoSourcesErrorDisplay = Key('video_sources_error');
  static const videoMetadataCard = Key('video_metadata_card');

  /// Returns a key for a network video item at the given [index].
  ///
  /// Used to identify individual video items in the network video sources list.
  static Key videoSourcesNetworkItem(int index) => Key('video_sources_network_item_$index');

  // ---------------------------------------------------------------------------
  // Advanced Features Screen - Subtitles Tab
  // ---------------------------------------------------------------------------
  static const subtitlesTab = Key('subtitles_tab');
  static const subtitlesPlayPauseButton = Key('subtitles_play_pause');
  static const subtitlesOffRadio = Key('subtitles_off_radio');
  static const subtitlesVideoPlayer = Key('subtitles_video_player');
  static const subtitlesNoTracksMessage = Key('subtitles_no_tracks_message');

  /// Returns a key for a subtitle track radio button at the given [index].
  ///
  /// Used to identify individual subtitle track selection radio buttons.
  static Key subtitlesTrackRadio(int index) => Key('subtitles_track_radio_$index');

  // ---------------------------------------------------------------------------
  // Advanced Features Screen - Error Handling Tab
  // ---------------------------------------------------------------------------
  static const errorHandlingTab = Key('error_handling_tab');
  static const errorHandlingInvalidUrlButton = Key('error_handling_invalid_url');
  static const errorHandlingInvalidFormatButton = Key('error_handling_invalid_format');
  static const errorHandlingValidVideoButton = Key('error_handling_valid_video');
  static const errorHandlingLoadingIndicator = Key('error_handling_loading');
  static const errorHandlingErrorCard = Key('error_handling_error_card');
  static const errorHandlingVideoPlayer = Key('error_handling_video_player');
  static const errorHandlingPlayPauseButton = Key('error_handling_play_pause');

  // ---------------------------------------------------------------------------
  // Advanced Features Screen - Multi-Player Tab
  // ---------------------------------------------------------------------------
  static const multiPlayerTab = Key('multi_player_tab');
  static const multiPlayerAddButton = Key('multi_player_add_button');
  static const multiPlayerRemoveAllButton = Key('multi_player_remove_all');
  static const multiPlayerEmptyState = Key('multi_player_empty_state');
  static const multiPlayerGrid = Key('multi_player_grid');

  /// Returns a key for a mini player at the given [index].
  ///
  /// Used to identify individual video player instances in the multi-player grid.
  static Key multiPlayerItem(int index) => Key('multi_player_item_$index');

  /// Returns a key for a mini player's play/pause button at the given [index].
  ///
  /// Used to identify the play/pause control for a specific player instance.
  static Key multiPlayerItemPlayPause(int index) => Key('multi_player_item_play_pause_$index');

  /// Returns a key for a mini player's remove button at the given [index].
  ///
  /// Used to identify the remove button for a specific player instance.
  static Key multiPlayerItemRemove(int index) => Key('multi_player_item_remove_$index');

  // ---------------------------------------------------------------------------
  // Layout Modes Screen
  // ---------------------------------------------------------------------------
  static const layoutModesVideoPlayer = Key('layout_modes_video_player');
  static const layoutModesNoneRadio = Key('layout_modes_none_radio');
  static const layoutModesNativeRadio = Key('layout_modes_native_radio');
  static const layoutModesFlutterRadio = Key('layout_modes_flutter_radio');
  static const layoutModesCompactRadio = Key('layout_modes_compact_radio');
  static const layoutModesCustomRadio = Key('layout_modes_custom_radio');
  static const layoutModesExternalPlayPause = Key('layout_modes_external_play_pause');
  static const layoutModesExternalSeekBackward = Key('layout_modes_external_seek_backward');
  static const layoutModesExternalSeekForward = Key('layout_modes_external_seek_forward');
  static const layoutModesCompactPlayPause = Key('layout_modes_compact_play_pause');

  // ---------------------------------------------------------------------------
  // Events Log Screen
  // ---------------------------------------------------------------------------
  static const eventsLogVideoPlayer = Key('events_log_video_player');
  static const eventsLogPlayPauseButton = Key('events_log_play_pause');
  static const eventsLogSeekBackwardButton = Key('events_log_seek_backward');
  static const eventsLogSeekForwardButton = Key('events_log_seek_forward');
  static const eventsLogMuteButton = Key('events_log_mute');
  static const eventsLogSpeedButton = Key('events_log_speed');
  static const eventsLogClearButton = Key('events_log_clear');
  static const eventsLogFilterPositionCheckbox = Key('events_log_filter_position');
  static const eventsLogAutoScrollCheckbox = Key('events_log_auto_scroll');
  static const eventsLogEmptyState = Key('events_log_empty_state');
  static const eventsLogList = Key('events_log_list');

  /// Returns a key for an event log item at the given [index].
  ///
  /// Used to identify individual event entries in the event log list.
  static Key eventsLogItem(int index) => Key('events_log_item_$index');

  // ---------------------------------------------------------------------------
  // Player Toolbar Config Screen
  // ---------------------------------------------------------------------------
  static const playerToolbarVideoPlayer = Key('player_toolbar_video_player');
  static const playerToolbarMaxActionsSwitch = Key('player_toolbar_max_actions_switch');
  static const playerToolbarMaxActionsSlider = Key('player_toolbar_max_actions_slider');
  static const playerToolbarPresetMinimal = Key('player_toolbar_preset_minimal');
  static const playerToolbarPresetPlayback = Key('player_toolbar_preset_playback');
  static const playerToolbarPresetFull = Key('player_toolbar_preset_full');
  static const playerToolbarPresetOverflow = Key('player_toolbar_preset_overflow');

  // ---------------------------------------------------------------------------
  // Video Metadata Screen
  // ---------------------------------------------------------------------------
  static const videoMetadataInfoSection = Key('video_metadata_info_section');
  static const homeScreenVideoMetadataCard = Key('home_screen_video_metadata_card');
  static const videoMetadataVideoPlayer = Key('video_metadata_video_player');

  // ---------------------------------------------------------------------------
  // Casting Screen
  // ---------------------------------------------------------------------------
  static const castingVideoPlayer = Key('casting_video_player');
  static const castingStatusCard = Key('casting_status_card');
  static const castingControlsCard = Key('casting_controls_card');
  static const castingPlatformInfoCard = Key('casting_platform_info_card');
  static const castingEventLogCard = Key('casting_event_log_card');
  static const castingToggleButton = Key('casting_toggle_button');
  static const castingClearLogButton = Key('casting_clear_log_button');

  // ---------------------------------------------------------------------------
  // Subtitle Config Screen
  // ---------------------------------------------------------------------------
  static const subtitleConfigVideoPlayer = Key('subtitle_config_video_player');
  static const subtitleConfigFlutterControlsButton = Key('subtitle_config_flutter_controls');
  static const subtitleConfigNativeControlsButton = Key('subtitle_config_native_controls');
  static const subtitleConfigFontSizeSlider = Key('subtitle_config_font_size_slider');
  static const subtitleConfigPositionTop = Key('subtitle_config_position_top');
  static const subtitleConfigPositionMiddle = Key('subtitle_config_position_middle');
  static const subtitleConfigPositionBottom = Key('subtitle_config_position_bottom');
  static const subtitleConfigTextColorPicker = Key('subtitle_config_text_color_picker');
  static const subtitleConfigBackgroundColorPicker = Key('subtitle_config_bg_color_picker');
  static const subtitleConfigRenderInFlutterSwitch = Key('subtitle_config_render_flutter');
  static const subtitleConfigResetButton = Key('subtitle_config_reset_button');
}
