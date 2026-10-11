import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/recipe_model.dart';
import '../providers/theme_provider.dart';
import '../services/recipe_repository.dart';
import '../utils/debouncer.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final Function(RecipeModel)? onSelectRecipe;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    this.onSelectRecipe,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    "All",
    "Quick & Easy",
    "Asian",
    "Healthy",
    "Italian",
    "Comfort Food"
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final _debouncer = Debouncer(milliseconds: 300);

  final List<RecipeModel> _featuredRecipes = [
    RecipeModel.defaultRecipe(),
    RecipeModel(
      id: "featured_honey_salmon",
      name: "Warm Honey Glazed Salmon",
      cookingTime: "20 mins",
      servings: "2 Servings",
      calories: "520 kcal",
      rating: "4.8 ★ (1.8k)",
      emoji: "🍣",
      category: "Asian",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "2 Fresh Salmon Fillets"),
        RecipeIngredient(name: "3 tbsp Pure Honey"),
        RecipeIngredient(name: "2 tbsp Soy Sauce"),
        RecipeIngredient(name: "2 cloves Garlic, minced"),
        RecipeIngredient(name: "1 tbsp Sesame Oil"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Whisk Glaze", desc: "Combine honey, soy sauce, garlic, and sesame oil."),
        RecipeStep(step: "Step 2", title: "Sear Salmon", desc: "Sear salmon skin-side up for 4 minutes until crisp."),
        RecipeStep(step: "Step 3", title: "Glaze & Baste", desc: "Pour honey glaze over fish, basting frequently until caramelized."),
      ],
      chefTip: "Do not let honey burn; turn down heat immediately once glaze thickens.",
    ),
    RecipeModel(
      id: "featured_avocado_toast",
      name: "Avocado & Poached Egg Toast",
      cookingTime: "10 mins",
      servings: "1 Serving",
      calories: "340 kcal",
      rating: "4.7 ★ (950)",
      emoji: "🥑",
      category: "Healthy",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "2 slices Sourdough Bread"),
        RecipeIngredient(name: "1 Ripe Avocado"),
        RecipeIngredient(name: "2 Fresh Eggs"),
        RecipeIngredient(name: "Chili Flakes & Sea Salt"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Toast Bread", desc: "Toast sourdough slices until golden and crisp."),
        RecipeStep(step: "Step 2", title: "Poach & Assemble", desc: "Poach eggs, mash avocado onto toast, top with eggs."),
      ],
      chefTip: "A squeeze of lemon over the mashed avocado prevents browning.",
    ),
    RecipeModel(
      id: "featured_pad_krapow",
      name: "Thai Spicy Basil Beef",
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
        RecipeStep(step: "Step 1", title: "Wok Fry", desc: "Sear chilies and garlic in hot wok, then add beef."),
        RecipeStep(step: "Step 2", title: "Basil Toss", desc: "Season with oyster sauce and toss in fresh holy basil."),
      ],
      chefTip: "Sear with very high heat for deep wok flavor.",
    ),
    RecipeModel(
      id: "featured_carbonara",
      name: "Classic Roman Carbonara",
      cookingTime: "25 mins",
      servings: "2 Servings",
      calories: "650 kcal",
      rating: "4.9 ★ (4.2k)",
      emoji: "🍝",
      category: "Italian",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "200g Spaghetti"),
        RecipeIngredient(name: "100g Guanciale or Pancetta"),
        RecipeIngredient(name: "2 Large Eggs"),
        RecipeIngredient(name: "50g Pecorino Romano"),
        RecipeIngredient(name: "Freshly Cracked Black Pepper"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Boil Pasta", desc: "Cook pasta in salted water until al dente."),
        RecipeStep(step: "Step 2", title: "Crisp Guanciale", desc: "Sauté guanciale until fat renders and edges are crispy."),
        RecipeStep(step: "Step 3", title: "Emulsify Sauce", desc: "Toss pasta with guanciale, then off heat, quickly stir in egg/cheese mixture with pasta water."),
      ],
      chefTip: "Never add the egg mixture while the pan is on the heat, or you'll get scrambled eggs!",
    ),
    RecipeModel(
      id: "featured_mac_cheese",
      name: "Ultimate Mac & Cheese",
      cookingTime: "30 mins",
      servings: "4 Servings",
      calories: "820 kcal",
      rating: "4.8 ★ (2.5k)",
      emoji: "🧀",
      category: "Comfort Food",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "250g Macaroni"),
        RecipeIngredient(name: "2 tbsp Butter"),
        RecipeIngredient(name: "2 tbsp Flour"),
        RecipeIngredient(name: "2 cups Whole Milk"),
        RecipeIngredient(name: "200g Sharp Cheddar, grated"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Mix Butter & Flour", desc: "Melt butter in a pan, stir in flour, and cook for 1 minute."),
        RecipeStep(step: "Step 2", title: "Add Milk", desc: "Slowly pour in milk while stirring until smooth and thick."),
        RecipeStep(step: "Step 3", title: "Add Cheese", desc: "Turn off heat, stir in cheddar cheese and cooked macaroni."),
      ],
      chefTip: "Grate fresh block cheese by hand for the smoothest and creamiest cheese sauce.",
    ),
    RecipeModel(
      id: "featured_caprese",
      name: "Fresh Caprese Salad",
      cookingTime: "5 mins",
      servings: "2 Servings",
      calories: "280 kcal",
      rating: "4.6 ★ (1.1k)",
      emoji: "🍅",
      category: "Quick & Easy",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "2 Ripe Tomatoes"),
        RecipeIngredient(name: "1 ball Fresh Mozzarella"),
        RecipeIngredient(name: "1 bunch Fresh Basil"),
        RecipeIngredient(name: "2 tbsp Extra Virgin Olive Oil"),
        RecipeIngredient(name: "Balsamic Glaze"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Slice", desc: "Slice tomatoes and mozzarella into 1/4-inch thick rounds."),
        RecipeStep(step: "Step 2", title: "Arrange", desc: "Alternate tomato, mozzarella, and basil leaves on a plate."),
        RecipeStep(step: "Step 3", title: "Dress", desc: "Drizzle with olive oil, balsamic glaze, and season with salt/pepper."),
      ],
      chefTip: "Keep tomatoes at room temperature; refrigeration destroys their flavor compounds.",
    ),
    RecipeModel(
      id: "featured_ramen",
      name: "Spicy Miso Ramen",
      cookingTime: "30 mins",
      servings: "2 Servings",
      calories: "600 kcal",
      rating: "4.9 ★ (3.4k)",
      emoji: "🍜",
      category: "Asian",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "2 portions Fresh Ramen Noodles"),
        RecipeIngredient(name: "4 cups Chicken or Pork Broth"),
        RecipeIngredient(name: "3 tbsp Red Miso Paste"),
        RecipeIngredient(name: "2 tbsp Chili Oil (Rayu)"),
        RecipeIngredient(name: "2 Soft Boiled Eggs (Ajitama)"),
        RecipeIngredient(name: "1 cup Sliced Scallions"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Prepare Tare", desc: "Whisk miso paste with a ladle of hot broth until smooth."),
        RecipeStep(step: "Step 2", title: "Boil Noodles", desc: "Cook ramen noodles for 2-3 minutes, then drain well."),
        RecipeStep(step: "Step 3", title: "Assemble", desc: "Pour hot broth into bowls, add noodles, and top with eggs, scallions, and chili oil."),
      ],
      chefTip: "Never boil miso paste directly in the pot; it destroys its delicate aroma and probiotics.",
    ),
    RecipeModel(
      id: "featured_kung_pao",
      name: "Kung Pao Chicken",
      cookingTime: "25 mins",
      servings: "3 Servings",
      calories: "550 kcal",
      rating: "4.7 ★ (2.1k)",
      emoji: "🥘",
      category: "Asian",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "400g Chicken Breast, cubed"),
        RecipeIngredient(name: "1/2 cup Unsalted Peanuts"),
        RecipeIngredient(name: "5 Dried Red Chilies"),
        RecipeIngredient(name: "1 tbsp Sichuan Peppercorns"),
        RecipeIngredient(name: "2 tbsp Soy Sauce & 1 tbsp Black Vinegar"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Marinate", desc: "Toss chicken in soy sauce and cornstarch; let sit for 10 minutes."),
        RecipeStep(step: "Step 2", title: "Toast Spices", desc: "Stir-fry dried chilies and Sichuan peppercorns until fragrant."),
        RecipeStep(step: "Step 3", title: "Wok Fry", desc: "Add chicken and peanuts, stir-fry on high heat, then toss in the sauce."),
      ],
      chefTip: "Sichuan peppercorns give the dish its signature 'ma la' (numbing and spicy) sensation.",
    ),
    RecipeModel(
      id: "featured_bibimbap",
      name: "Classic Beef Bibimbap",
      cookingTime: "40 mins",
      servings: "2 Servings",
      calories: "650 kcal",
      rating: "4.8 ★ (1.9k)",
      emoji: "🍛",
      category: "Asian",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "2 cups Cooked Short-grain Rice"),
        RecipeIngredient(name: "200g Thinly Sliced Beef (Bulgogi)"),
        RecipeIngredient(name: "1 cup Spinach & 1 cup Bean Sprouts"),
        RecipeIngredient(name: "1 Carrot, julienned"),
        RecipeIngredient(name: "2 tbsp Gochujang (Korean Chili Paste)"),
        RecipeIngredient(name: "2 Fried Eggs"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Blanch Veggies", desc: "Lightly blanch spinach and bean sprouts, season with sesame oil."),
        RecipeStep(step: "Step 2", title: "Sauté", desc: "Sauté carrots and beef separately until cooked."),
        RecipeStep(step: "Step 3", title: "Serve", desc: "Place rice in a bowl, arrange toppings in a circle, top with egg and gochujang."),
      ],
      chefTip: "Serve in a hot stone bowl (Dolsot) to get a delicious crispy rice crust at the bottom!",
    ),
    RecipeModel(
      id: "featured_bengali_salad",
      name: "Bengali Shosha Tomato Salad",
      cookingTime: "10 mins",
      servings: "4 Servings",
      calories: "45 kcal",
      rating: "4.7 ★ (1.2k)",
      emoji: "🥒",
      category: "Healthy",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "2 Cucumbers, finely diced"),
        RecipeIngredient(name: "2 Tomatoes, chopped"),
        RecipeIngredient(name: "1 Red Onion, finely sliced"),
        RecipeIngredient(name: "2 Green Chilies, chopped"),
        RecipeIngredient(name: "1/4 cup Fresh Coriander"),
        RecipeIngredient(name: "1 tbsp Mustard Oil (Kachi Ghani)"),
        RecipeIngredient(name: "Pinch of Black Salt (Kala Namak)"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Chop Vegetables", desc: "Finely dice the cucumber, tomato, and slice the onion."),
        RecipeStep(step: "Step 2", title: "Mix Flavors", desc: "Toss with green chilies, coriander, and black salt."),
        RecipeStep(step: "Step 3", title: "Dressing", desc: "Drizzle mustard oil on top just before serving and mix well."),
      ],
      chefTip: "The drizzle of raw mustard oil gives it the authentic sharp Bengali kick. Don't skip it!",
    ),
    RecipeModel(
      id: "featured_mango_bhorta",
      name: "Kacha Aamer Bhorta",
      cookingTime: "15 mins",
      servings: "2 Servings",
      calories: "85 kcal",
      rating: "4.9 ★ (2.8k)",
      emoji: "🥭",
      category: "Quick & Easy",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "2 Green (Raw) Mangoes"),
        RecipeIngredient(name: "1 tsp Kasundi (Mustard Sauce)"),
        RecipeIngredient(name: "2 Dried Red Chilies, roasted"),
        RecipeIngredient(name: "1 tbsp Sugar or Jaggery"),
        RecipeIngredient(name: "Salt and Black Salt to taste"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Prep Mangoes", desc: "Peel and grate or finely slice the raw green mangoes."),
        RecipeStep(step: "Step 2", title: "Crush Chilies", desc: "Crush the roasted dried red chilies with salt and sugar."),
        RecipeStep(step: "Step 3", title: "Mix Well", desc: "Combine mangoes, chili mix, and Kasundi. Toss well until juicy."),
      ],
      chefTip: "Use your hands to mix and crush the ingredients together—it releases the mango juices perfectly!",
    ),
    RecipeModel(
      id: "featured_shorshe_ilish",
      name: "Shorshe Ilish (Mustard Hilsa)",
      cookingTime: "30 mins",
      servings: "4 Servings",
      calories: "450 kcal",
      rating: "4.9 ★ (3.5k)",
      emoji: "🐟",
      category: "Asian",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "4 pieces Ilish (Hilsa) Fish"),
        RecipeIngredient(name: "3 tbsp Mustard Seeds (Yellow & Black)"),
        RecipeIngredient(name: "4-5 Green Chilies"),
        RecipeIngredient(name: "1/2 tsp Turmeric Powder"),
        RecipeIngredient(name: "3 tbsp Mustard Oil"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Prep Paste", desc: "Soak mustard seeds, then blend into a smooth paste with 2 green chilies and a pinch of salt."),
        RecipeStep(step: "Step 2", title: "Marinate", desc: "Lightly marinate the fish pieces with turmeric and salt."),
        RecipeStep(step: "Step 3", title: "Simmer", desc: "Heat mustard oil, add the paste and water. Gently slide in the fish and simmer for 10 mins with slit green chilies."),
      ],
      chefTip: "Blending the mustard seeds with a green chili and salt prevents the paste from turning bitter.",
    ),
    RecipeModel(
      id: "featured_beef_tehari",
      name: "Old Dhaka Beef Tehari",
      cookingTime: "1 hr 15 mins",
      servings: "6 Servings",
      calories: "780 kcal",
      rating: "4.8 ★ (5.1k)",
      emoji: "🍛",
      category: "Comfort Food",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "1 kg Beef, cut into small bite-sized pieces"),
        RecipeIngredient(name: "500g Kalijeera or Chinigura Rice"),
        RecipeIngredient(name: "1/2 cup Mustard Oil"),
        RecipeIngredient(name: "10-12 Whole Green Chilies"),
        RecipeIngredient(name: "2 tbsp Ginger-Garlic Paste"),
        RecipeIngredient(name: "Whole Spices (Cardamom, Cinnamon, Cloves, Tejpata)"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Cook Beef", desc: "Cook the beef with mustard oil, ginger, garlic, and whole spices until tender and oil separates."),
        RecipeStep(step: "Step 2", title: "Prepare Rice", desc: "Remove beef pieces. In the same oily broth, fry the washed aromatic rice briefly, then add hot water."),
        RecipeStep(step: "Step 3", title: "Dum (Steam)", desc: "When water reduces, mix the beef back in, add green chilies, cover tightly, and steam (dum) on low heat for 20 mins."),
      ],
      chefTip: "Authentic Tehari relies entirely on the pungency of Mustard Oil and the aroma of Green Chilies—do not use red chili powder!",
    ),
    RecipeModel(
      id: "featured_chicken_roast",
      name: "Biye Barir Chicken Roast",
      cookingTime: "1 hr",
      servings: "4 Servings",
      calories: "620 kcal",
      rating: "4.9 ★ (4.8k)",
      emoji: "🍗",
      category: "Comfort Food",
      isFavorite: false,
      ingredients: [
        RecipeIngredient(name: "4 large Chicken Leg Quarters"),
        RecipeIngredient(name: "1/2 cup Sour Yogurt (Tok Doi)"),
        RecipeIngredient(name: "1/4 cup Fried Onions (Beresta)"),
        RecipeIngredient(name: "1 tbsp Nut & Poppy Seed Paste"),
        RecipeIngredient(name: "2 tbsp Ghee"),
        RecipeIngredient(name: "1 tsp Kewra Water"),
      ],
      steps: [
        RecipeStep(step: "Step 1", title: "Fry Chicken", desc: "Lightly score the chicken, rub with salt, and shallow fry until golden. Set aside."),
        RecipeStep(step: "Step 2", title: "Rich Gravy", desc: "Sauté ginger-garlic paste, add yogurt, nut paste, and whole spices. Cook until oil surfaces."),
        RecipeStep(step: "Step 3", title: "Simmer", desc: "Add chicken back in, cover with water, and simmer. Finish with ghee, beresta, and kewra water."),
      ],
      chefTip: "The Kewra water and Ghee added at the very end are the secret to that authentic Bangladeshi wedding aroma.",
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RecipeModel> get _filteredRecipes {
    return _featuredRecipes.where((r) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          r.category.toLowerCase() == _categories[_selectedCategoryIndex].toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.ingredients.any((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showChefTipsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("👨‍🍳", style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Text(
                  "Daily Chef Secrets",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipRow(ctx, "Tasty Soup Broth", "Save vegetable scraps like onion skins in a freezer bag to make good soup broth later."),
            const SizedBox(height: 12),
            _buildTipRow(ctx, "Crispy Meat Crust", "Always wipe meat dry with paper towels before frying so it browns nicely."),
            const SizedBox(height: 12),
            _buildTipRow(ctx, "Fresh Herb Trick", "Put soft herbs in ice water for 15 minutes to make them crisp again."),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Got it, Chef!"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(BuildContext context, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context), fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(color: AppColors.muted(context), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final repo = Provider.of<RecipeRepository>(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/app_icon.jpg',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CookSmart",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Turn fridge scraps into gourmet meals",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Theme Toggle Button
                      GestureDetector(
                        onTap: () => themeProvider.toggleTheme(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: AppColors.text(context),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Notification Chef Tips Button
                      GestureDetector(
                        onTap: _showChefTipsModal,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: AppColors.text(context),
                                size: 20,
                              ),
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondaryAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Interactive Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(Icons.search, color: AppColors.primary, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          _debouncer.run(() {
                            setState(() => _searchQuery = val.trim());
                          });
                        },
                        style: TextStyle(color: AppColors.text(context), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Search dishes, ingredients (e.g. Salmon, Chicken)...",
                          hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.muted(context), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Category Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedCategoryIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border(context),
                          ),
                        ),
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.muted(context),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // Quick AI Prompt Hero Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface(context),
                      AppColors.primary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "AI Smart Pantry",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Have leftover ingredients in your kitchen?",
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () => widget.onNavigateTab(1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                ),
                                child: const Text("AI Cook ->", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("🍳", style: TextStyle(fontSize: 48)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Featured Recipes Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Featured Recipes (${_filteredRecipes.length})",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = "";
                          _selectedCategoryIndex = 0;
                        });
                      },
                      child: const Text("Reset Filters", style: TextStyle(color: AppColors.primary)),
                    )
                ],
              ),
              const SizedBox(height: 14),

              // Recipes List or Empty State
              if (_filteredRecipes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        const Text("🔍", style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          "No recipes found matching \"$_searchQuery\"",
                          style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Try searching for something else or reset categories.",
                          style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _filteredRecipes.map((recipe) {
                    final isSaved = repo.isSaved(recipe.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: _buildRecipeCard(
                        context,
                        recipe: recipe,
                        isSaved: isSaved,
                        onBookmarkTap: () => repo.toggleSave(recipe),
                        onTap: () {
                          if (widget.onSelectRecipe != null) {
                            widget.onSelectRecipe!(recipe);
                          }
                          widget.onNavigateTab(2); // Go to Recipe Result
                        },
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context, {
    required RecipeModel recipe,
    required bool isSaved,
    required VoidCallback onBookmarkTap,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context)),
              ),
              alignment: Alignment.center,
              child: Text(recipe.emoji, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.rating,
                          style: const TextStyle(
                            color: AppColors.secondaryAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "⏱️ ${recipe.cookingTime}",
                        style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recipe.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_outline,
                color: isSaved ? AppColors.primary : AppColors.muted(context),
                size: 24,
              ),
              onPressed: onBookmarkTap,
            ),
          ],
        ),
      ),
    );
  }
}
