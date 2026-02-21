# عاش (FitCoach+) Flutter Implementation Guide

## 📦 What Has Been Created

This Flutter project foundation has been set up with the essential structure and configuration to replicate all functionality from the React web application.

### ✅ Created Files

#### Core Configuration
1. **`pubspec.yaml`** - Complete dependencies list matching React app functionality
2. **`lib/main.dart`** - App entry point with all providers
3. **`lib/app.dart`** - Root widget with navigation logic
4. **`lib/core/constants/colors.dart`** - Complete color system from React app
5. **`lib/core/config/theme_config.dart`** - Theme configuration with RTL support
6. **`lib/data/models/user_profile.dart`** - User data model with Hive
7. **`lib/presentation/providers/language_provider.dart`** - Bilingual support with translations
8. **`lib/presentation/screens/splash_screen.dart`** - Splash screen
9. **`lib/presentation/screens/language_selection_screen.dart`** - Language selection
10. **`README.md`** - Complete project documentation
11. **`IMPLEMENTATION_GUIDE.md`** - This file

### 📊 Project Status

**Completion**: ~15% (Foundation Complete)

#### ✅ Completed
- [x] Project structure
- [x] Dependencies configuration
- [x] Theme system (Light/Dark with RTL)
- [x] Color palette (matching React app)
- [x] Language provider (AR/EN with translations)
- [x] Main app shell with providers
- [x] Basic navigation structure
- [x] User profile data model
- [x] Splash screen
- [x] Language selection screen

#### ⏳ Remaining (To Be Implemented)

**Critical Providers (8 files)**
- [ ] `lib/presentation/providers/auth_provider.dart`
- [ ] `lib/presentation/providers/user_provider.dart`
- [ ] `lib/presentation/providers/theme_provider.dart`
- [ ] `lib/presentation/providers/workout_provider.dart`
- [ ] `lib/presentation/providers/nutrition_provider.dart`
- [ ] `lib/presentation/providers/messaging_provider.dart`
- [ ] `lib/presentation/providers/quota_provider.dart`

**Data Models (15 files)**
- [ ] `lib/data/models/workout_plan.dart`
- [ ] `lib/data/models/exercise.dart`
- [ ] `lib/data/models/nutrition_plan.dart`
- [ ] `lib/data/models/meal.dart`
- [ ] `lib/data/models/message.dart`
- [ ] `lib/data/models/quota.dart`
- [ ] `lib/data/models/video_call.dart`
- [ ] `lib/data/models/product.dart`
- [ ] `lib/data/models/order.dart`
- [ ] And more...

**Repositories (8 files)**
- [ ] `lib/data/repositories/auth_repository.dart`
- [ ] `lib/data/repositories/user_repository.dart`
- [ ] `lib/data/repositories/workout_repository.dart`
- [ ] `lib/data/repositories/nutrition_repository.dart`
- [ ] `lib/data/repositories/messaging_repository.dart`
- [ ] `lib/data/repositories/store_repository.dart`

**Core Screens (26 files)**
- [ ] `lib/presentation/screens/onboarding_screen.dart`
- [ ] `lib/presentation/screens/auth/otp_auth_screen.dart`
- [ ] `lib/presentation/screens/intake/first_intake_screen.dart`
- [ ] `lib/presentation/screens/intake/second_intake_screen.dart`
- [ ] `lib/presentation/screens/home/home_dashboard_screen.dart`
- [ ] `lib/presentation/screens/workout/workout_screen.dart`
- [ ] `lib/presentation/screens/nutrition/nutrition_screen.dart`
- [ ] `lib/presentation/screens/messaging/coach_messaging_screen.dart`
- [ ] `lib/presentation/screens/store/store_screen.dart`
- [ ] `lib/presentation/screens/account/account_screen.dart`
- [ ] `lib/presentation/screens/coach/coach_dashboard.dart`
- [ ] `lib/presentation/screens/admin/admin_dashboard.dart`
- [ ] And 14 more screens...

**Reusable Widgets (20+ files)**
- [ ] `lib/presentation/widgets/common/custom_button.dart`
- [ ] `lib/presentation/widgets/common/custom_text_field.dart`
- [ ] `lib/presentation/widgets/common/custom_app_bar.dart`
- [ ] `lib/presentation/widgets/common/quota_indicator.dart`
- [ ] `lib/presentation/widgets/workout/exercise_card.dart`
- [ ] And 15+ more widgets...

**Network & Storage (10 files)**
- [ ] `lib/core/network/dio_client.dart`
- [ ] `lib/core/network/socket_client.dart`
- [ ] `lib/core/network/interceptors/auth_interceptor.dart`
- [ ] `lib/data/local/hive_service.dart`
- [ ] `lib/data/local/secure_storage.dart`
- [ ] And more...

**Total Remaining**: ~100 files to create

---

## 🚀 Quick Start Instructions

### Step 1: Install Flutter

```bash
# Check if Flutter is installed
flutter --version

# If not installed, download from:
# https://docs.flutter.dev/get-started/install
```

### Step 2: Set Up Project

```bash
# Navigate to mobile folder
cd mobile

# Install dependencies
flutter pub get

# Check for issues
flutter doctor
```

### Step 3: Run the App

```bash
# List available devices
flutter devices

# Run on iOS simulator (macOS only)
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Run on Chrome (for testing)
flutter run -d chrome
```

### Step 4: Generate Missing Files

Since Hive requires code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📝 Implementation Roadmap

### Phase 1: Complete Foundation (Week 1)

**Priority 1: Providers**
Create all provider files with state management:

```dart
// Example: auth_provider.dart
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserProfile? _user;
  String? _error;
  
  AuthProvider(this._repository) {
    _checkAuthStatus();
  }
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserProfile? get user => _user;
  String? get error => _error;
  
  Future<void> _checkAuthStatus() async {
    // Check if user has stored token
    // Load user profile
  }
  
  Future<bool> requestOTP(String phoneNumber) async {
    // Request OTP from API
  }
  
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    // Verify OTP and login
  }
  
  Future<void> logout() async {
    // Logout and clear data
  }
}
```

**Priority 2: Data Models**
Create all data model files matching React app interfaces.

**Priority 3: Repositories**
Create repository files for API communication:

```dart
// Example: auth_repository.dart
import '../models/user_profile.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio;
  
  AuthRepository() : _dio = Dio(BaseOptions(
    baseUrl: 'https://your-api-url.com/api/v1',
  ));
  
  Future<void> requestOTP(String phoneNumber) async {
    await _dio.post('/auth/request-otp', data: {
      'phoneNumber': phoneNumber,
    });
  }
  
  Future<AuthResponse> verifyOTP(String phoneNumber, String otp) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'phoneNumber': phoneNumber,
      'otp': otp,
    });
    
    return AuthResponse.fromJson(response.data);
  }
  
  // More methods...
}
```

### Phase 2: Authentication Flow (Week 2)

**Screens to Create:**
1. Onboarding Screen (3 slides)
2. OTP Auth Screen
3. First Intake Screen
4. Second Intake Screen

**Features:**
- Phone number validation (+966 format)
- OTP input with 6 digits
- Form validation
- API integration
- Navigation flow

### Phase 3: Core User Features (Week 3-5)

**Screens to Create:**
1. Home Dashboard
2. Workout Screen
3. Nutrition Screen
4. Coach Messaging Screen
5. Store Screen
6. Account Screen

**Features:**
- Workout plan display
- Exercise substitution UI
- Nutrition plan with expiry
- Real-time messaging
- Quota indicators
- Product browsing

### Phase 4: Coach & Admin (Week 6-7)

**Screens to Create:**
1. Coach Dashboard
2. Coach Calendar
3. Plan Builders
4. Admin Dashboard (8 screens)

**Features:**
- Plan creation tools
- Client management
- Analytics charts
- Admin controls

### Phase 5: Polish & Release (Week 8-10)

**Tasks:**
- Complete all widgets
- Add animations
- Implement offline support
- Add push notifications
- Comprehensive testing
- Performance optimization
- App store preparation

---

## 💡 Development Tips

### 1. Use Hot Reload
```bash
# Press 'r' in terminal while app is running
# Or Cmd/Ctrl + S in VS Code
```

### 2. Debug with DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 3. Check for Lint Issues
```bash
flutter analyze
```

### 4. Format Code
```bash
flutter format lib/
```

### 5. Run Tests
```bash
flutter test
```

---

## 🔧 Common Implementation Patterns

### 1. Creating a New Screen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewScreen extends StatelessWidget {
  const NewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Title'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Your content here
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. Using Provider for State

```dart
// In build method:
final authProvider = context.watch<AuthProvider>();

if (authProvider.isLoading) {
  return const CircularProgressIndicator();
}

if (authProvider.error != null) {
  return Text('Error: ${authProvider.error}');
}

// Or use Consumer
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return Text('User: ${authProvider.user?.name}');
  },
)
```

### 3. Navigation Between Screens

```dart
// Navigate to new screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const NewScreen()),
);

// Navigate back
Navigator.pop(context);

// Replace current screen
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const NewScreen()),
);
```

### 4. RTL Support

```dart
Directionality(
  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
  child: YourWidget(),
)
```

### 5. API Call Pattern

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final data = await repository.fetchData();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  } catch (error) {
    setState(() {
      _error = error.toString();
      _isLoading = false;
    });
  }
}
```

---

## 📚 Reference Documentation

All React app specifications are available in `/docs` folder:

1. **Business Logic**: `/docs/05-BUSINESS-LOGIC.md`
2. **Screen Specs**: `/docs/03-SCREEN-SPECIFICATIONS.md`
3. **Data Models**: `/docs/02-DATA-MODELS.md`
4. **API Specs**: `/docs/06-API-SPECIFICATIONS.md`
5. **Migration Guides**: `/docs/migration/`

---

## 🎯 Next Steps for AI Tools

To complete this Flutter app, an AI tool should:

1. **Read** the React app code in `/App.tsx` and all `/components/*.tsx` files
2. **Read** the specifications in `/docs` folder
3. **Create** all remaining provider files
4. **Create** all data model files
5. **Create** all repository files
6. **Create** all 28 screen files
7. **Create** all reusable widget files
8. **Create** network and storage utility files
9. **Test** each screen as it's created
10. **Verify** feature parity with React app

### Recommended AI Approach

```
For each React component:
1. Read the component code
2. Read the corresponding screen spec from /docs
3. Create equivalent Flutter widget
4. Implement state management with Provider
5. Integrate with API repository
6. Add bilingual support
7. Test functionality
8. Move to next component
```

### Priority Order

1. **Auth Flow** (Onboarding → OTP → Intake)
2. **Home Dashboard** (Main navigation hub)
3. **Workout Screen** (Core feature)
4. **Nutrition Screen** (Core feature)
5. **Messaging Screen** (Communication)
6. **Store Screen** (E-commerce)
7. **Account Screen** (Settings)
8. **Coach Dashboard** (Coach tools)
9. **Admin Dashboard** (Admin tools)
10. **Supporting Screens** (Modals, details)

---

## 🏁 Completion Criteria

The Flutter app will be complete when:

- ✅ All 28 screens are implemented
- ✅ All features from React app work identically
- ✅ Bilingual support (AR/EN) is fully functional
- ✅ RTL layout works correctly
- ✅ API integration is complete
- ✅ Quota management works
- ✅ Real-time messaging works
- ✅ All forms validate properly
- ✅ Navigation flows correctly
- ✅ App matches design system
- ✅ No critical bugs
- ✅ Performance is optimized
- ✅ Ready for app store submission

---

## 📞 Support

For questions or issues:
1. Check React app code for reference
2. Review `/docs` folder specifications
3. Consult Flutter documentation
4. Check migration guides in `/docs/migration/`

---

**Status**: Foundation Complete - Ready for Full Implementation  
**Estimated Remaining Effort**: 8-10 weeks (with 2-3 developers)  
**Next Action**: Begin implementing providers and repositories

---

Good luck with the Flutter implementation! 🚀
