import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';

class RecipeRepository extends ChangeNotifier {
  List<RecipeModel> _savedRecipes = [];
  int _generatedCount = 0;
  static const String _prefsKey = "cooksmart_saved_recipes_v2";
  static const String _generatedCountKey = "cooksmart_generated_count";

  List<RecipeModel> get savedRecipes => List.unmodifiable(_savedRecipes);
  int get savedCount => _savedRecipes.length;
  int get generatedCount => _generatedCount;

  RecipeRepository() {
    _initRepository();
  }

  Future<void> _initRepository() async {
    await _loadFromLocal();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseAuth.instance.authStateChanges().listen((user) {
          if (user != null) {
            syncFromFirestore(user.uid);
          }
        });
      }
    } catch (_) {}
  }

  bool isSaved(String idOrName) {
    return _savedRecipes.any((r) => r.id == idOrName || r.name == idOrName);
  }

  Future<void> toggleSave(RecipeModel recipe) async {
    final existingIndex = _savedRecipes.indexWhere((r) => r.id == recipe.id || r.name == recipe.name);
    if (existingIndex >= 0) {
      await removeRecipe(_savedRecipes[existingIndex].id);
    } else {
      final savedRecipe = recipe.copyWith(isFavorite: true);
      _savedRecipes.insert(0, savedRecipe);
      notifyListeners();
      await _saveToLocal();
      await _saveToFirestore(savedRecipe);
    }
  }

  Future<void> saveRecipe(RecipeModel recipe) async {
    final exists = isSaved(recipe.id) || isSaved(recipe.name);
    if (!exists) {
      final saved = recipe.copyWith(isFavorite: true);
      _savedRecipes.insert(0, saved);
      notifyListeners();
      await _saveToLocal();
      await _saveToFirestore(saved);
    }
  }

  Future<void> removeRecipe(String recipeId) async {
    final removed = _savedRecipes.firstWhere(
      (r) => r.id == recipeId,
      orElse: () => RecipeModel.defaultRecipe(),
    );
    _savedRecipes.removeWhere((r) => r.id == recipeId);
    notifyListeners();
    await _saveToLocal();
    await _removeFromFirestore(removed);
  }

  Future<void> incrementGeneratedCount() async {
    _generatedCount++;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_generatedCountKey, _generatedCount);
    } catch (_) {}
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _generatedCount = prefs.getInt(_generatedCountKey) ?? 3;
      final rawJson = prefs.getString(_prefsKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        _savedRecipes = decoded.map((item) => RecipeModel.fromJson(item)).toList();
      } else {
        _savedRecipes = RecipeModel.initialRecipes();
        await _saveToLocal();
      }
      notifyListeners();
    } catch (e) {
      _savedRecipes = RecipeModel.initialRecipes();
      notifyListeners();
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_savedRecipes.map((r) => r.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {}
  }

  Future<void> _saveToFirestore(RecipeModel recipe) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final sanitizedDocId = recipe.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('recipes')
              .doc(sanitizedDocId)
              .set(recipe.toJson(), SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Firestore save error: $e");
    }
  }

  Future<void> _removeFromFirestore(RecipeModel recipe) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final sanitizedDocId = recipe.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('recipes')
              .doc(sanitizedDocId)
              .delete();
        }
      }
    } catch (e) {
      debugPrint("Firestore delete error: $e");
    }
  }

  Future<bool> syncFromFirestore([String? userId]) async {
    try {
      if (Firebase.apps.isEmpty) return false;
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recipes')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final remoteRecipes = snapshot.docs.map((d) => RecipeModel.fromJson(d.data())).toList();
        for (final remote in remoteRecipes) {
          if (!_savedRecipes.any((r) => r.id == remote.id)) {
            _savedRecipes.insert(0, remote);
          }
        }
        await _saveToLocal();
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint("Firestore sync error: $e");
      return false;
    }
  }
}
