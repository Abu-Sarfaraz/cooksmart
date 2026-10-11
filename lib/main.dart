import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/recipe_model.dart';
import 'screens/home_screen.dart';
import 'screens/input_screen.dart';
import 'screens/recipe_result_screen.dart';
import 'screens/saved_recipes_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/theme_provider.dart';
import 'services/recipe_repository.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase optional/offline mode: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RecipeRepository()),
      ],
      child: const CookSmartApp(),
    ),
  );
}

class CookSmartApp extends StatefulWidget {
  const CookSmartApp({super.key});

  @override
  State<CookSmartApp> createState() => _CookSmartAppState();
}

class _CookSmartAppState extends State<CookSmartApp> {
  bool _isOfflineGuest = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    Widget homeWidget = const MainShellScreen();
    try {
      if (Firebase.apps.isNotEmpty && !_isOfflineGuest) {
        homeWidget = StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const MainShellScreen();
            }
            return AuthScreen(onLoginSuccess: () {
              // If anonymous auth fails, allow offline guest access
              if (FirebaseAuth.instance.currentUser == null) {
                setState(() {
                  _isOfflineGuest = true;
                });
              }
            });
          },
        );
      }
    } catch (_) {}

    return MaterialApp(
      title: 'CookSmart AI',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: homeWidget,
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  RecipeModel _currentRecipe = RecipeModel.defaultRecipe();

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onRecipeGenerated(RecipeModel newRecipe) {
    setState(() {
      _currentRecipe = newRecipe;
    });
  }

  void _onSelectRecipe(RecipeModel recipe) {
    setState(() {
      _currentRecipe = recipe;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<RecipeRepository>(context);

    final List<Widget> screens = [
      HomeScreen(
        onNavigateTab: _navigateToTab,
        onSelectRecipe: _onSelectRecipe,
      ),
      InputScreen(
        onNavigateTab: _navigateToTab,
        onRecipeGenerated: _onRecipeGenerated,
      ),
      RecipeResultScreen(
        recipe: _currentRecipe,
        onNavigateTab: _navigateToTab,
        onSaveRecipe: (r) => repo.saveRecipe(r),
      ),
      SavedRecipesScreen(
        onNavigateTab: _navigateToTab,
        onSelectRecipe: _onSelectRecipe,
      ),
      // Profile screen is now the 5th tab
      const ProfileScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border(
            top: BorderSide(color: AppColors.border(context), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          backgroundColor: AppColors.surface(context),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.muted(context),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'AI Cook',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Recipe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
