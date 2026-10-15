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
    return MaterialApp(
      title: 'Pokodex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCC3D3D),
          surface: const Color(0xFFFFFBF7),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF7),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFBF7),
          foregroundColor: Color(0xFF292524),
          elevation: 0,
        ),
      ),
      home: PokemonListScreen(
        apiService: apiService ?? PokeApiService(),
      ),
    );
  }
}
