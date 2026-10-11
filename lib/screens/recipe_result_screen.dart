import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/recipe_model.dart';
import '../services/gemini_recipe_service.dart';
import '../services/recipe_repository.dart';

class RecipeResultScreen extends StatefulWidget {
  final RecipeModel recipe;
  final Function(int) onNavigateTab;
  final Function(RecipeModel) onSaveRecipe;

  const RecipeResultScreen({
    super.key,
    required this.recipe,
    required this.onNavigateTab,
    required this.onSaveRecipe,
  });

  @override
  State<RecipeResultScreen> createState() => _RecipeResultScreenState();
}

class _RecipeResultScreenState extends State<RecipeResultScreen> {
  late RecipeModel _currentRecipe;
  bool _isModifying = false;

  @override
  void initState() {
    super.initState();
    _currentRecipe = widget.recipe;
  }

  @override
  void didUpdateWidget(covariant RecipeResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recipe.id != oldWidget.recipe.id || widget.recipe.name != oldWidget.recipe.name) {
      _currentRecipe = widget.recipe;
    }
  }

  Future<void> _handleModification(String promptText) async {
    setState(() => _isModifying = true);
    try {
      final updated = await GeminiRecipeService.modifyRecipe(
        original: _currentRecipe,
        modificationRequest: promptText,
      );
      setState(() {
        _currentRecipe = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Recipe adjusted: $promptText ✨"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      String friendlyMsg = "Could not change the recipe right now. Please try again.";
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socket') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('clientexception') ||
          errStr.contains('network')) {
        friendlyMsg = "Could not connect to the internet. Please check your connection and try again.";
      } else if (errStr.contains('timeout') || errStr.contains('timed out')) {
        friendlyMsg = "Chef AI took too long to answer. Please try again.";
      } else if (errStr.contains('busy') || errStr.contains('quota')) {
        friendlyMsg = "Chef AI is busy right now. Please wait a moment and try again.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isModifying = false);
      }
    }
  }

  void _shareRecipe() {
    final buffer = StringBuffer();
    buffer.writeln("🍳 ${_currentRecipe.name} (${_currentRecipe.cookingTime})");
    buffer.writeln("Servings: ${_currentRecipe.servings} | Calories: ${_currentRecipe.calories}");
    buffer.writeln("\n🛒 Ingredients:");
    for (final ing in _currentRecipe.ingredients) {
      buffer.writeln("• ${ing.name}");
    }
    buffer.writeln("\n👨‍🍳 Instructions:");
    for (final st in _currentRecipe.steps) {
      buffer.writeln("${st.step}: ${st.title} - ${st.desc}");
    }
    if (_currentRecipe.chefTip != null) {
      buffer.writeln("\n💡 Chef Tip: ${_currentRecipe.chefTip}");
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Full recipe copied to clipboard! 📋"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startCookingMode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InteractiveCookingModeSheet(recipe: _currentRecipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<RecipeRepository>(context);
    final isSaved = repo.isSaved(_currentRecipe.id);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text(context)),
          onPressed: () => widget.onNavigateTab(1),
        ),
        title: const Text("CookSmart Recipe 🍳"),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: AppColors.text(context)),
            tooltip: "Share / Copy Recipe",
            onPressed: _shareRecipe,
          ),
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? AppColors.primary : AppColors.text(context),
            ),
            tooltip: "Save Recipe",
            onPressed: () {
              repo.toggleSave(_currentRecipe);
              widget.onSaveRecipe(_currentRecipe);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Preview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.bg(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          alignment: Alignment.center,
                          child: Text(_currentRecipe.emoji, style: const TextStyle(fontSize: 60)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _currentRecipe.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _SpecBadge(icon: "⏱️", text: _currentRecipe.cookingTime),
                            _SpecBadge(icon: "🔥", text: _currentRecipe.calories),
                            _SpecBadge(icon: "👥", text: _currentRecipe.servings),
                            _SpecBadge(icon: "⭐", text: _currentRecipe.rating),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Interactive Cooking Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _startCookingMode,
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 22),
                      label: const Text(
                        "Start Guided Cooking Mode 👨‍🍳",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quick AI Recipe Iterations
                  Text(
                    "Customize with Chef AI:",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.muted(context)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTweakChip("🔥 Make Spicier", () => _handleModification("Make it spicy with chili peppers")),
                      _buildTweakChip("🥗 Lower Calories", () => _handleModification("Make it lower calorie and lighter")),
                      _buildTweakChip("⏱️ Quicker 15m Prep", () => _handleModification("Simplify steps for ultra-fast 15 min cook")),
                      _buildTweakChip("🧀 Extra Cheesy", () => _handleModification("Add a rich cheese melt touch")),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Ingredients Checklist Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ingredients (${_currentRecipe.ingredients.length} items)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(context),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text("Copy List", style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          final list = _currentRecipe.ingredients.map((i) => "• ${i.name}").join("\n");
                          Clipboard.setData(ClipboardData(text: list));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Ingredients copied to grocery list! 🛒")),
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: AppColors.surface(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.border(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: _currentRecipe.ingredients.map((item) {
                        return CheckboxListTile(
                          dense: true,
                          activeColor: AppColors.primary,
                          title: Text(
                            item.name,
                            style: TextStyle(
                              color: item.checked ? AppColors.text(context) : AppColors.muted(context),
                              decoration: item.checked ? TextDecoration.none : TextDecoration.lineThrough,
                              fontSize: 13,
                            ),
                          ),
                          value: item.checked,
                          onChanged: (bool? val) {
                            setState(() {
                              item.checked = val ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step-by-Step Instructions Section
                  Text(
                    "Step-by-Step Cooking Instructions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: _currentRecipe.steps.map((st) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                st.step,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    st.title,
                                    style: TextStyle(
                                      color: AppColors.text(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    st.desc,
                                    style: TextStyle(
                                      color: AppColors.muted(context),
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  // Chef's Pro Tip Card
                  if (_currentRecipe.chefTip != null && _currentRecipe.chefTip!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondaryAmber.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("💡", style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Chef's Secret Tip",
                                  style: TextStyle(
                                    color: AppColors.secondaryAmber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentRecipe.chefTip!,
                                  style: TextStyle(
                                    color: AppColors.text(context),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Modification Loading Overlay
          if (_isModifying)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 14),
                    Text("Updating recipe with Chef AI...", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTweakChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: AppColors.text(context))),
      backgroundColor: AppColors.surface(context),
      side: BorderSide(color: AppColors.border(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: _isModifying ? null : onTap,
    );
  }
}

class _SpecBadge extends StatelessWidget {
  final String icon;
  final String text;
  const _SpecBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        "$icon $text",
        style: TextStyle(fontSize: 11, color: AppColors.text(context), fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Fullscreen Interactive Step-by-Step Cooking Walkthrough with Countdown Timer
class _InteractiveCookingModeSheet extends StatefulWidget {
  final RecipeModel recipe;
  const _InteractiveCookingModeSheet({required this.recipe});

  @override
  State<_InteractiveCookingModeSheet> createState() => _InteractiveCookingModeSheetState();
}

class _InteractiveCookingModeSheetState extends State<_InteractiveCookingModeSheet> {
  int _currentStepIndex = 0;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  bool _isTimerRunning = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
      _isTimerRunning = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isTimerRunning = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.accentGreen,
              content: Text("⏰ Cooking timer finished! Check your dish!"),
            ),
          );
        }
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    final step = steps[_currentStepIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Guided Cook Mode 👨‍🍳",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    "Step ${_currentStepIndex + 1} of ${steps.length}",
                    style: TextStyle(color: AppColors.muted(context), fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStepIndex + 1) / steps.length,
            backgroundColor: AppColors.border(context),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            borderRadius: BorderRadius.circular(8),
            minHeight: 6,
          ),
          const SizedBox(height: 24),

          // Step Details
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step.step,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text(context)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                step.desc,
                style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.text(context)),
              ),
            ),
          ),

          // Built-in Kitchen Timer Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, color: AppColors.secondaryAmber, size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Kitchen Timer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          _secondsRemaining > 0 ? _formatDuration(_secondsRemaining) : "Set 3m / 5m timer",
                          style: TextStyle(
                            color: _secondsRemaining > 0 ? AppColors.primary : AppColors.muted(context),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_isTimerRunning)
                      IconButton(
                        icon: const Icon(Icons.pause, color: Colors.redAccent),
                        onPressed: _stopTimer,
                      )
                    else ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => _startTimer(180),
                        child: const Text("3m", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => _startTimer(300),
                        child: const Text("5m", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Navigation Buttons
          Row(
            children: [
              if (_currentStepIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => setState(() => _currentStepIndex--),
                    child: const Text("<- Previous Step"),
                  ),
                ),
              if (_currentStepIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_currentStepIndex < steps.length - 1) {
                      setState(() => _currentStepIndex++);
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.accentGreen,
                          content: Text("🎉 Great job! You finished all cooking steps! Enjoy your meal!"),
                        ),
                      );
                    }
                  },
                  child: Text(
                    _currentStepIndex < steps.length - 1 ? "Next Step ->" : "Finish Cooking! 🎉",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
