import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/main.dart';

void main() {
  testWidgets('VMS app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VmsApp());

    // Verify that the login screen loads with VMS branding
    expect(find.text('Vehicle Management System'), findsOneWidget);
    expect(find.text('Sign In to Dashboard'), findsOneWidget);
  });
}
