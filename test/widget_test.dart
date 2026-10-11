import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cooksmart/main.dart';
import 'package:cooksmart/providers/theme_provider.dart';
import 'package:cooksmart/services/recipe_repository.dart';

void main() {
  testWidgets('CookSmart app initial render and navigation test', (WidgetTester tester) async {
    // 1. Pump the full application with Providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => RecipeRepository()),
        ],
        child: const CookSmartApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Verify Home Screen is initially active
    expect(find.text('CookSmart'), findsOneWidget);
    expect(find.textContaining('Featured Recipes'), findsOneWidget);

    // 3. Navigate to AI Cook tab (Tab 1)
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('AI Cook'),
      ),
    );
    await tester.pumpAndSettle();

    // 4. Verify AI Cook / Input Screen elements
    expect(find.text('AI Recipe Generator 🪄'), findsOneWidget);
    expect(find.text('✨ Generate Recipe ->'), findsOneWidget);

    // 5. Navigate to Recipe tab (Tab 2) via BottomNavigationBar
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Recipe'),
      ),
    );
    await tester.pumpAndSettle();

    // 6. Verify Recipe Result Screen elements
    expect(find.text('CookSmart Recipe 🍳'), findsOneWidget);
    expect(find.textContaining('Ingredients'), findsOneWidget);

    // 7. Navigate to Saved tab (Tab 3) via BottomNavigationBar
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Saved'),
      ),
    );
    await tester.pumpAndSettle();

    // 8. Verify Saved Recipes Screen elements
    expect(find.text('Saved Recipes ❤️'), findsOneWidget);
    expect(find.textContaining('Generate New'), findsOneWidget);
  });
}
