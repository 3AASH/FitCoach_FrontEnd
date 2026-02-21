import 'package:flutter/foundation.dart';
import '../../core/config/demo_mode.dart';

class DemoModeProvider extends ChangeNotifier {
  final DemoModeConfig _config;

  DemoModeProvider(this._config);

  bool get isDemo => _config.isDemo;
}
