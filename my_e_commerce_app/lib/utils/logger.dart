import 'package:flutter/foundation.dart';

/// Basit bir loglama yardımcısı.
/// Yalnızca debug modunda log çıktıları gösterir.
class Logger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }
  
  static void error(String message) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
    }
  }
}
