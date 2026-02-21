// Demo mode is opt-in and only enabled via build-time dart-define.
// Supports both DEMO_MODE and DMO_MODE aliases for CI/local consistency.
const bool kDemoMode =
    bool.fromEnvironment('DEMO_MODE', defaultValue: false) ||
    bool.fromEnvironment('DMO_MODE', defaultValue: false);

class DemoModeConfig {
  const DemoModeConfig();

  bool get isDemo => kDemoMode;
}
