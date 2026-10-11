class RecipeIngredient {
  final String name;
  bool checked;

  RecipeIngredient({
    required this.name,
    this.checked = true,
  });

  factory RecipeIngredient.fromJson(dynamic json) {
    if (json is String) {
      return RecipeIngredient(name: json);
    } else if (json is Map<String, dynamic>) {
      return RecipeIngredient(
        name: json['name'] as String? ?? 'Ingredient',
        checked: json['checked'] as bool? ?? true,
      );
    }
    return RecipeIngredient(name: json.toString());
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'checked': checked,
      };
}

class RecipeStep {
  final String step;
  final String title;
  final String desc;

  RecipeStep({
    required this.step,
    required this.title,
    required this.desc,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json, int index) {
    return RecipeStep(
      step: json['step'] as String? ?? 'Step ${index + 1}',
      title: json['title'] as String? ?? 'Cooking Instruction',
      desc: json['desc'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step,
        'title': title,
        'desc': desc,
      };
}

class RecipeModel {
  final String id;
  final String name;
  final String cookingTime;
  final String servings;
  final String calories;
  final String rating;
  final String emoji;
  final String category;
  final bool isFavorite;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final String? chefTip;

  RecipeModel({
    String? id,
    required this.name,
    required this.cookingTime,
    required this.servings,
    required this.calories,
    required this.rating,
    required this.emoji,
    this.category = "AI Curated",
    this.isFavorite = false,
    required this.ingredients,
    required this.steps,
    this.chefTip,
  }) : id = id ?? ('${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch % 10000}');

  RecipeModel copyWith({
    String? id,
    String? name,
    String? cookingTime,
    String? servings,
    String? calories,
    String? rating,
    String? emoji,
    String? category,
    bool? isFavorite,
    List<RecipeIngredient>? ingredients,
    List<RecipeStep>? steps,
    String? chefTip,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      rating: rating ?? this.rating,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      chefTip: chefTip ?? this.chefTip,
    );
  }

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as List<dynamic>? ?? [];
    final List<RecipeIngredient> parsedIngredients = rawIngredients.map((i) {
      return RecipeIngredient.fromJson(i);
    }).toList();

    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    final List<RecipeStep> parsedSteps = [];
    for (int i = 0; i < rawSteps.length; i++) {
      final s = rawSteps[i];
      if (s is Map<String, dynamic>) {
        parsedSteps.add(RecipeStep.fromJson(s, i));
      } else if (s is String) {
        parsedSteps.add(RecipeStep(
          step: 'Step ${i + 1}',
          title: 'Instruction',
          desc: s,
        ));
      }
    }

    final name = json['name'] as String? ?? 'Custom AI Recipe';
    return RecipeModel(
      id: json['id'] as String?,
      name: name,
      cookingTime: json['cookingTime'] as String? ?? '25 mins',
      servings: json['servings'] as String? ?? '2 Servings',
      calories: json['calories'] as String? ?? '420 kcal',
      rating: json['rating'] as String? ?? '4.9 (AI Pick)',
      emoji: json['emoji'] as String? ?? '🍳',
      category: json['category'] as String? ?? 'AI Curated',
      isFavorite: json['isFavorite'] as bool? ?? false,
      ingredients: parsedIngredients,
      steps: parsedSteps,
      chefTip: json['chefTip'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cookingTime': cookingTime,
        'servings': servings,
        'calories': calories,
        'rating': rating,
        'emoji': emoji,
        'category': category,
        'isFavorite': isFavorite,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'chefTip': chefTip,
      };

  // Fallback default recipe
  factory RecipeModel.defaultRecipe() {
    return RecipeModel(
      id: "tuscan_chicken_default",
      name: "Creamy Garlic Parmesan Tuscan Chicken",
      cookingTime: "20 mins",
      servings: "2 Servings",
      calories: "420 kcal",
      rating: "4.9 ★ (2.4k)",
      emoji: "🍗",
      category: "Quick & Easy",
      isFavorite: true,
      ingredients: [
        RecipeIngredient(name: "2 Boneless Chicken Breasts"),
        RecipeIngredient(name: "4 cloves Garlic, minced"),
        RecipeIngredient(name: "1 cup Heavy Cream"),
        RecipeIngredient(name: "1/2 cup Grated Parmesan"),
        RecipeIngredient(name: "1 cup Sun-dried Tomatoes"),
        RecipeIngredient(name: "2 cups Baby Spinach"),
      ],
      steps: [
        RecipeStep(
          step: "Step 1",
          title: "Brown the Chicken",
          desc: "Put salt, pepper, and herbs on the chicken breasts. Fry in olive oil on medium heat for 6 minutes on each side until golden brown.",
        ),
        RecipeStep(
          step: "Step 2",
          title: "Cook the Garlic",
          desc: "Add chopped garlic and sliced dried tomatoes to the pan; cook for 2 minutes until it smells great.",
        ),
        RecipeStep(
          step: "Step 3",
          title: "Make Cream Sauce",
          desc: "Pour in cream and cheese. Stir gently until warm and creamy.",
        ),
        RecipeStep(
          step: "Step 4",
          title: "Mix and Serve",
          desc: "Add fresh spinach until soft. Put the chicken back in the pan, spoon warm sauce on top, and serve.",
        ),
      ],
      chefTip: "Add a splash of water or broth to the hot pan before pouring in cream to make the sauce extra tasty.",
    );
  }

  static List<RecipeModel> initialRecipes() {
    return [
      RecipeModel.defaultRecipe(),
      RecipeModel(
        id: "salmon_honey_glaze",
        name: "Warm Honey Glazed Salmon",
        cookingTime: "20 mins",
        servings: "2 Servings",
        calories: "520 kcal",
        rating: "4.8 ★ (1.8k)",
        emoji: "🍣",
        category: "Asian",
        isFavorite: true,
        ingredients: [
          RecipeIngredient(name: "2 Fresh Salmon Fillets"),
          RecipeIngredient(name: "3 tbsp Pure Honey"),
          RecipeIngredient(name: "2 tbsp Soy Sauce"),
          RecipeIngredient(name: "2 cloves Garlic, minced"),
          RecipeIngredient(name: "1 tbsp Sesame Oil"),
        ],
        steps: [
          RecipeStep(
            step: "Step 1",
            title: "Mix Glaze",
            desc: "Whisk honey, soy sauce, minced garlic, and sesame oil together.",
          ),
          RecipeStep(
            step: "Step 2",
            title: "Pan Sear",
            desc: "Sear salmon flesh-side down for 4 mins, flip and spoon glaze over fish until sticky.",
          ),
        ],
        chefTip: "Don't let the honey burn; lower the heat right after pouring the glaze.",
      ),
      RecipeModel(
        id: "avocado_poached_egg",
        name: "Avocado & Poached Egg Toast",
        cookingTime: "10 mins",
        servings: "1 Serving",
        calories: "340 kcal",
        rating: "4.7 ★ (950)",
        emoji: "🥑",
        category: "Healthy",
        isFavorite: true,
        ingredients: [
          RecipeIngredient(name: "2 slices Sourdough Bread"),
          RecipeIngredient(name: "1 Ripe Avocado"),
          RecipeIngredient(name: "2 Fresh Eggs"),
          RecipeIngredient(name: "Chili Flakes & Sea Salt"),
        ],
        steps: [
          RecipeStep(
            step: "Step 1",
            title: "Toast Bread",
            desc: "Toast sourdough slices until golden and crisp.",
          ),
          RecipeStep(
            step: "Step 2",
            title: "Poach & Assemble",
            desc: "Poach eggs for 3 minutes, mash avocado onto toast, top with eggs and chili flakes.",
          ),
        ],
        chefTip: "Add a splash of vinegar to the poaching water to keep egg whites tight.",
      ),
      RecipeModel(
        id: "thai_basil_beef",
        name: "Thai Spicy Basil Beef (Pad Krapow)",
        cookingTime: "15 mins",
        servings: "2 Servings",
        calories: "460 kcal",
        rating: "4.9 ★ (3.1k)",
        emoji: "🥩",
        category: "Asian",
        isFavorite: false,
        ingredients: [
          RecipeIngredient(name: "300g Minced Beef"),
          RecipeIngredient(name: "1 cup Fresh Thai Holy Basil"),
          RecipeIngredient(name: "3 Bird's Eye Chilies"),
          RecipeIngredient(name: "2 tbsp Oyster Sauce"),
        ],
        steps: [
          RecipeStep(
            step: "Step 1",
            title: "Cook Beef and Garlic",
            desc: "Cook crushed chilies and garlic in a hot pan, then add minced beef and stir until browned.",
          ),
          RecipeStep(
            step: "Step 2",
            title: "Add Basil",
            desc: "Add oyster sauce and stir in fresh basil leaves off the heat.",
          ),
        ],
        chefTip: "Serve over warm white rice with a fried egg on top.",
      ),
    ];
  }
}
