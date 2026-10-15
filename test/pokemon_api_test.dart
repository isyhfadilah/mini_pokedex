import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mini_pokodex/services/poke_api_service.dart';

void main() {
  group('Pokémon list and search', () {
    test(
      'requests an offset page and reports whether another page exists',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/api/v2/pokemon-species');
          expect(request.url.queryParameters, {'limit': '20', 'offset': '40'});
          return http.Response(
            jsonEncode({
              'count': 1000,
              'next': 'https://pokeapi.co/api/v2/pokemon?offset=60&limit=20',
              'results': [
                {
                  'name': 'meowth',
                  'url': 'https://pokeapi.co/api/v2/pokemon-species/52/',
                },
              ],
            }),
            200,
          );
        });

        final page = await PokeApiService(client: client)
            .fetchPokemonPage(offset: 40, limit: 20);

        expect(page.totalCount, 1000);
        expect(page.results.single.name, 'meowth');
        expect(page.hasNextPage, isTrue);
      },
    );

    test('returns no search result for an unknown Pokémon name', () async {
      final client = MockClient((request) async {
        expect(
          request.url.path,
          '/api/v2/pokemon-species/not-a-pokemon',
        );
        return http.Response('{}', 404);
      });

      final result = await PokeApiService(client: client)
          .searchPokemonByName('not-a-pokemon');

      expect(result, isNull);
    });
  });

  group('additional Pokémon endpoints', () {
    test('loads evolution branches and their requirements', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v2/evolution-chain/67');
        return http.Response(
          jsonEncode({
            'chain': {
              'species': {
                'name': 'eevee',
                'url': 'https://pokeapi.co/api/v2/pokemon-species/133/',
              },
              'evolution_details': [],
              'evolves_to': [
                {
                  'species': {
                    'name': 'vaporeon',
                    'url': 'https://pokeapi.co/api/v2/pokemon-species/134/',
                  },
                  'evolution_details': [
                    {
                      'trigger': {'name': 'use-item'},
                      'item': {'name': 'water-stone'},
                      'evolves_to': [],
                    },
                  ],
                  'evolves_to': [],
                },
              ],
            },
          }),
          200,
        );
      });

      final chain = await PokeApiService(client: client)
          .fetchEvolutionChain(67);

      expect(chain.root.name, 'eevee');
      expect(chain.root.evolvesTo, hasLength(1));
      expect(chain.root.evolvesTo.single.id, 134);
      expect(
        chain.root.evolvesTo.single.requirements,
        contains('Use Water Stone'),
      );
    });

    test('loads encounter locations and available game versions', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v2/pokemon/25/encounters');
        return http.Response(
          jsonEncode([
            {
              'location_area': {'name': 'viridian-forest-area'},
              'version_details': [
                {
                  'version': {'name': 'red'},
                },
                {
                  'version': {'name': 'blue'},
                },
              ],
            },
          ]),
          200,
        );
      });

      final locations = await PokeApiService(client: client)
          .fetchEncounterLocations(25);

      expect(locations, hasLength(1));
      expect(locations.single.name, 'viridian-forest-area');
      expect(locations.single.versions, ['red', 'blue']);
    });
  });
}
