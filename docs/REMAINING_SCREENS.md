# Remaining Screens to Implement

## ✅ Completed Screens (5/28)
1. Splash Screen ✅
2. Language Selection ✅
3. Onboarding (3 slides) ✅
4. OTP Authentication ✅
5. First Intake (5 questions) ✅

## 📋 Remaining Screens (23/28)

### User Flow Screens (7)

#### 6. Second Intake Screen
**File**: `lib/presentation/screens/intake/second_intake_screen.dart`
**Access**: Premium+ only
**Fields**:
- Age (number input)
- Weight (number input in kg)
- Height (number input in cm)
- Body Fat % (optional, number)
- Injuries (multi-select checkboxes)
- Medical Conditions (optional, text area)

**Features**:
- Only accessible for Premium/Smart Premium users
- 6 questions in step format
- Validation for all inputs
- Save to backend

---

#### 7. Home Dashboard Screen
**File**: `lib/presentation/screens/home/home_dashboard_screen.dart`
**Layout**:
- Welcome header with user name
- Subscription tier badge
- Quick stats (workout streak, calories, etc.)
- Today's workout card (if available)
- Today's nutrition card
- Quick actions (Message Coach, View Progress)
- Bottom navigation (Home, Workout, Nutrition, Coach, Store, Account)

**Features**:
- Real-time data
- Quota indicators
- Navigation to all main sections

---

#### 8. Workout Screen
**File**: `lib/presentation/screens/workout/workout_screen.dart`
**Layout**:
- Weekly calendar view
- Current day's exercises
- Exercise cards with:
  - Name (AR/EN)
  - Sets x Reps
  - Video thumbnail
  - Complete button
  - Substitute button (if injury conflict)
- Progress tracking
- Timer between sets

**Features**:
- Injury substitution engine
- Real-time completion tracking
- Exercise video playback
- Rest timer
- Workout summary at end

---

#### 9. Nutrition Screen
**File**: `lib/presentation/screens/nutrition/nutrition_screen.dart`
**Layout**:
- Macro progress rings (Protein, Carbs, Fats)
- Calorie counter
- Daily meal plan:
  - Breakfast
  - Lunch
  - Dinner
  - Snacks
- Meal cards with food items
- Trial expiry banner (Freemium users)

**Features**:
- Freemium: 14-day trial countdown
- Premium+: Unlimited access
- Meal logging
- Macro tracking

---

#### 10. Coach Messaging Screen
**File**: `lib/presentation/screens/messaging/coach_messaging_screen.dart`
**Layout**:
- Chat interface
- Message bubbles (user vs coach)
- Input field with attachment button
- Quota indicator at top
- Real-time message delivery

**Features**:
- Real-time Socket.IO messaging
- Attachment support (Premium+ only)
- Quota enforcement
- Read receipts
- Post-interaction rating (after conversation ends)

---

#### 11. Store Screen
**File**: `lib/presentation/screens/store/store_screen.dart`
**Layout**:
- Category tabs (Supplements, Equipment, Apparel)
- Product grid
- Product cards with:
  - Image
  - Name (AR/EN)
  - Price (SAR)
  - Add to cart button
- Shopping cart icon with badge
- Search and filters

**Features**:
- Product browsing
- Cart management
- Checkout flow
- Order history

---

#### 12. Account Screen
**File**: `lib/presentation/screens/account/account_screen.dart`
**Layout**:
- Profile section (avatar, name, email)
- Subscription tier card with upgrade button
- Settings list:
  - Edit Profile
  - Subscription Management
  - Progress & Analytics
  - Language & Theme
  - Notifications
  - Help & Support
  - Logout

**Features**:
- Profile editing
- Subscription upgrade
- Settings management
- Logout

---

### Coach Tools Screens (6)

#### 13. Coach Dashboard
**File**: `lib/presentation/screens/coach/coach_dashboard.dart`
**Access**: Coach role only
**Layout**:
- Client count stats
- Earnings this month
- Active plans count
- Recent client activity
- Quick actions (Create Plan, View Calendar, Messages)

---

#### 14. Coach Calendar
**File**: `lib/presentation/screens/coach/coach_calendar.dart`
**Layout**:
- Monthly calendar view
- Client session markers
- Video call schedule
- Clickable days showing client sessions

---

#### 15. Client List
**File**: `lib/presentation/screens/coach/client_list_screen.dart`
**Layout**:
- Searchable client list
- Client cards with:
  - Name, avatar
  - Subscription tier
  - Last activity
  - Quick actions (Message, View Profile, Create Plan)

---

#### 16. Workout Plan Builder
**File**: `lib/presentation/screens/coach/workout_plan_builder_screen.dart`
**Layout**:
- Plan name and description
- Day selector
- Exercise search and add
- Sets/reps configuration
- Save and assign to client

---

#### 17. Nutrition Plan Builder
**File**: `lib/presentation/screens/coach/nutrition_plan_builder_screen.dart`
**Layout**:
- Plan name and description
- Macro targets input
- Day selector
- Meal creation
- Food item search and add
- Save and assign to client

---

#### 18. Coach Earnings
**File**: `lib/presentation/screens/coach/coach_earnings_screen.dart`
**Layout**:
- Monthly earnings chart
- Breakdown by client tier
- Payment history
- Payout settings

---

### Admin Dashboard Screens (8)

#### 19. Admin Main Dashboard
**File**: `lib/presentation/screens/admin/admin_dashboard.dart`
**Access**: Admin role only
**Layout**:
- Platform stats (total users, coaches, revenue)
- Charts and analytics
- Quick actions to management screens

---

#### 20. User Management
**File**: `lib/presentation/screens/admin/user_management_screen.dart`
**Layout**:
- User table with search and filters
- User actions (view, edit, suspend, delete)
- Subscription tier changes
- Fitness score updates

---

#### 21. Coach Management
**File**: `lib/presentation/screens/admin/coach_management_screen.dart`
**Layout**:
- Coach table with search and filters
- Coach approval/suspension
- Performance metrics
- Client assignment

---

#### 22. Content Management
**File**: `lib/presentation/screens/admin/content_management_screen.dart`
**Layout**:
- Exercise library management
- Food database management
- Educational content
- Add/edit/delete content

---

#### 23. Store Management
**File**: `lib/presentation/screens/admin/store_management_screen.dart`
**Layout**:
- Product management
- Category management
- Order management
- Inventory tracking

---

#### 24. Subscription Management
**File**: `lib/presentation/screens/admin/subscription_management_screen.dart`
**Layout**:
- Subscription tier configuration
- Pricing management
- Quota settings
- Promo codes

---

#### 25. System Settings
**File**: `lib/presentation/screens/admin/system_settings_screen.dart`
**Layout**:
- Platform configuration
- Feature toggles
- API settings
- Email templates

---

#### 26. Analytics Dashboard
**File**: `lib/presentation/screens/admin/analytics_screen.dart`
**Layout**:
- Revenue charts
- User growth charts
- Engagement metrics
- Retention analytics

---

### Supporting Screens (2)

#### 27. Exercise Detail Modal
**File**: `lib/presentation/screens/workout/exercise_detail_screen.dart`
**Layout**:
- Exercise name and description
- Video player
- Instructions
- Muscle groups
- Equipment needed
- Alternative exercises list

---

#### 28. Video Call Screen
**File**: `lib/presentation/screens/messaging/video_call_screen.dart`
**Layout**:
- Video feed
- Controls (mute, camera, end)
- Chat overlay
- Duration counter
- Quota tracking

---

## 📦 Screen Templates

### Basic Screen Template
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../providers/language_provider.dart';

class ScreenNameScreen extends StatefulWidget {
  const ScreenNameScreen({super.key});

  @override
  State<ScreenNameScreen> createState() => _ScreenNameScreenState();
}

class _ScreenNameScreenState extends State<ScreenNameScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('screen_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Screen content here
            ],
          ),
        ),
      ),
    );
  }
}
```

### Screen with Provider Template
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../providers/language_provider.dart';
import '../providers/data_provider.dart';

class ScreenNameScreen extends StatefulWidget {
  const ScreenNameScreen({super.key});

  @override
  State<ScreenNameScreen> createState() => _ScreenNameScreenState();
}

class _ScreenNameScreenState extends State<ScreenNameScreen> {
  @override
  void initState() {
    super.initState();
    // Load data
    Future.microtask(() {
      context.read<DataProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final dataProvider = context.watch<DataProvider>();
    
    if (dataProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (dataProvider.error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error: ${dataProvider.error}'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('screen_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Screen content here
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🎨 Common Widgets Needed

### High Priority Widgets (Must create first)
1. `CustomButton` - Reusable button component
2. `CustomTextField` - Reusable text input
3. `CustomCard` - Reusable card wrapper
4. `QuotaIndicator` - Shows quota usage
5. `LoadingState` - Loading indicator
6. `EmptyState` - Empty state placeholder
7. `ErrorState` - Error message display

### Workout Widgets
1. `ExerciseCard` - Exercise display card
2. `WorkoutDayCard` - Day selection card
3. `ExerciseVideoPlayer` - Video player
4. `SetCounter` - Set completion tracker
5. `RestTimer` - Rest period timer

### Nutrition Widgets
1. `MacroRing` - Macro progress ring
2. `MealCard` - Meal display card
3. `FoodItemCard` - Food item display
4. `TrialBanner` - Freemium trial warning

### Messaging Widgets
1. `MessageBubble` - Chat message bubble
2. `MessageInput` - Chat input field
3. `AttachmentButton` - File attachment (Premium+)
4. `TypingIndicator` - Typing status

### Store Widgets
1. `ProductCard` - Product display card
2. `CartBadge` - Cart item count
3. `PriceTag` - Price display
4. `CategoryTab` - Category selector

---

## 🚀 Implementation Priority

### Week 1: Core User Flow
- [ ] Second Intake Screen
- [ ] Home Dashboard Screen
- [ ] Workout Screen (basic)
- [ ] Nutrition Screen (basic)
- [ ] Common widgets

### Week 2: Features & Messaging
- [ ] Coach Messaging Screen
- [ ] Store Screen
- [ ] Account Screen
- [ ] Exercise Detail Modal
- [ ] Messaging widgets

### Week 3: Coach Tools
- [ ] Coach Dashboard
- [ ] Coach Calendar
- [ ] Client List
- [ ] Workout Plan Builder
- [ ] Nutrition Plan Builder
- [ ] Coach Earnings

### Week 4: Admin & Polish
- [ ] All 8 Admin screens
- [ ] Video Call Screen
- [ ] All remaining widgets
- [ ] Testing and bug fixes
- [ ] Performance optimization

---

## 📝 Notes

- Each screen should support both English and Arabic
- All screens should handle RTL layout properly
- Include loading and error states
- Follow the design system (colors, typography, spacing)
- Implement proper navigation
- Add form validation where needed
- Handle quota enforcement
- Implement role-based access control

---

**Total Remaining**: 23 screens + 25+ widgets
**Estimated Time**: 4-6 weeks (with 2 developers)
**Current Status**: 18% complete (5/28 screens done)
