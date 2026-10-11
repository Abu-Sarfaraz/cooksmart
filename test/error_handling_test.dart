import 'package:flutter_test/flutter_test.dart';
import 'package:cooksmart/services/gemini_recipe_service.dart';

void main() {
  group('Friendly Exception Handling Tests', () {
    test('generateRecipe throws friendly message when ingredients list is empty', () async {
      expect(
        () async => await GeminiRecipeService.generateRecipe(
          ingredients: [],
          dietaryPreference: 'None',
          availableTime: '20 mins',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Please add at least one ingredient to generate a recipe.'),
          ),
        ),
      );
    });

    test('Recipe empty ingredients message does not contain technical jargon', () async {
      try {
        await GeminiRecipeService.generateRecipe(
          ingredients: [],
          dietaryPreference: '',
          availableTime: '',
        );
        fail('Should have thrown an exception');
      } catch (e) {
        final message = e.toString().toLowerCase();
        expect(message, isNot(contains('nullpointer')));
        expect(message, isNot(contains('socketexception')));
        expect(message, isNot(contains('http')));
        expect(message, isNot(contains('error:')));
        expect(message, contains('please add at least one ingredient'));
      }
    });
  });
}
