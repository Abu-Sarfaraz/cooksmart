import 'package:flutter_test/flutter_test.dart';
import 'package:cooksmart/models/recipe_model.dart';

void main() {
  group('RecipeModel Tests', () {
    test('defaultRecipe returns valid model', () {
      final recipe = RecipeModel.defaultRecipe();
      expect(recipe.name, isNotEmpty);
      expect(recipe.ingredients.length, greaterThanOrEqualTo(1));
      expect(recipe.steps.length, greaterThanOrEqualTo(1));
      expect(recipe.cookingTime, isNotEmpty);
      expect(recipe.servings, isNotEmpty);
    });

    test('fromJson parses full structured recipe correctly', () {
      final json = {
        "name": "Spicy Honey Garlic Tofu",
        "cookingTime": "20 mins",
        "servings": "2 Servings",
        "calories": "380 kcal",
        "rating": "4.9",
        "emoji": "🍲",
        "ingredients": [
          {"name": "1 block Firm Tofu", "checked": true},
          {"name": "3 cloves Garlic, minced", "checked": true},
          {"name": "2 tbsp Honey", "checked": true}
        ],
        "steps": [
          {
            "step": "Step 1",
            "title": "Prep Tofu",
            "desc": "Press tofu and cut into 1-inch cubes."
          },
          {
            "step": "Step 2",
            "title": "Crisp Tofu",
            "desc": "Pan fry until golden brown."
          }
        ],
        "chefTip": "Dust tofu with cornstarch for maximum crispiness."
      };

      final recipe = RecipeModel.fromJson(json);
      expect(recipe.name, "Spicy Honey Garlic Tofu");
      expect(recipe.cookingTime, "20 mins");
      expect(recipe.servings, "2 Servings");
      expect(recipe.ingredients.length, 3);
      expect(recipe.ingredients.first.name, "1 block Firm Tofu");
      expect(recipe.ingredients.first.checked, isTrue);
      expect(recipe.steps.length, 2);
      expect(recipe.steps.first.title, "Prep Tofu");
      expect(recipe.chefTip, isNotNull);
    });
  });
}
