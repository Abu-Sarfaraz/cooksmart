import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../config/api_keys.dart';

class GeminiRecipeService {
  static const String _apiKey = geminiApiKey;

  // In-memory LRU cache to save API costs for identical recipe requests
  static final Map<String, RecipeModel> _recipeCache = {};

  // Tier 1: Ultra-fast & Cost-efficient (1-3 ingredients, simple constraints)
  static const List<String> _tier1Models = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash-8b',
  ];

  // Tier 2: High-reasoning & Gourmet Precision (4+ ingredients or complex diets)
  static const List<String> _tier2Models = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
  ];

  /// Cache key generator
  static String _generateCacheKey(List<String> ingredients, String diet, String time, [String? servings]) {
    final sorted = List<String>.from(ingredients.map((e) => e.trim().toLowerCase()))..sort();
    return "${sorted.join('_')}|${diet.toLowerCase()}|${time.toLowerCase()}|${servings ?? '2'}";
  }

  static Future<RecipeModel> generateRecipe({
    required List<String> ingredients,
    required String dietaryPreference,
    required String availableTime,
    String servings = "2 Servings",
    String mealType = "Any",
  }) async {
    if (ingredients.isEmpty) {
      throw Exception('Please add at least one ingredient to generate a recipe.');
    }

    // Check Cache first to avoid unnecessary API cost
    final cacheKey = _generateCacheKey(ingredients, dietaryPreference, availableTime, servings);
    if (_recipeCache.containsKey(cacheKey)) {
      return _recipeCache[cacheKey]!;
    }

    final String prompt = '''
You are a friendly home-cooking chef. Create a tasty, simple, easy-to-make recipe matching these details:
- Available Ingredients: ${ingredients.join(", ")}
- Dietary Preference: $dietaryPreference
- Time Limit: $availableTime
- Servings: $servings
- Meal Type: $mealType

IMPORTANT LANGUAGE RULES:
- Use ONLY very simple, clear, and easy-to-understand plain English words.
- Do NOT use difficult, fancy, or confusing cooking words (do not use words like "deglaze", "julienne", "emulsify", "caramelize", "aromatics", "reduction", "concasse", or complex culinary terms).
- Instead, use simple everyday words like "cut into small pieces", "fry until brown", "stir gently", "mix well", "turn down the heat".
- Do NOT use any language other than simple English.
- Make every step short, clear, and easy for anyone to follow.

Return ONLY a valid, parseable JSON object strictly matching this schema with no markdown wrapping or quotes:
{
  "name": "Simple Easy Recipe Name in Plain English",
  "cookingTime": "$availableTime or actual minutes (e.g. 20 mins)",
  "servings": "$servings",
  "calories": "Estimated total per serving (e.g. 450 kcal)",
  "rating": "4.9 ★",
  "emoji": "A single food emoji (e.g. 🥘, 🍲, 🍗, 🍝, 🍣, 🥗, 🌮)",
  "category": "Quick & Easy, Asian, Healthy, Italian, or Comfort Food",
  "ingredients": [
    {"name": "Ingredient with simple amount (e.g. 2 Boneless Chicken Breasts)", "checked": true}
  ],
  "steps": [
    {
      "step": "Step 1",
      "title": "Simple Step Title",
      "desc": "Short, clear instructions written in simple English."
    }
  ],
  "chefTip": "A simple helpful tip in plain English to make the dish taste better."
}
''';

    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.7,
      }
    };

    // Cost Optimization: Accurately decide model tier
    final bool hasDietaryRestrictions = dietaryPreference.isNotEmpty &&
        dietaryPreference.toLowerCase() != "no restrictions" &&
        dietaryPreference.toLowerCase() != "none";

    final bool isComplex = ingredients.length >= 4 || hasDietaryRestrictions;
    final List<String> modelsToTry = isComplex ? _tier2Models : _tier1Models;

    final recipe = await _executeWithFallback(modelsToTry, requestBody);
    _recipeCache[cacheKey] = recipe;
    return recipe;
  }

  /// Modifies an existing recipe according to a user request (e.g. "make spicier", "swap garlic")
  static Future<RecipeModel> modifyRecipe({
    required RecipeModel original,
    required String modificationRequest,
  }) async {
    final String prompt = '''
Take this existing recipe:
Title: ${original.name}
Ingredients: ${original.ingredients.map((i) => i.name).join(", ")}
Steps: ${original.steps.map((s) => "${s.step}: ${s.desc}").join("; ")}

Change it according to this request: "$modificationRequest".

IMPORTANT LANGUAGE RULES:
- Use ONLY very simple, clear, and easy-to-understand plain English words.
- Do NOT use difficult words or fancy chef terms.
- Use simple words like "cut", "fry", "mix", "cook".
- Do NOT use any language other than simple English.

Return ONLY valid JSON with updated name, ingredients, steps, and chefTip following the same schema.
''';

    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.7,
      }
    };

    return await _executeWithFallback(_tier1Models, requestBody);
  }

  static Future<RecipeModel> _executeWithFallback(
    List<String> models,
    Map<String, dynamic> requestBody,
  ) async {
    String friendlyErrorMessage = 'Could not make the recipe right now. Please try again.';

    for (final model in models) {
      final Uri url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
      );

      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final String jsonText = parts[0]['text'];
              final cleanJson = jsonText
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
              final Map<String, dynamic> parsedRecipe = jsonDecode(cleanJson);
              return RecipeModel.fromJson(parsedRecipe);
            }
          }
        } else if (response.statusCode == 503 || response.statusCode == 429) {
          friendlyErrorMessage = 'Chef AI is busy right now. Please wait a moment and try again.';
          continue; // High demand: cascade to next model
        } else if (response.statusCode == 404) {
          continue; // Model endpoint unavailable: cascade to next model
        } else {
          try {
            final errJson = jsonDecode(response.body);
            final msg = (errJson['error']?['message']?.toString() ?? '').toLowerCase();
            if (msg.contains('quota') || msg.contains('rate limit')) {
              friendlyErrorMessage = 'Chef AI is busy right now. Please wait a moment and try again.';
            } else if (msg.contains('api key') || msg.contains('unauthenticated')) {
              friendlyErrorMessage = 'Chef AI is not configured properly. Please check your API key.';
            }
          } catch (_) {}
        }
      } catch (e) {
        final errText = e.toString().toLowerCase();
        if (errText.contains('failed host lookup') ||
            errText.contains('socketexception') ||
            errText.contains('clientexception') ||
            errText.contains('network') ||
            errText.contains('connection')) {
          throw Exception('Could not connect to the internet. Please check your connection and try again.');
        } else if (errText.contains('timeoutexception') || errText.contains('timed out')) {
          friendlyErrorMessage = 'Chef AI took too long to answer. Please try again.';
        }
        continue;
      }
    }

    throw Exception(friendlyErrorMessage);
  }
}
