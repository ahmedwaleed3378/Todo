import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeServices {
  final GetStorage _box = GetStorage();
  final String _key = 'isDarkMode';
  void _saveThemeToBox(bool isDark) {
    _box.write(_key, isDark);
  }

  bool _loadThemeFromBox() {
    return _box.read<bool>(_key) ?? false;
  }

  ThemeMode get theme {
    return _loadThemeFromBox() ? ThemeMode.dark : ThemeMode.light;
  }

  void switchTheme() {
    Get.changeThemeMode(_loadThemeFromBox() ? ThemeMode.dark : ThemeMode.light);
    _saveThemeToBox(!_loadThemeFromBox());
  }
}
