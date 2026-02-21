import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// ...existing code...
// Update the import path below if your main.dart is in a different location
import 'package:fitapp/main.dart' as app;
import 'workout_coach_e2e_test.dart' as workoutCoachE2E;
// import 'package:fitcoach_mobile/presentation/providers/auth_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete User Flow Integration Tests', () {
    testWidgets('complete onboarding and authentication flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Splash screen should appear
      expect(find.text('عاش'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. Language selection
      expect(find.text('اختر اللغة'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // 3. Onboarding screens
      expect(find.text('Welcome to FitCoach+'), findsOneWidget);
      
      // Swipe through onboarding
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // 4. OTP Authentication
      expect(find.text('Phone Verification'), findsOneWidget);
      
      // Enter phone number
      await tester.enterText(
        find.byType(TextField).first,
        '+966501234567',
      );
      await tester.pumpAndSettle();

      // Tap Send OTP
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter OTP
      final otpFields = find.byType(TextField);
      await tester.enterText(otpFields.at(1), '1');
      await tester.enterText(otpFields.at(2), '2');
      await tester.enterText(otpFields.at(3), '3');
      await tester.enterText(otpFields.at(4), '4');
      await tester.pumpAndSettle();

      // Tap Verify
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 5. First Intake
      expect(find.text('Tell us about yourself'), findsOneWidget);
      
      // Answer questions
      await tester.tap(find.text('Fat Loss'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Beginner'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Continue through remaining questions
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // 6. Home Dashboard should load
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Nutrition'), findsOneWidget);
    });

    testWidgets('workout flow with injury substitution', (WidgetTester tester) async {
      // Assuming user is logged in
      app.main();
      await tester.pumpAndSettle();

      // Navigate to workout tab
      await tester.tap(find.text('Workout'));
      await tester.pumpAndSettle();

      // Should see weekly workout plan
      expect(find.text('Monday'), findsOneWidget);
      
      // Tap on a workout day
      await tester.tap(find.text('Monday'));
      await tester.pumpAndSettle();

      // Should see exercise list
      expect(find.byType(ListView), findsOneWidget);

      // Check for injury substitution
      final injuryButton = find.text('Substitute Exercise');
      if (tester.any(injuryButton)) {
        await tester.tap(injuryButton);
        await tester.pumpAndSettle();

        // Should show substitution options
        expect(find.text('Safe Alternatives'), findsOneWidget);
      }

      // Mark exercise as complete
      await tester.tap(find.byIcon(Icons.check_circle_outline).first);
      await tester.pumpAndSettle();

      // Should show completion animation
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('nutrition plan and trial management', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to nutrition tab
      await tester.tap(find.text('Nutrition'));
      await tester.pumpAndSettle();

      // Should see macro rings
      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);

      // Check for trial countdown (for freemium users)
      if (tester.any(find.textContaining('days remaining'))) {
        expect(find.textContaining('days remaining'), findsOneWidget);
      }

      // Tap on a meal
      await tester.tap(find.text('Breakfast'));
      await tester.pumpAndSettle();

      // Should show meal details
      expect(find.byType(Dialog), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Mark meal as complete
      await tester.tap(find.byIcon(Icons.check_circle_outline).first);
      await tester.pumpAndSettle();
    });

    testWidgets('messaging with quota enforcement', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to messages
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      // Should see quota indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('remaining'), findsOneWidget);

      // Try to send a message
      await tester.enterText(
        find.byType(TextField),
        'Test message from integration test',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Should see message in chat
      expect(find.text('Test message from integration test'), findsOneWidget);

      // Quota should be updated
      // (specific assertion depends on initial quota)
    });

    testWidgets('store purchase flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to store
      await tester.tap(find.text('Store'));
      await tester.pumpAndSettle();

      // Should see products
      expect(find.text('Supplements'), findsOneWidget);

      // Tap on a product
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Should see product details
      expect(find.text('Add to Cart'), findsOneWidget);

      // Add to cart
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Should see success message
      expect(find.text('Added to cart'), findsOneWidget);

      // Open cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      // Should see cart with item
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('video call booking with quota check', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to booking
      await tester.tap(find.text('Book Video Call'));
      await tester.pumpAndSettle();

      // Should see quota warning for freemium
      if (tester.any(find.textContaining('video call'))) {
        expect(find.textContaining('remaining'), findsOneWidget);
      }

      // Select date
      await tester.tap(find.text('Select Date'));
      await tester.pumpAndSettle();

      // Tap on a date in calendar
      await tester.tap(find.text('15').first);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select time
      await tester.tap(find.text('Select Time'));
      await tester.pumpAndSettle();

      // Select time slot
      await tester.tap(find.text('10:00 AM'));
      await tester.pumpAndSettle();

      // Confirm booking
      await tester.tap(find.text('Book Now'));
      await tester.pumpAndSettle();

      // Should show confirmation
      expect(find.text('Booking Confirmed'), findsOneWidget);
    });

    testWidgets('subscription upgrade flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to account
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      // Tap on subscription
      await tester.tap(find.text('Subscription'));
      await tester.pumpAndSettle();

      // Should see current plan
      expect(find.text('Freemium'), findsOneWidget);

      // Tap upgrade
      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();

      // Should see plan options
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Smart Premium'), findsOneWidget);

      // Select Premium
      await tester.tap(find.text('Choose Premium'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Confirm Upgrade'), findsOneWidget);
    });

    testWidgets('language switch persists', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to account
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      // Tap language
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // Switch to Arabic
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      // Should see Arabic text
      expect(find.text('الرئيسية'), findsOneWidget);

      // Restart app
      await tester.pumpWidget(const SizedBox.shrink());
      app.main();
      await tester.pumpAndSettle();

      // Language should persist
      expect(find.text('الرئيسية'), findsOneWidget);
    });

    testWidgets('progress tracking displays correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to progress
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Should see charts
      expect(find.byType(CustomPaint), findsWidgets);

      // Switch time period
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      // Charts should update
      expect(find.byType(CustomPaint), findsWidgets);

      // Check for achievement cards
      if (tester.any(find.text('Achievements'))) {
        expect(find.text('Achievements'), findsOneWidget);
      }
    });

    testWidgets('exercise library search and filter', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to exercise library
      await tester.tap(find.text('Exercise Library'));
      await tester.pumpAndSettle();

      // Should see search bar
      expect(find.byType(TextField), findsOneWidget);

      // Search for exercise
      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pumpAndSettle();

      // Should see filtered results
      expect(find.textContaining('Bench'), findsWidgets);

      // Apply filter
      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();

      // Should see chest exercises only
      // (specific assertion depends on data)
    });
  });

  workoutCoachE2E.registerWorkoutCoachE2ETests();
}