class PokemonSummary {
  const PokemonSummary({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final url = json['url'] as String;
    final id = int.tryParse(
      RegExp(r'/pokemon/(\d+)/?$').firstMatch(url)?.group(1) ?? '',
    );

    if (id == null) {
      throw const FormatException('ID Pokémon tidak valid.');
    }

    return PokemonSummary(id: id, name: name);
  }

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}

class PokemonAbility {
  const PokemonAbility({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}

class PokemonStat {
  const PokemonStat({
    required this.name,
    required this.value,
  });

  final String name;
  final int value;
}

class PokemonDetail {
  const PokemonDetail({
    required this.summary,
    required this.height,
    required this.weight,
    required this.types,
    required this.stats,
    required this.abilities,
  });

  final PokemonSummary summary;
  final int height;
  final int weight;
  final List<String> types;
  final List<PokemonStat> stats;
  final List<String> abilities;

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    final summary = PokemonSummary(
      id: json['id'] as int,
      name: json['name'] as String,
    );

    return PokemonDetail(
      summary: summary,
      height: json['height'] as int,
      weight: json['weight'] as int,
      types: (json['types'] as List<dynamic>)
          .map(
            (entry) => (entry as Map<String, dynamic>)['type']
                ['name'] as String,
          )
          .toList(growable: false),
      stats: (json['stats'] as List<dynamic>)
          .map((entry) {
            final statEntry = entry as Map<String, dynamic>;
            return PokemonStat(
              name: (statEntry['stat'] as Map<String, dynamic>)['name']
                  as String,
              value: statEntry['base_stat'] as int,
            );
          })
          .toList(growable: false),
      abilities: (json['abilities'] as List<dynamic>)
          .map(
            (entry) => (entry as Map<String, dynamic>)['ability']
                ['name'] as String,
          )
          .toList(growable: false),
    );
  }
}

class PokemonSpecies {
  const PokemonSpecies({
    required this.description,
    required this.growthRate,
  });

  final String description;
  final String growthRate;

  factory PokemonSpecies.fromJson(Map<String, dynamic> json) {
    final descriptions = json['flavor_text_entries'] as List<dynamic>;
    final englishDescription = descriptions.cast<Map<String, dynamic>>().firstWhere(
      (entry) =>
          (entry['language'] as Map<String, dynamic>)['name'] == 'en',
      orElse: () => <String, dynamic>{'flavor_text': 'Deskripsi tidak tersedia.'},
    );

    return PokemonSpecies(
      description: (englishDescription['flavor_text'] as String)
          .replaceAll(RegExp(r'\s+'), ' '),
      growthRate:
          (json['growth_rate'] as Map<String, dynamic>)['name'] as String,
    );
  }
}

class PokemonForm {
  const PokemonForm({
    required this.name,
    required this.types,
  });

  final String name;
  final List<String> types;

  factory PokemonForm.fromJson(Map<String, dynamic> json) {
    return PokemonForm(
      name: json['name'] as String,
      types: (json['types'] as List<dynamic>)
          .map(
            (entry) => (entry as Map<String, dynamic>)['type']
                ['name'] as String,
          )
          .toList(growable: false),
    );
  }
}
