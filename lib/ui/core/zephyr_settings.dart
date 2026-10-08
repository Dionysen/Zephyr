/// Reusable settings controls for desktop (inline) and mobile (list + dialogs).
library;

export 'settings/zephyr_settings_adaptive_number.dart';
export 'settings/zephyr_settings_app_bar.dart';
export 'settings/zephyr_settings_category_header.dart';
export 'settings/zephyr_settings_choice_tile.dart';
export 'settings/zephyr_settings_desktop_row.dart';
export 'settings/zephyr_settings_list_tile.dart';
export 'settings/zephyr_settings_number_picker.dart';
export 'settings/zephyr_settings_section.dart';
export 'settings/zephyr_settings_slider_row.dart';
export 'settings/zephyr_settings_switch_tile.dart';
export 'settings/zephyr_settings_value_tile.dart';

import 'settings/zephyr_settings_desktop_row.dart';
import 'settings/zephyr_settings_slider_row.dart';

/// Historical name for [ZephyrSettingsDesktopRow].
typedef ZephyrSettingsRow = ZephyrSettingsDesktopRow;

/// Historical name for [ZephyrSettingsSliderRow].
typedef ZephyrSettingsSlider = ZephyrSettingsSliderRow;
