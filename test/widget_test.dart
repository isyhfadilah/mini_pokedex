import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_pokodex/main.dart';
import 'package:mini_pokodex/services/poke_api_service.dart';

void main() {
  testWidgets('loads the list and filters Pokémon by name', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v2/pokemon');
      return http.Response(
        jsonEncode({
          'results': [
            {
              'name': 'bulbasaur',
              'url': 'https://pokeapi.co/api/v2/pokemon/1/',
            },
            {'name': 'pikachu', 'url': 'https://pokeapi.co/api/v2/pokemon/25/'},
          ],
        }),
        200,
      );
    });

    await tester.pumpWidget(
      PokedexApp(apiService: PokeApiService(client: client)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pika');
    await tester.pump();

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });
}
