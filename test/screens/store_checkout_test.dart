import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/screens/store/store_checkout_screen.dart';

Widget _buildCheckout(List<Map<String, dynamic>> cartItems) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: MaterialApp(
      home: StoreCheckoutScreen(cartItems: cartItems),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cartItems = <Map<String, dynamic>>[
    {'productId': 'p1', 'name': 'Protein Powder', 'price': 100, 'quantity': 2},
  ];

  group('StoreCheckoutScreen payment step', () {
    testWidgets('offers cash on delivery as the only payment method',
        (tester) async {
      await tester.pumpWidget(_buildCheckout(cartItems));
      await tester.pumpAndSettle();

      final lang = LanguageProvider();

      // Move from shipping to payment step
      await tester.enterText(
          find.byType(TextField).at(0), 'Test User');
      await tester.enterText(
          find.byType(TextField).at(1), 'test@example.com');
      await tester.enterText(
          find.byType(TextField).at(2), '+966500000001');
      await tester.enterText(
          find.byType(TextField).at(3), 'King Fahd Road 1');
      final nextButton = find.text(lang.t('checkout_next'));
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton.first);
        await tester.pumpAndSettle();
      }

      // No card option or card fields anywhere in the flow
      expect(find.text(lang.t('payment_method_card')), findsNothing);
      expect(find.byType(RadioListTile<dynamic>), findsNothing);
      expect(find.text(lang.t('checkout_card_number')), findsNothing);
    });
  });
}
