import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokeApiException implements Exception {
  const PokeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PokeApiService {
  PokeApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://pokeapi.co/api/v2';
  final http.Client _client;

  Future<List<PokemonSummary>> fetchPokemonList() async {
    final json = await _getJson('$_baseUrl/pokemon?limit=200');
    final results = json['results'] as List<dynamic>;
    return results
        .map(
          (entry) =>
              PokemonSummary.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: false);
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
    final response = await _client
        .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PokeApiException(
        'Permintaan ke PokéAPI gagal (${response.statusCode}).',
      );
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const PokeApiException('Respons PokéAPI tidak dapat dibaca.');
    }
  }
}
