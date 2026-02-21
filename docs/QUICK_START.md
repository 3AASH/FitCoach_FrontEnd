# 🚀 Flutter Mobile App Quick Start Guide

**Get the عاش Fitness mobile app running in 5 minutes**

---

## ⚡ **1. Prerequisites**

```bash
# Install Flutter (3.x required)
flutter --version

# Check Flutter doctor
flutter doctor

# Install Git
git --version
```

---

## 📦 **2. Install Dependencies**

```bash
cd mobile

# Get Flutter packages
flutter pub get
```

---

## 🔧 **3. Setup Configuration**

### **Update API Endpoint:**

Edit `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://your-backend-url:3000';
  
  // For local development:
  // Android emulator: 'http://10.0.2.2:3000'
  // iOS simulator: 'http://localhost:3000'
  // Real device: 'http://192.168.1.x:3000' (your computer's IP)
}
```

### **For Development:**

```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000';

// iOS Simulator
static const String baseUrl = 'http://localhost:3000';

// Real Device (find your computer's IP)
static const String baseUrl = 'http://192.168.1.100:3000';
```

---

## 📱 **4. Run App**

### **Start Backend First:**

```bash
# In backend folder
cd ../backend
npm run dev
```

### **Run Flutter App:**

```bash
# Back to mobile folder
cd ../mobile

# Check connected devices
flutter devices

# Run on connected device/emulator
flutter run

# Or specify device
flutter run -d chrome           # Web
flutter run -d emulator-5554    # Android
flutter run -d "iPhone 14"      # iOS
```

---

## ✅ **5. Verify Installation**

### **App Should:**
- ✅ Launch with language selection screen
- ✅ Show Arabic and English options
- ✅ Connect to backend (no connection errors)

### **Test Login Flow:**
1. Select language (Arabic or English)
2. Enter phone number
3. Request OTP
4. Backend should send OTP (check console logs)
5. Enter OTP code
6. Should navigate to intake screens

---

## 🏗️ **6. Project Structure**

```
mobile/
├── lib/
│   ├── main.dart                   # App entry point
│   ├── app.dart                    # Main app widget
│   │
│   ├── core/                       # Core configurations
│   │   ├── config/
│   │   │   ├── api_config.dart    # ← CONFIGURE THIS
│   │   │   └── theme_config.dart
│   │   └── constants/
│   │       └── colors.dart
│   │
│   ├── data/                       # Data layer
│   │   ├── models/                 # Data models
│   │   └── repositories/           # API calls
│   │
│   └── presentation/               # UI layer
│       ├── screens/                # 39 screens
│       ├── widgets/                # Reusable widgets
│       └── providers/              # State management
│
├── test/                           # Unit tests
├── integration_test/               # Integration tests
└── pubspec.yaml                    # Dependencies
```

---

## 🔧 **7. Common Development Tasks**

### **Add New Package:**

```bash
# Add to pubspec.yaml then run:
flutter pub get
```

### **Run Tests:**

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widgets/custom_button_test.dart

# Run integration tests
flutter test integration_test/
```

### **Build for Release:**

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### **Clean Build:**

```bash
flutter clean
flutter pub get
flutter run
```

---

## 📱 **8. Device-Specific Setup**

### **Android:**

1. Enable USB debugging on device
2. Connect device via USB
3. Run `flutter devices` to verify
4. Run `flutter run`

### **iOS:**

1. Open Xcode
2. Trust developer certificate
3. Select real device
4. Run from Xcode or `flutter run`

### **Web:**

```bash
flutter run -d chrome
```

---

## 🔑 **9. Test User Accounts**

### **Default Accounts (if using seeded data):**

```
Phone: +966500000001
Role: Regular User
Tier: Freemium

Phone: +966500000002
Role: Premium User
Tier: Premium

Phone: +966500000003
Role: Coach

Phone: +966500000004
Role: Admin
```

**OTP Code:** Check backend console logs or use `123456` if in dev mode

---

## 🎨 **10. Theme & Styling**

### **Colors are defined in:**
```
lib/core/constants/colors.dart
```

### **Enhanced Components:**
```
lib/presentation/widgets/
├── enhanced_button.dart      # Buttons
├── enhanced_card.dart        # Cards
├── enhanced_input.dart       # Text fields
├── enhanced_progress.dart    # Progress bars
└── focus_wrapper.dart        # Focus rings
```

### **Match React Web Theme:**
- ✅ 99% exact color match
- ✅ Same typography
- ✅ Same spacing
- ✅ Same border radius
- ✅ Same focus rings

---

## 🌐 **11. API Integration**

### **All screens connected to backend:**

| Feature | Repository | Status |
|---------|------------|--------|
| **Auth** | `auth_repository.dart` | ✅ Connected |
| **Users** | `user_repository.dart` | ✅ Connected |
| **Workouts** | `workout_repository.dart` | ✅ Connected |
| **Nutrition** | `nutrition_repository.dart` | ✅ Connected |
| **Messaging** | `messaging_repository.dart` | ✅ Connected |
| **Coach** | `coach_repository.dart` | ✅ Connected |
| **Admin** | `admin_repository.dart` | ✅ Connected |
| **Store** | `store_repository.dart` | ✅ Connected |
| **Payment** | `payment_repository.dart` | ✅ Connected |

**[View Backend Integration Guide →](./BACKEND_INTEGRATION_GUIDE.md)**

---

## 🐛 **Troubleshooting**

### **Connection Error:**

```dart
// Check API URL in api_config.dart
// Android: http://10.0.2.2:3000
// iOS: http://localhost:3000
// Real device: http://YOUR_COMPUTER_IP:3000
```

### **Provider Errors:**

```bash
# Make sure Provider is initialized in main.dart
# All providers should be wrapped with MultiProvider
```

### **Build Errors:**

```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

### **Gradle Errors (Android):**

```bash
cd android
./gradlew clean
cd ..
flutter run
```

---

## 🔗 **Next Steps**

1. ✅ **[Read Implementation Guide](./IMPLEMENTATION_GUIDE.md)**
2. ✅ **[Learn Backend Integration](./BACKEND_INTEGRATION_GUIDE.md)**
3. ✅ **[View Feature List](./FEATURE_AUDIT.md)**
4. ✅ **[Check React Comparison](./REACT_VS_FLUTTER_COMPARISON.md)**

---

## 📞 **Need Help?**

- Check [Implementation Guide](./IMPLEMENTATION_GUIDE.md)
- Review [Backend Integration](./BACKEND_INTEGRATION_GUIDE.md)
- See [Feature Audit](./FEATURE_AUDIT.md)

---

**Status:** ✅ App should now be running!  
**Connected:** Backend APIs  
**Ready for:** Testing & development

---

*Quick Start Guide*  
*Last Updated: December 2024*  
*Flutter Version: 3.x*

