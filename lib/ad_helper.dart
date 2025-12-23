import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  // ---------------------------------------------------------------------------
  // Android AdMob Configuration
  // App ID: ca-app-pub-6241753847233513~2040098065
  // ---------------------------------------------------------------------------

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner
    }
    // Your REAL Production Banner ID
    return 'ca-app-pub-6241753847233513/6063103552';
  }

  static String get appOpenAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/9257395915'; // Android Test App Open
    }
    // Your REAL Production App Open ID (Ensure this is an "App Open" unit, not Banner)
    // If you used the suffix of your App ID here, it will fail. 
    // You must create a specific App Open Ad Unit in AdMob.
    return 'ca-app-pub-6241753847233513/2040098065'; 
  }
}
