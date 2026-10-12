import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/recipe_model.dart';
import '../services/recipe_repository.dart';
import '../utils/debouncer.dart';

class SavedRecipesScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final Function(RecipeModel) onSelectRecipe;

  const SavedRecipesScreen({
    super.key,
    required this.onNavigateTab,
    required this.onSelectRecipe,
  });

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    "All Saved",
    "Quick & Easy",
    "Asian",
    "Healthy",
    "AI Curated",
  ];

  bool _isGridView = true;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<RecipeRepository>(context);
    final allSaved = repo.savedRecipes;

    // Filter recipes
    final filtered = allSaved.where((r) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          r.category.toLowerCase() == _categories[_selectedCategoryIndex].toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.ingredients.any((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Saved Recipes ❤️",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Your cookbook (${allSaved.length} saved)",
                        style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Search Toggle
                      IconButton(
                        icon: Icon(_isSearchOpen ? Icons.close : Icons.search, color: AppColors.text(context)),
                        onPressed: () {
                          setState(() {
                            _isSearchOpen = !_isSearchOpen;
                            if (!_isSearchOpen) {
                              _searchController.clear();
                              _searchQuery = "";
                            }
                          });
                        },
                      ),
                      // View Mode Toggle (Grid vs List)
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          color: AppColors.primary,
                        ),
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar if open
              if (_isSearchOpen)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (val) {
                            _debouncer.run(() {
                              setState(() => _searchQuery = val.trim());
                            });
                          },
                          style: TextStyle(color: AppColors.text(context), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Search saved recipes or ingredients...",
                            hintStyle: TextStyle(color: AppColors.muted(context), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.close, color: AppColors.muted(context), size: 16),
                          ),
                        ),
                    ],
                  ),
                ),

              // Filter Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedCategoryIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategoryIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Main List / Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.kitchen,
                                size: 72,
                                color: AppColors.muted(context).withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                allSaved.isEmpty ? "No saved recipes yet" : "No recipes found in this filter",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                allSaved.isEmpty
                                    ? "Generate recipes with AI Cook and save your favorites!"
                                    : "Try clearing search or choosing another category.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                              ),
                              const SizedBox(height: 16),
                              if (allSaved.isEmpty)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => widget.onNavigateTab(1),
                                  icon: const Icon(Icons.auto_awesome, size: 18),
                                  label: const Text("Generate with AI"),
                                )
                            ],
                          ),
                        ),
                      )
                    : _isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: filtered.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.76,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, index) {
                              final r = filtered[index];
                              return _buildGridCard(context, r, repo);
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final r = filtered[index];
                              return _buildListTile(context, r, repo);
                            },
                          ),
              ),
              const SizedBox(height: 12),

              // Bottom Action Area: Contains both Generate Recipe and Grocery List without overlapping!
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onNavigateTab(1),
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        label: const Text(
                          "+ Generate New AI Recipe",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _showGroceryList(context, filtered),
                        icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
                        label: const Text(
                          "Grocery List",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface(context),
                          foregroundColor: AppColors.text(context),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroceryList(BuildContext context, List<RecipeModel> recipes) {
    // Compile grocery list by counting identical ingredient names
    final Map<String, int> groceryMap = {};
    for (var recipe in recipes) {
      for (var ingredient in recipe.ingredients) {
        final name = ingredient.name.toLowerCase();
        groceryMap[name] = (groceryMap[name] ?? 0) + 1;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Smart Grocery List",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.muted(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Collected from ${recipes.length} recipes",
                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: groceryMap.length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.border(context)),
                  itemBuilder: (context, index) {
                    final entry = groceryMap.entries.elementAt(index);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_box_outline_blank, color: AppColors.muted(context)),
                      title: Text(
                        "${entry.key.substring(0, 1).toUpperCase()}${entry.key.substring(1)}",
                        style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        "${entry.value} recipe${entry.value > 1 ? 's' : ''}",
                        style: const TextStyle(color: AppColors.primary, fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridCard(BuildContext context, RecipeModel r, RecipeRepository repo) {
    return GestureDetector(
      onTap: () {
        widget.onSelectRecipe(r);
        widget.onNavigateTab(2);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.bg(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  alignment: Alignment.center,
                  child: Text(r.emoji, style: const TextStyle(fontSize: 40)),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _confirmRemove(context, r, repo),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: AppColors.primary, size: 16),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              r.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text(context),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "⏱️ ${r.cookingTime}",
                  style: TextStyle(color: AppColors.muted(context), fontSize: 11),
                ),
                Text(
                  r.rating,
                  style: const TextStyle(
                    color: AppColors.secondaryAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, RecipeModel r, RecipeRepository repo) {
    return Dismissible(
      key: Key(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        repo.removeRecipe(r.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed ${r.name}"),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: "Undo", onPressed: () => repo.saveRecipe(r)),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          widget.onSelectRecipe(r);
          widget.onNavigateTab(2);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(r.emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${r.cookingTime} • ${r.calories} • ${r.category}",
                      style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.primary, size: 20),
                onPressed: () => _confirmRemove(context, r, repo),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, RecipeModel r, RecipeRepository repo) {
    repo.removeRecipe(r.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Removed ${r.name}"),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: "Undo", onPressed: () => repo.saveRecipe(r)),
      ),
    );
  }
}
