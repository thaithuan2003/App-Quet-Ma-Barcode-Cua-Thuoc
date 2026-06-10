import 'package:cnpm_bdtt/app/pharmacy_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login screen when no token is saved', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PharmacyApp());
    await tester.pumpAndSettle();

    expect(find.text('Pharmacy Barcode'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Dang nhap'), findsOneWidget);
  });
}
