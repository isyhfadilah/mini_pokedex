import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/poke_api_service.dart';
import 'pokemon_detail_screen.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key, required this.apiService});

  final PokeApiService apiService;

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  static const _pageSize = 20;

  final List<PokemonSummary> _pokemon = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchText = '';
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasNextPage = true;
  int _totalCount = 0;
  String? _listError;
  bool _isSearching = false;
  bool _searchLoading = false;
  PokemonSummary? _searchResult;
  String? _searchError;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isSearching &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter < 500) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _loadingMore = false;
      _hasNextPage = true;
      _listError = null;
      _pokemon.clear();
    });
    await _fetchPage();
  }

  Future<void> _loadNextPage() async {
    if (_initialLoading || _loadingMore || !_hasNextPage || _isSearching) {
      return;
    }
    setState(() {
      _loadingMore = true;
      _listError = null;
    });
    await _fetchPage();
  }

  Future<void> _fetchPage() async {
    try {
      final page = await widget.apiService.fetchPokemonPage(
        offset: _pokemon.length,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _pokemon.addAll(page.results);
        _totalCount = page.totalCount;
        _hasNextPage = page.hasNextPage;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _listError = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _searchPokemon(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    final requestId = ++_searchRequestId;

    setState(() {
      _isSearching = true;
      _searchLoading = true;
      _searchResult = null;
      _searchError = null;
    });

    try {
      final result = await widget.apiService.searchPokemonByName(query);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchResult = result;
        _searchLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchError = error.toString();
        _searchLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchRequestId++;
    _searchController.clear();
    setState(() {
      _searchText = '';
      _isSearching = false;
      _searchLoading = false;
      _searchResult = null;
      _searchError = null;
    });
  }

  void _openDetail(PokemonSummary pokemon) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PokemonDetailScreen(
          pokemon: pokemon,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  Widget _buildPokemonContent() {
    if (_isSearching) {
      if (_searchLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_searchError != null) {
        return _LoadError(
          message: 'Pencarian gagal.\n$_searchError',
          onRetry: () => _searchPokemon(_searchController.text),
        );
      }
      final result = _searchResult;
      if (result == null) {
        return const _EmptySearchResult();
      }
      return _buildPokemonGrid(
        [result],
        heading: 'Hasil pencarian',
        countLabel: '1 Pokémon',
        paginated: false,
      );
    }

    if (_initialLoading && _pokemon.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_listError != null && _pokemon.isEmpty) {
      return _LoadError(
        message: 'Daftar Pokémon gagal dimuat.\n$_listError',
        onRetry: _loadFirstPage,
      );
    }
    if (_pokemon.isEmpty) {
      return const _EmptySearchResult();
    }

    return _buildPokemonGrid(
      _pokemon,
      heading: 'Pokédex',
      countLabel: '${_pokemon.length} dari $_totalCount spesies',
      paginated: true,
    );
  }

  Widget _buildPokemonGrid(
    List<PokemonSummary> pokemon, {
    required String heading,
    required String countLabel,
    required bool paginated,
  }) {
    final showFooter = paginated &&
        (_loadingMore || (_listError != null && _pokemon.isNotEmpty));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Text(
                heading,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                countLabel,
                style: const TextStyle(
                  color: Color(0xFF8993A3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: pokemon.length + (showFooter ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 208,
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
            ),
            itemBuilder: (context, index) {
              if (index >= pokemon.length) {
                if (_loadingMore) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return Center(
                  child: TextButton.icon(
                    onPressed: _loadNextPage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba muat lagi'),
                  ),
                );
              }

              final item = pokemon[index];
              return _PokemonCard(
                pokemon: item,
                onTap: () => _openDetail(item),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.catching_pokemon, color: Color(0xFFEF6B55), size: 25),
            SizedBox(width: 8),
            Text(
              'pokodex',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFFEF6B55), size: 8),
                SizedBox(width: 6),
                Text(
                  'KANTO',
                  style: TextStyle(
                    color: Color(0xFFB94D3C),
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'YOUR POCKET ADVENTURE',
                      style: TextStyle(
                        color: Color(0xFF3A8B63),
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Temukan teman\npetualanganmu.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kenali Pokémon baru dan lengkapi koleksimu.',
                    style: TextStyle(
                      color: const Color(0xFF768196),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) =>
                        setState(() => _searchText = value),
                    onSubmitted: _searchPokemon,
                    decoration: InputDecoration(
                      hintText: 'Cari Pokémon...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchText.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildPokemonContent()),
          ],
        ),
      ),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  const _PokemonCard({required this.pokemon, required this.onTap});

  final PokemonSummary pokemon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _cardColors[pokemon.id % _cardColors.length];
    return Material(
      color: accent.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: 35,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#${pokemon.id.toString().padLeft(3, '0')}',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 17,
                        color: accent.withValues(alpha: 0.75),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: 'pokemon-${pokemon.id}',
                        child: Image.network(
                          pokemon.imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFEF6B55),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => Icon(
                            Icons.catching_pokemon,
                            size: 72,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    _capitalize(pokemon.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF202B3C),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 42, color: Color(0xFFEF6B55)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: Color(0xFF9AA4B2),
          ),
          SizedBox(height: 10),
          Text(
            'Pokémon tidak ditemukan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Periksa ejaan nama lalu coba lagi.',
            style: TextStyle(color: Color(0xFF768196)),
          ),
        ],
      ),
    );
  }
}

const _cardColors = [
  Color(0xFF45A880),
  Color(0xFFE9A641),
  Color(0xFF7187D5),
  Color(0xFFE87962),
  Color(0xFF54A6B4),
  Color(0xFF9A77C5),
];

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
