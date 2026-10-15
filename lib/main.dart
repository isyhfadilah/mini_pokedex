import 'package:flutter/material.dart';

import 'screens/pokemon_list_screen.dart';
import 'services/poke_api_service.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key, this.apiService});

  final PokeApiService? apiService;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFEF6B55);
    const ink = Color(0xFF202B3C);
    return MaterialApp(
      title: 'Pokodex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          surface: const Color(0xFFF8F9FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FC),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: ink,
              displayColor: ink,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FC),
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: ink.withValues(alpha: 0.45)),
          prefixIconColor: const Color(0xFF768196),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE9EDF3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: PokemonListScreen(
        apiService: apiService ?? PokeApiService(),
      ),
    );
  }
}
