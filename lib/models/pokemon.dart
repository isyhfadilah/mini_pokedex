class PokemonSummary {
  const PokemonSummary({required this.id, required this.name});

  final int id;
  final String name;

  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final url = json['url'] as String;
    final id = int.tryParse(
      RegExp(r'/(?:pokemon|pokemon-species)/(\d+)/?$')
              .firstMatch(url)
              ?.group(1) ??
          '',
    );

    if (id == null) {
      throw const FormatException('ID Pokémon tidak valid.');
    }

    return PokemonSummary(id: id, name: name);
  }

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}

class PokemonPage {
  const PokemonPage({
    required this.results,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<PokemonSummary> results;
  final int totalCount;
  final bool hasNextPage;
}

class PokemonAbility {
  const PokemonAbility({required this.name, required this.description});

  final String name;
  final String description;
}

class PokemonStat {
  const PokemonStat({required this.name, required this.value});

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
            (entry) =>
                (entry as Map<String, dynamic>)['type']['name'] as String,
          )
          .toList(growable: false),
      stats: (json['stats'] as List<dynamic>)
          .map((entry) {
            final statEntry = entry as Map<String, dynamic>;
            return PokemonStat(
              name:
                  (statEntry['stat'] as Map<String, dynamic>)['name'] as String,
              value: statEntry['base_stat'] as int,
            );
          })
          .toList(growable: false),
      abilities: (json['abilities'] as List<dynamic>)
          .map(
            (entry) =>
                (entry as Map<String, dynamic>)['ability']['name'] as String,
          )
          .toList(growable: false),
    );
  }
}

class PokemonSpecies {
  const PokemonSpecies({
    required this.description,
    required this.growthRate,
    required this.evolutionChainId,
  });

  final String description;
  final String growthRate;
  final int evolutionChainId;

  factory PokemonSpecies.fromJson(Map<String, dynamic> json) {
    final descriptions = json['flavor_text_entries'] as List<dynamic>;
    final englishDescription = descriptions
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (entry) =>
              (entry['language'] as Map<String, dynamic>)['name'] == 'en',
          orElse: () => <String, dynamic>{
            'flavor_text': 'Deskripsi tidak tersedia.',
          },
        );

    final evolutionChainUrl =
        (json['evolution_chain'] as Map<String, dynamic>)['url'] as String;
    final evolutionChainId = int.tryParse(
      RegExp(r'/evolution-chain/(\d+)/?$')
              .firstMatch(evolutionChainUrl)
              ?.group(1) ??
          '',
    );
    if (evolutionChainId == null) {
      throw const FormatException('ID rantai evolusi tidak valid.');
    }

    return PokemonSpecies(
      description: (englishDescription['flavor_text'] as String).replaceAll(
        RegExp(r'\s+'),
        ' ',
      ),
      growthRate:
          (json['growth_rate'] as Map<String, dynamic>)['name'] as String,
      evolutionChainId: evolutionChainId,
    );
  }
}

class PokemonEvolutionChain {
  const PokemonEvolutionChain({required this.root});

  final PokemonEvolutionNode root;

  factory PokemonEvolutionChain.fromJson(Map<String, dynamic> json) {
    return PokemonEvolutionChain(
      root: PokemonEvolutionNode.fromJson(
        json['chain'] as Map<String, dynamic>,
      ),
    );
  }
}

class PokemonEvolutionNode {
  const PokemonEvolutionNode({
    required this.id,
    required this.name,
    required this.requirements,
    required this.evolvesTo,
  });

  final int id;
  final String name;
  final List<String> requirements;
  final List<PokemonEvolutionNode> evolvesTo;

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  factory PokemonEvolutionNode.fromJson(Map<String, dynamic> json) {
    final species = json['species'] as Map<String, dynamic>;
    final speciesUrl = species['url'] as String;
    final id = int.tryParse(
      RegExp(r'/pokemon-species/(\d+)/?$').firstMatch(speciesUrl)?.group(1) ??
          '',
    );
    if (id == null) {
      throw const FormatException(
        'ID Pokémon pada rantai evolusi tidak valid.',
      );
    }

    final details = (json['evolution_details'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final requirements = details.expand(_parseEvolutionRequirements).toList();

    return PokemonEvolutionNode(
      id: id,
      name: species['name'] as String,
      requirements: requirements,
      evolvesTo: (json['evolves_to'] as List<dynamic>)
          .map(
            (entry) =>
                PokemonEvolutionNode.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

class PokemonEncounterLocation {
  const PokemonEncounterLocation({required this.name, required this.versions});

  final String name;
  final List<String> versions;

  factory PokemonEncounterLocation.fromJson(Map<String, dynamic> json) {
    final versionDetails = (json['version_details'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final locationArea = json['location_area'] as Map<String, dynamic>;
    return PokemonEncounterLocation(
      name: locationArea['name'] as String,
      versions: versionDetails
          .map(
            (entry) =>
                (entry['version'] as Map<String, dynamic>)['name'] as String,
          )
          .toSet()
          .toList(growable: false),
    );
  }
}

Iterable<String> _parseEvolutionRequirements(
  Map<String, dynamic> details,
) sync* {
  final trigger =
      (details['trigger'] as Map<String, dynamic>)['name'] as String;
  final minimumLevel = details['min_level'] as int?;
  final item = details['item'] as Map<String, dynamic>?;
  final heldItem = details['held_item'] as Map<String, dynamic>?;
  final move = details['known_move'] as Map<String, dynamic>?;
  final location = details['location'] as Map<String, dynamic>?;
  final happiness = details['min_happiness'] as int?;
  final timeOfDay = details['time_of_day'] as String?;

  if (minimumLevel != null) yield 'Level $minimumLevel';
  if (item != null) yield 'Use ${_titleCase(item['name'] as String)}';
  if (heldItem != null) yield 'Hold ${_titleCase(heldItem['name'] as String)}';
  if (move != null) yield 'Know ${_titleCase(move['name'] as String)}';
  if (location != null) {
    yield _titleCase((location['name'] as String).replaceAll('-', ' '));
  }
  if (happiness != null) yield 'Happiness $happiness+';
  if (timeOfDay != null && timeOfDay.isNotEmpty) yield _titleCase(timeOfDay);
  if (trigger != 'level-up' && trigger != 'use-item') {
    yield _titleCase(trigger.replaceAll('-', ' '));
  }
}

String _titleCase(String value) => value
    .replaceAll('-', ' ')
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

class PokemonForm {
  const PokemonForm({required this.name, required this.types});

  final String name;
  final List<String> types;

  factory PokemonForm.fromJson(Map<String, dynamic> json) {
    return PokemonForm(
      name: json['name'] as String,
      types: (json['types'] as List<dynamic>)
          .map(
            (entry) =>
                (entry as Map<String, dynamic>)['type']['name'] as String,
          )
          .toList(growable: false),
    );
  }
}
