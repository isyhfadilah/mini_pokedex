import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/poke_api_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  const PokemonDetailScreen({
    super.key,
    required this.pokemon,
    required this.apiService,
  });

  final PokemonSummary pokemon;
  final PokeApiService apiService;

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  late Future<PokemonDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = widget.apiService.fetchPokemonDetail(widget.pokemon.name);
  }

  void _retry() {
    setState(() {
      _detailFuture = widget.apiService.fetchPokemonDetail(widget.pokemon.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Pokémon',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<PokemonDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detail Pokémon gagal dimuat.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = snapshot.data!;
          return _PokemonDetailContent(
            detail: detail,
            apiService: widget.apiService,
          );
        },
      ),
    );
  }
}

class _PokemonDetailContent extends StatefulWidget {
  const _PokemonDetailContent({required this.detail, required this.apiService});

  final PokemonDetail detail;
  final PokeApiService apiService;

  @override
  State<_PokemonDetailContent> createState() => _PokemonDetailContentState();
}

class _PokemonDetailContentState extends State<_PokemonDetailContent> {
  late final Future<PokemonSpecies> _speciesFuture;
  late final Future<PokemonEvolutionChain> _evolutionFuture;
  late final Future<List<PokemonEncounterLocation>> _encounterFuture;
  late final Future<PokemonForm> _formFuture;
  late final Future<List<PokemonAbility>> _abilitiesFuture;

  @override
  void initState() {
    super.initState();
    final name = widget.detail.summary.name;
    _speciesFuture = widget.apiService.fetchPokemonSpecies(name);
    _evolutionFuture = _speciesFuture.then(
      (species) =>
          widget.apiService.fetchEvolutionChain(species.evolutionChainId),
    );
    _encounterFuture = widget.apiService.fetchEncounterLocations(
      widget.detail.summary.id,
    );
    _formFuture = widget.apiService.fetchPokemonForm(name);
    _abilitiesFuture = widget.apiService.fetchAbilities(
      widget.detail.abilities,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final accent = _typeColor(detail.types.first);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Container(
          height: 255,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: -28,
                bottom: -62,
                child: Container(
                  width: 205,
                  height: 205,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${detail.summary.id.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              Hero(
                tag: 'pokemon-${detail.summary.id}',
                child: Image.network(
                  detail.summary.imageUrl,
                  fit: BoxFit.contain,
                  width: 230,
                  height: 230,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.catching_pokemon, size: 120, color: accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _capitalize(detail.summary.name),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.7),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          children: detail.types
              .map(
                (type) => _TypeChip(
                  label: _capitalize(type),
                  color: _typeColor(type),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _MeasurementCard(
                label: 'Tinggi',
                value: '${(detail.height / 10).toStringAsFixed(1)} m',
                icon: Icons.height,
                accent: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MeasurementCard(
                label: 'Berat',
                value: '${(detail.weight / 10).toStringAsFixed(1)} kg',
                icon: Icons.monitor_weight_outlined,
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Statistik dasar'),
        const SizedBox(height: 12),
        ...detail.stats.map((stat) => _StatRow(stat: stat, accent: accent)),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Tentang'),
        _AsyncInfoSection<PokemonEvolutionChain>(
          title: 'Rantai evolusi',
          future: _evolutionFuture,
          builder: (chain) => _EvolutionTree(root: chain.root),
        ),
        _AsyncInfoSection<List<PokemonEncounterLocation>>(
          title: 'Lokasi ditemukan',
          future: _encounterFuture,
          builder: (locations) => locations.isEmpty
              ? const Text('Belum ada data lokasi untuk Pokémon ini.')
              : _EncounterLocationList(locations: locations),
        ),
        _AsyncInfoSection<PokemonSpecies>(
          title: 'Deskripsi',
          future: _speciesFuture,
          builder: (species) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(species.description),
              const SizedBox(height: 8),
              Text(
                'Growth rate: ${_capitalize(species.growthRate.replaceAll('-', ' '))}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        _AsyncInfoSection<PokemonForm>(
          title: 'Form',
          future: _formFuture,
          builder: (form) => Text(
            '${_capitalize(form.name)} · ${form.types.map(_capitalize).join(', ')}',
          ),
        ),
        _AsyncInfoSection<List<PokemonAbility>>(
          title: 'Ability',
          future: _abilitiesFuture,
          builder: (abilities) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: abilities
                .map(
                  (ability) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalize(ability.name.replaceAll('-', ' ')),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(ability.description),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _EvolutionTree extends StatelessWidget {
  const _EvolutionTree({required this.root});

  final PokemonEvolutionNode root;

  @override
  Widget build(BuildContext context) => _buildNode(root);

  Widget _buildNode(PokemonEvolutionNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F5F8),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                node.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.catching_pokemon,
                  color: Color(0xFF9AA4B2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalize(node.name),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (node.requirements.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      node.requirements.join(' · '),
                      style: const TextStyle(
                        color: Color(0xFF768196),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        for (final child in node.evolvesTo)
          Padding(
            padding: const EdgeInsets.only(left: 17, top: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  color: Color(0xFFB4BCC8),
                  size: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18, top: 4, bottom: 8),
                  child: _buildNode(child),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EncounterLocationList extends StatelessWidget {
  const _EncounterLocationList({required this.locations});

  final List<PokemonEncounterLocation> locations;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(
        '${locations.length} lokasi ditemukan',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text('Ketuk untuk melihat lokasi dan game'),
      children: locations
          .map(
            (location) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(
                Icons.place_outlined,
                color: Color(0xFFEF6B55),
              ),
              title: Text(_capitalize(location.name.replaceAll('-', ' '))),
              subtitle: location.versions.isEmpty
                  ? null
                  : Text(
                      location.versions
                          .map(
                            (version) =>
                                _capitalize(version.replaceAll('-', ' ')),
                          )
                          .join(' · '),
                    ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AsyncInfoSection<T> extends StatelessWidget {
  const _AsyncInfoSection({
    required this.title,
    required this.future,
    required this.builder,
  });

  final String title;
  final Future<T> future;
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEBEEF3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<T>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(
                    minHeight: 3,
                    color: Color(0xFFEF6B55),
                    backgroundColor: Color(0xFFF2F3F6),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Gagal memuat $title: ${snapshot.error}',
                    style: TextStyle(color: Colors.red.shade700),
                  );
                }
                return builder(snapshot.requireData);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEEF3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 7),
          Text(label, style: const TextStyle(color: Color(0xFF768196))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat, required this.accent});

  final PokemonStat stat;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final label = _capitalize(stat.name.replaceAll('-', ' '));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${stat.value}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (stat.value / 255).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.13),
            ),
          ),
        ],
      ),
    );
  }
}

Color _typeColor(String type) {
  return switch (type) {
    'grass' || 'bug' => const Color(0xFF48A878),
    'fire' => const Color(0xFFE87955),
    'water' || 'ice' => const Color(0xFF5389D4),
    'electric' => const Color(0xFFD5A52D),
    'poison' || 'ghost' => const Color(0xFF9064B8),
    'psychic' || 'fairy' => const Color(0xFFD66C9B),
    'ground' || 'rock' => const Color(0xFFB1844D),
    'fighting' || 'dragon' => const Color(0xFFD15D56),
    _ => const Color(0xFF748092),
  };
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
