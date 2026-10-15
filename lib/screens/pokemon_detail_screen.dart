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
      appBar: AppBar(title: Text(_capitalize(widget.pokemon.name))),
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
  late final Future<PokemonForm> _formFuture;
  late final Future<List<PokemonAbility>> _abilitiesFuture;

  @override
  void initState() {
    super.initState();
    final name = widget.detail.summary.name;
    _speciesFuture = widget.apiService.fetchPokemonSpecies(name);
    _formFuture = widget.apiService.fetchPokemonForm(name);
    _abilitiesFuture = widget.apiService.fetchAbilities(
      widget.detail.abilities,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          height: 230,
          decoration: BoxDecoration(
            color: const Color(0xFFF8E9E3),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Hero(
            tag: 'pokemon-${detail.summary.id}',
            child: Image.network(
              detail.summary.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.catching_pokemon,
                size: 120,
                color: Color(0xFFCC3D3D),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '#${detail.summary.id.toString().padLeft(3, '0')}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _capitalize(detail.summary.name),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: detail.types
              .map((type) => _TypeChip(label: _capitalize(type)))
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MeasurementCard(
                label: 'Berat',
                value: '${(detail.weight / 10).toStringAsFixed(1)} kg',
                icon: Icons.monitor_weight_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Statistik dasar'),
        const SizedBox(height: 12),
        ...detail.stats.map((stat) => _StatRow(stat: stat)),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Tentang'),
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            FutureBuilder<T>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
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
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFCC3D3D)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color(0xFFF8E9E3),
      side: BorderSide.none,
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
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final PokemonStat stat;

  @override
  Widget build(BuildContext context) {
    final label = _capitalize(stat.name.replaceAll('-', ' '));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
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
              color: const Color(0xFFCC3D3D),
              backgroundColor: const Color(0xFFF1D9D2),
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
