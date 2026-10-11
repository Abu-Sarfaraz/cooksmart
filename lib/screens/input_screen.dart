import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/recipe_model.dart';
import '../services/gemini_recipe_service.dart';
import '../services/recipe_repository.dart';

class InputScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final Function(RecipeModel) onRecipeGenerated;

  const InputScreen({
    super.key,
    required this.onNavigateTab,
    required this.onRecipeGenerated,
  });

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final List<String> _ingredients = ["Chicken Breast", "Olive Oil", "Garlic"];

  final Map<String, List<String>> _pantryCategories = {
    "🥩 Proteins": ["Eggs", "Chicken", "Beef", "Salmon", "Tofu", "Cheddar Cheese"],
    "🥦 Fresh Veggies": ["Garlic", "Onion", "Tomatoes", "Bell Pepper", "Spinach", "Lemon"],
    "🧂 Pantry & Spices": ["Olive Oil", "Butter", "Soy Sauce", "Honey", "Pasta", "Rice"],
  };

  // Multi-select dietary preferences
  final Set<String> _selectedDietary = {};
  final List<String> _dietaryOptions = [
    "Vegetarian",
    "Gluten-Free",
    "High Protein",
    "Low Carb / Keto",
    "Dairy-Free",
    "Vegan"
  ];

  int _selectedTimeIndex = 1;
  final List<String> _timeOptions = [
    "⚡ Quick (<15m)",
    "⏱️ Medium (30m)",
    "🍲 Slow Cook (45m+)"
  ];

  int _selectedServingsIndex = 1;
  final List<String> _servingsOptions = [
    "1 Person",
    "2 Servings",
    "4 Family",
    "6+ Feast"
  ];

  int _selectedMealTypeIndex = 2;
  final List<String> _mealTypes = [
    "🍳 Breakfast",
    "🥗 Lunch",
    "🍲 Dinner",
    "🍿 Snack"
  ];

  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addIngredient(String val) {
    final clean = val.trim();
    if (clean.isNotEmpty && !_ingredients.any((i) => i.toLowerCase() == clean.toLowerCase())) {
      setState(() {
        _ingredients.add(clean);
        _inputController.clear();
        _errorMessage = null;
      });
    }
  }

  void _removeIngredient(String val) {
    setState(() {
      _ingredients.remove(val);
    });
  }

  Future<void> _handleGenerateRecipe() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Please add at least one ingredient to generate a recipe!"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dietaryString = _selectedDietary.isEmpty
          ? "No Restrictions"
          : _selectedDietary.join(", ");

      final recipe = await GeminiRecipeService.generateRecipe(
        ingredients: _ingredients,
        dietaryPreference: dietaryString,
        availableTime: _timeOptions[_selectedTimeIndex],
        servings: _servingsOptions[_selectedServingsIndex],
        mealType: _mealTypes[_selectedMealTypeIndex],
      );

      // Track usage stats in repository
      if (mounted) {
        Provider.of<RecipeRepository>(context, listen: false).incrementGeneratedCount();
      }

      widget.onRecipeGenerated(recipe);
      widget.onNavigateTab(2); // Go to Recipe Result
    } catch (e) {
      String cleanError = e.toString().replaceFirst('Exception: ', '').trim();
      final lower = cleanError.toLowerCase();

      if (lower.contains('socket') ||
          lower.contains('failed host lookup') ||
          lower.contains('clientexception') ||
          lower.contains('xmlhttprequest') ||
          lower.contains('network')) {
        cleanError = "Could not connect to the internet. Please check your connection and try again.";
      } else if (lower.contains('timeout') || lower.contains('timed out')) {
        cleanError = "Chef AI took too long to answer. Please try again.";
      } else if (lower.contains('busy') || lower.contains('quota') || lower.contains('429')) {
        cleanError = "Chef AI is busy right now. Please wait a moment and try again.";
      } else if (lower.contains('404') || lower.contains('not found')) {
        cleanError = "Could not reach Chef AI right now. Please try again.";
      } else if (cleanError.isEmpty || lower.contains('formatexception') || lower.contains('syntaxerror')) {
        cleanError = "Could not read the recipe response. Please try again.";
      }

      setState(() {
        _errorMessage = cleanError;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF93000A),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cleanError,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text(context)),
          onPressed: _isLoading ? null : () => widget.onNavigateTab(0),
        ),
        title: const Text("AI Recipe Generator 🪄"),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tell CookSmart what's inside your pantry & fridge",
                    style: TextStyle(color: AppColors.muted(context), fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Error Banner with Retry
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.text(context), fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: _handleGenerateRecipe,
                            child: const Text("Retry", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),

                  // Ingredients Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Your Kitchen Ingredients (${_ingredients.length})",
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Zero-Waste AI",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Active Ingredient Chips
                        if (_ingredients.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "No ingredients added yet. Type below or tap staples!",
                              style: TextStyle(color: AppColors.muted(context), fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _ingredients.map((ing) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.chip(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ing,
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _removeIngredient(ing),
                                      child: Icon(
                                        Icons.close,
                                        color: AppColors.muted(context),
                                        size: 16,
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 14),

                        // Input Field & Add Button
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                onSubmitted: _addIngredient,
                                decoration: InputDecoration(
                                  hintText: "Add an ingredient (e.g. Tomatoes, Soy Sauce...)",
                                  hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 13),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  fillColor: AppColors.bg(context),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.border(context)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _addIngredient(_inputController.text),
                              icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 34),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Categorized Pantry Staples
                  Text(
                    "Pantry Staples (Tap to add/remove)",
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ..._pantryCategories.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted(context)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((staple) {
                              final alreadyAdded = _ingredients.any((i) => i.toLowerCase() == staple.toLowerCase());
                              return GestureDetector(
                                onTap: () {
                                  if (alreadyAdded) {
                                    _removeIngredient(staple);
                                  } else {
                                    _addIngredient(staple);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: alreadyAdded
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: alreadyAdded ? AppColors.primary : AppColors.border(context),
                                    ),
                                  ),
                                  child: Text(
                                    alreadyAdded ? "✓ $staple" : "+ $staple",
                                    style: TextStyle(
                                      color: alreadyAdded ? AppColors.primary : AppColors.text(context),
                                      fontSize: 12,
                                      fontWeight: alreadyAdded ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Meal Type Selector
                  Text(
                    "Meal Type",
                    style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(_mealTypes.length, (index) {
                      final isSelected = index == _selectedMealTypeIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMealTypeIndex = index),
                          child: Container(
                            margin: EdgeInsets.only(right: index < _mealTypes.length - 1 ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border(context)),
                            ),
                            child: Text(
                              _mealTypes[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.text(context),
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),

                  // Dietary Preferences (Multi-Select)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Dietary Preferences (Multi-Select)",
                        style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (_selectedDietary.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _selectedDietary.clear()),
                          child: const Text("Clear all", style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietaryOptions.map((diet) {
                      final isSelected = _selectedDietary.contains(diet);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(diet),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.text(context),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface(context),
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedDietary.add(diet);
                            } else {
                              _selectedDietary.remove(diet);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Cooking Time & Servings
                  Row(
                    children: [
                      // Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Max Cooking Time",
                              style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedTimeIndex,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surface(context),
                                  items: List.generate(_timeOptions.length, (i) {
                                    return DropdownMenuItem(
                                      value: i,
                                      child: Text(_timeOptions[i], style: TextStyle(fontSize: 12, color: AppColors.text(context))),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedTimeIndex = val);
                                  },
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Servings
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Serving Size",
                              style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedServingsIndex,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surface(context),
                                  items: List.generate(_servingsOptions.length, (i) {
                                    return DropdownMenuItem(
                                      value: i,
                                      child: Text(_servingsOptions[i], style: TextStyle(fontSize: 12, color: AppColors.text(context))),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedServingsIndex = val);
                                  },
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Main CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGenerateRecipe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Asking Chef AI...",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : const Text(
                              "✨ Generate Recipe ->",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("👨‍🍳", style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                    const SizedBox(height: 18),
                    Text(
                      "Making Your Recipe...",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Looking at your ingredients and finding the best meal ideas.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.muted(context), height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
