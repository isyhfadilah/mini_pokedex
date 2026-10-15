import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_pokodex/main.dart';
import 'package:mini_pokodex/services/poke_api_service.dart';

void main() {
  testWidgets('loads a page and searches by submitted Pokémon name', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/v2/pokemon-species') {
        expect(request.url.queryParameters, {'limit': '20', 'offset': '0'});
        return http.Response(
          jsonEncode({
            'count': 2,
            'next': null,
            'results': [
              {
                'name': 'bulbasaur',
                'url': 'https://pokeapi.co/api/v2/pokemon-species/1/',
              },
              {
                'name': 'pikachu',
                'url': 'https://pokeapi.co/api/v2/pokemon-species/25/',
              },
            ],
          }),
          200,
        );
      }
      expect(request.url.path, '/api/v2/pokemon-species/pikachu');
      return http.Response(jsonEncode({'id': 25, 'name': 'pikachu'}), 200);
    });

    await tester.pumpWidget(
      PokedexApp(apiService: PokeApiService(client: client)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pikachu');
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });
}
