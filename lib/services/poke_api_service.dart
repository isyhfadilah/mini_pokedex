import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokeApiException implements Exception {
  const PokeApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PokeApiService {
  PokeApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://pokeapi.co/api/v2';
  final http.Client _client;

  Future<PokemonPage> fetchPokemonPage({
    int offset = 0,
    int limit = 20,
  }) async {
    if (offset < 0 || limit <= 0) {
      throw ArgumentError('Offset harus >= 0 dan limit harus > 0.');
    }
    final json = await _getJson(
      '$_baseUrl/pokemon-species?limit=$limit&offset=$offset',
    );
    final results = json['results'] as List<dynamic>;
    return PokemonPage(
      results: results
          .map(
            (entry) => PokemonSummary.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
      totalCount: json['count'] as int,
      hasNextPage: json['next'] != null,
    );
  }

  Future<PokemonSummary?> searchPokemonByName(String query) async {
    final name = query.trim().toLowerCase();
    if (name.isEmpty) {
      return null;
    }

    try {
      final json = await _getJson(
        '$_baseUrl/pokemon-species/${Uri.encodeComponent(name)}',
      );
      return PokemonSummary(
        id: json['id'] as int,
        name: json['name'] as String,
      );
    } on PokeApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<PokemonDetail> fetchPokemonDetail(String name) async {
    final json = await _getJson('$_baseUrl/pokemon/${Uri.encodeComponent(name)}');
    return PokemonDetail.fromJson(json);
  }

  Future<PokemonSpecies> fetchPokemonSpecies(String name) async {
    final json = await _getJson(
      '$_baseUrl/pokemon-species/${Uri.encodeComponent(name)}',
    );
    return PokemonSpecies.fromJson(json);
  }

  Future<PokemonEvolutionChain> fetchEvolutionChain(int id) async {
    final json = await _getJson('$_baseUrl/evolution-chain/$id');
    return PokemonEvolutionChain.fromJson(json);
  }

  Future<List<PokemonEncounterLocation>> fetchEncounterLocations(
    int pokemonId,
  ) async {
    try {
      final json = jsonDecode(
        await _getBody('$_baseUrl/pokemon/$pokemonId/encounters'),
      ) as List<dynamic>;
      return json
          .map(
            (entry) => PokemonEncounterLocation.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } on FormatException {
      throw const PokeApiException('Respons lokasi Pokémon tidak dapat dibaca.');
    }
  }

  Future<PokemonForm> fetchPokemonForm(String name) async {
    final json = await _getJson(
      '$_baseUrl/pokemon-form/${Uri.encodeComponent(name)}',
    );
    return PokemonForm.fromJson(json);
  }

  Future<List<PokemonAbility>> fetchAbilities(List<String> abilityNames) async {
    final abilities = await Future.wait(
      abilityNames.map((name) async {
        final json = await _getJson(
          '$_baseUrl/ability/${Uri.encodeComponent(name)}',
        );
        final entries = (json['effect_entries'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final englishEntry = entries.firstWhere(
          (entry) =>
              (entry['language'] as Map<String, dynamic>)['name'] == 'en',
          orElse: () => <String, dynamic>{'short_effect': 'Efek tidak tersedia.'},
        );

        return PokemonAbility(
          name: json['name'] as String,
          description: englishEntry['short_effect'] as String,
        );
      }),
    );
    return abilities;
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    try {
      return jsonDecode(await _getBody(url)) as Map<String, dynamic>;
    } on FormatException {
      throw const PokeApiException('Respons PokéAPI tidak dapat dibaca.');
    }
  }

  Future<String> _getBody(String url) async {
    final response = await _client
        .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PokeApiException(
        'Permintaan ke PokéAPI gagal (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return response.body;
  }
}
