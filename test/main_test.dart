import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_editor/main.dart';

main(){
  testWidgets('MyApp widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget( MyApp());


    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.pump();

  });
}