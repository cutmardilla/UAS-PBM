import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/database_service.dart';
import '../recipe/recipe_detail_screen.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({
    Key? key,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseService _db = DatabaseService();
  String _selectedCategory = 'Sarapan';
  List<Recipe>? _popularRecipes;
  List<Recipe>? _editorsChoice;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<String> _categories = [
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan',
    'Minuman'
  ];

  @override
  void initState() {
    super.initState();
    _initializeDb();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _onSearch(widget.initialQuery!);
    } else {
      _loadRecipes();
    }

    // Add listener for search text changes
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeDb() async {
    try {
      if (!_db.isConnected) {
        await _db.connect();
      }
    } catch (e) {
      print('Error connecting to database: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to connect to database. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _onSearch(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (!_db.isConnected) {
        await _db.connect();
      }

      // Load popular recipes
      final popularRecipes = await _db.getRecipesByCategory(_selectedCategory);

      // Load editor's choice (for now, using trending recipes as example)
      final editorsChoice = await _db.getTrendingRecipes();

      if (mounted) {
        setState(() {
          _popularRecipes = popularRecipes;
          _editorsChoice = editorsChoice;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recipes: $e');
      if (mounted) {
        setState(() {
          _error =
              'Failed to load recipes. Please check your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onCategorySelected(String category) async {
    setState(() {
      _selectedCategory = category;
      _searchController.clear(); // Clear search when category changes
    });
    await _loadRecipes();
  }

  Future<void> _onSearch(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      await _loadRecipes();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (!_db.isConnected) {
        await _db.connect();
      }

      final searchResults = await _db.searchRecipes(query);

      if (mounted) {
        setState(() {
          _popularRecipes = searchResults;
          _editorsChoice = null; // Hide editor's choice during search
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching recipes: $e');
      if (mounted) {
        setState(() {
          _error =
              'Failed to search recipes. Please check your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecipes,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRecipes,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _onSearch,
                            decoration: InputDecoration(
                              hintText: 'Search',
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = category == _selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _onCategorySelected(category);
                                    }
                                  },
                                  backgroundColor: Colors.grey[100],
                                  selectedColor:
                                      const Color(0xFF7FBFB6).withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF7FBFB6)
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Popular Recipes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_popularRecipes?.isEmpty ?? true)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No recipes found'),
                            ),
                          )
                        else
                          SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _popularRecipes?.length ?? 0,
                              itemBuilder: (context, index) {
                                final recipe = _popularRecipes![index];
                                return Container(
                                  width: 180,
                                  margin: EdgeInsets.only(
                                      right: index ==
                                              (_popularRecipes?.length ?? 0) - 1
                                          ? 0
                                          : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RecipeDetailScreen(
                                            recipe: recipe,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          child: Image.network(
                                            recipe.imageUrl,
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                height: 120,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipe.title,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    backgroundImage: recipe
                                                                .chefImageUrl !=
                                                            null
                                                        ? NetworkImage(recipe
                                                            .chefImageUrl!)
                                                        : null,
                                                    child: recipe
                                                                .chefImageUrl ==
                                                            null
                                                        ? const Icon(
                                                            Icons.person,
                                                            size: 16,
                                                            color: Colors.grey,
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'By ${recipe.chefName}',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Editor's Choice",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_editorsChoice?.isEmpty ?? true)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No editor\'s choice recipes found'),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: _editorsChoice!.map((recipe) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RecipeDetailScreen(
                                            recipe: recipe,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                            left: Radius.circular(12),
                                          ),
                                          child: Image.network(
                                            recipe.imageUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recipe.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor:
                                                          Colors.grey[200],
                                                      backgroundImage: recipe
                                                                  .chefImageUrl !=
                                                              null
                                                          ? NetworkImage(recipe
                                                              .chefImageUrl!)
                                                          : null,
                                                      child:
                                                          recipe.chefImageUrl ==
                                                                  null
                                                              ? const Icon(
                                                                  Icons.person,
                                                                  size: 16,
                                                                  color: Colors
                                                                      .grey,
                                                                )
                                                              : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      recipe.chefName,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7FBFB6)
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.bookmark_border,
                                            color: Color(0xFF7FBFB6),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }
}
