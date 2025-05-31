import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../recipe/recipe_detail_screen.dart';
import '../../models/recipe.dart';

class ErrorBoundaryWidget extends StatelessWidget {
  final Widget child;
  final Function() onRetry;

  const ErrorBoundaryWidget({
    Key? key,
    required this.child,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      print('Error caught by ErrorBoundaryWidget:');
      print(details.exception);
      print(details.stack);

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              details.exception.toString(),
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    };

    return child;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  List<Recipe>? _trendingRecipes;
  List<Recipe>? _popularRecipes;
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _error;
  bool _isMounted = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All Menu', 'icon': Icons.restaurant_menu, 'category': 'All'},
    {'name': 'Sarapan', 'icon': Icons.breakfast_dining, 'category': 'Sarapan'},
    {
      'name': 'Makan Siang',
      'icon': Icons.lunch_dining,
      'category': 'Makan Siang'
    },
    {
      'name': 'Makan Malam',
      'icon': Icons.dinner_dining,
      'category': 'Makan Malam'
    },
  ];

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeAndLoad();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (_isMounted && mounted) {
      setState(fn);
    }
  }

  Future<void> _initializeAndLoad() async {
    try {
      print('Initializing home screen...');
      if (!_db.isConnected) {
        print('Database not connected, attempting to connect...');
        await _db.connect();
      }
      print('Database connected, loading recipes...');

      // Load trending recipes first
      _safeSetState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading trending recipes...');
      try {
        final trendingRecipes = await _db.getTrendingRecipes();
        if (_isMounted) {
          _safeSetState(() {
            _trendingRecipes = trendingRecipes;
            // Initially set popular recipes to trending recipes
            _popularRecipes = trendingRecipes;
          });
        }
      } catch (e) {
        print('Error loading trending recipes: $e');
        if (_isMounted) {
          _safeSetState(() {
            _trendingRecipes = [];
            _popularRecipes = [];
          });
        }
      }

      // Then load category recipes if needed
      if (_selectedCategory != 'All' && _isMounted) {
        print('Loading category recipes...');
        try {
          final categoryRecipes =
              await _db.getRecipesByCategory(_selectedCategory);
          if (_isMounted) {
            _safeSetState(() {
              _popularRecipes = categoryRecipes;
            });
          }
        } catch (e) {
          print('Error loading category recipes: $e');
          // Keep the trending recipes as popular recipes if category loading fails
        }
      }

      if (_isMounted) {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error initializing home screen: $e');
      print('Stack trace: $stackTrace');
      if (_isMounted) {
        _safeSetState(() {
          _error = 'Failed to initialize. Please try again.';
          _isLoading = false;
          _trendingRecipes = [];
          _popularRecipes = [];
        });
      }
    }
  }

  Future<void> _onCategorySelected(String category) async {
    if (_isLoading || !_isMounted) {
      print('Ignoring category selection while loading or unmounted');
      return;
    }

    print('Category selected: $category');
    _safeSetState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      if (category == 'All') {
        // Use trending recipes for "All" category
        _safeSetState(() {
          _popularRecipes = _trendingRecipes;
          _isLoading = false;
        });
        return;
      }

      final categoryRecipes = await _db.getRecipesByCategory(category);

      if (_isMounted) {
        _safeSetState(() {
          _popularRecipes = categoryRecipes;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading recipes for category $category: $e');
      print('Stack trace: $stackTrace');

      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load $category recipes: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _onCategorySelected(category),
              textColor: Colors.white,
            ),
          ),
        );

        // Revert to previous state
        _safeSetState(() {
          _selectedCategory = 'All';
          _popularRecipes = _trendingRecipes;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    print('Refreshing home screen...');
    try {
      if (!_db.isConnected) {
        print('Database disconnected, attempting to reconnect...');
        await _db.reconnect();
      }
      await _initializeAndLoad();
      print('Refresh completed successfully');
    } catch (e, stackTrace) {
      print('Error refreshing: $e');
      print('Stack trace: $stackTrace');
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _onRefresh(),
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWidget(
      onRetry: () {
        print('Retrying home screen initialization...');
        _initializeAndLoad();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading recipes...'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initializeAndLoad,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : (_trendingRecipes?.isEmpty ?? true) &&
                            (_popularRecipes?.isEmpty ?? true)
                        ? const Center(
                            child: Text('No recipes found'),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo is ScrollStartNotification) {
                                // Unfocus any text fields when scrolling starts
                                FocusScope.of(context).unfocus();
                              }
                              return true;
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Consumer<AuthProvider>(
                                              builder: (context, auth, _) =>
                                                  Text(
                                                'Hi, ${auth.user?.name ?? "Guest"}',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              'What would you like to cook?',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7FBFB6)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.menu_book,
                                            color: Color(0xFF7FBFB6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Search recipes',
                                        prefixIcon: const Icon(Icons.search,
                                            color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                      onSubmitted: (value) {
                                        if (value.isNotEmpty) {
                                          Navigator.pushNamed(
                                            context,
                                            '/search',
                                            arguments: value.trim(),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (_trendingRecipes?.isNotEmpty ??
                                      false) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Text(
                                                'Trending now ',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '🔥',
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                  context, '/search');
                                            },
                                            child: const Row(
                                              children: [
                                                Text(
                                                  'See all',
                                                  style: TextStyle(
                                                    color: Color(0xFF7FBFB6),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: Color(0xFF7FBFB6),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 280,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        itemCount:
                                            _trendingRecipes?.length ?? 0,
                                        itemBuilder: (context, index) {
                                          final recipe =
                                              _trendingRecipes![index];
                                          return Container(
                                            width: 280,
                                            margin: const EdgeInsets.only(
                                                right: 16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .vertical(
                                                          top: Radius.circular(
                                                              12),
                                                        ),
                                                        child: Image.network(
                                                          recipe.imageUrl,
                                                          height: 160,
                                                          width:
                                                              double.infinity,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Container(
                                                              height: 160,
                                                              color: Colors
                                                                  .grey[200],
                                                              child: const Icon(
                                                                Icons
                                                                    .broken_image,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        right: 8,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons.star,
                                                                color: Colors
                                                                    .amber,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                recipe.rating
                                                                    .toString(),
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          recipe.title,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          'By ${recipe.chefName}',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .timer_outlined,
                                                              size: 16,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              '${recipe.cookingTimeMinutes} mins',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .grey[600],
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 16),
                                                            Icon(
                                                              Icons
                                                                  .favorite_border,
                                                              size: 16,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              '${recipe.likes}',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .grey[600],
                                                                fontSize: 12,
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
                                  ],
                                  const SizedBox(height: 24),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Popular category',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: _categories.map((category) {
                                            final isSelected =
                                                category['category'] ==
                                                    _selectedCategory;
                                            return GestureDetector(
                                              onTap: () => _onCategorySelected(
                                                  category['category']),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 64,
                                                    height: 64,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFF7FBFB6)
                                                          : const Color(
                                                                  0xFF7FBFB6)
                                                              .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    child: Icon(
                                                      category['icon'],
                                                      color: isSelected
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF7FBFB6),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    category['name'],
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFF7FBFB6)
                                                          : Colors.grey,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_popularRecipes?.isNotEmpty ?? false) ...[
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Text(
                                        _selectedCategory == 'All'
                                            ? 'Popular Recipes'
                                            : '$_selectedCategory Recipes',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 120,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        itemCount: _popularRecipes?.length ?? 0,
                                        itemBuilder: (context, index) {
                                          final recipe =
                                              _popularRecipes![index];
                                          return Container(
                                            width: 200,
                                            margin: const EdgeInsets.only(
                                                right: 16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius
                                                            .horizontal(
                                                      left: Radius.circular(12),
                                                    ),
                                                    child: Image.network(
                                                      recipe.imageUrl,
                                                      width: 80,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          width: 80,
                                                          height: 120,
                                                          color:
                                                              Colors.grey[200],
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
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            recipe.title,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                      0xFF7FBFB6)
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: const Text(
                                                              'View Recipe',
                                                              style: TextStyle(
                                                                color: Color(
                                                                    0xFF7FBFB6),
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}
