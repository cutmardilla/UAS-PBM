import 'package:mongo_dart/mongo_dart.dart';
import 'dart:async';
import '../models/recipe.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Db? _db;
  DbCollection? _recipes;
  DbCollection? _users;
  DbCollection? _userLikes;
  bool _isConnected = false;

  // Add getters for collections and connection state
  DbCollection? get users => _ensureConnected() ? _users : null;
  DbCollection? get recipes => _ensureConnected() ? _recipes : null;
  DbCollection? get userLikes => _ensureConnected() ? _userLikes : null;
  bool get isConnected => _isConnected;
  Db? get database => _db;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  bool _ensureConnected() {
    if (!_isConnected) {
      print('Database not connected. Please call connect() first.');
      return false;
    }
    return true;
  }

  Future<void> connect() async {
    if (_isConnected) {
      print('Already connected to MongoDB Atlas');
      return;
    }

    try {
      print('Connecting to MongoDB Atlas...');
      _db = await Db.create(
          'mongodb+srv://rafliafriza90:Y9HOoJybQtABpZUk@rafli.6lc8d.mongodb.net/sendokgarpu?retryWrites=true&w=majority&appName=Rafli');
      await _db!.open();
      print('Connected to MongoDB Atlas');

      // Initialize collections
      _recipes = _db!.collection('recipes');
      _users = _db!.collection('users');
      _userLikes = _db!.collection('user_likes');
      _isConnected = true;

      // Verify connection and check if we need to initialize sample data
      try {
        final recipesCount = await _recipes!.count();
        print('Found $recipesCount recipes in database');

        if (recipesCount == 0) {
          print('No recipes found, initializing sample data...');
          await _initializeSampleData();
        }
      } catch (e) {
        print('Error checking recipes: $e');
        await disconnect();
        throw Exception('Failed to verify database connection');
      }
    } catch (e) {
      print('Error connecting to MongoDB: $e');
      await disconnect();
      rethrow;
    }
  }

  Future<void> _initializeSampleData() async {
    try {
      // Check if data already exists
      final usersCount = await _users!.count();
      final recipesCount = await _recipes!.count();

      print('Found $usersCount users and $recipesCount recipes in database');

      if (usersCount > 0 || recipesCount > 0) {
        print('Sample data already exists, skipping initialization');
        return;
      }

      print('Initializing sample data...');

      // Create users first
      final users = [
        {
          '_id': ObjectId(),
          'name': 'Chef John Doe',
          'email': 'john@example.com',
          'password': 'hashed_password_1',
          'image_url':
              'https://images.unsplash.com/photo-1566554273541-37a9ca77b91f?ixlib=rb-4.0.3',
          'created_at': DateTime.now(),
          'last_login': DateTime.now()
        },
        {
          '_id': ObjectId(),
          'name': 'Chef Maria Garcia',
          'email': 'maria@example.com',
          'password': 'hashed_password_2',
          'image_url':
              'https://images.unsplash.com/photo-1566554273541-37a9ca77b91f?ixlib=rb-4.0.3',
          'created_at': DateTime.now(),
          'last_login': DateTime.now()
        }
      ];

      print('Inserting users...');
      await _users!.insertMany(users);
      print('Users inserted successfully');

      // Get user IDs for recipes
      final chefJohn = users[0]['_id'];
      final chefMaria = users[1]['_id'];

      final recipes = [
        {
          '_id': ObjectId(),
          'title': 'Nasi Goreng Special',
          'description': 'Nasi goreng dengan bumbu special dan telur mata sapi',
          'image_url':
              'https://images.unsplash.com/photo-1512058564366-18510be2db19?ixlib=rb-4.0.3',
          'chef_id': chefJohn,
          'cooking_time_minutes': 20,
          'ingredients': [
            '2 piring nasi putih',
            '2 butir telur',
            '3 siung bawang putih',
            '5 siung bawang merah',
            '2 cabai merah',
            'Kecap manis',
            'Garam dan merica'
          ],
          'instructions': [
            'Haluskan bawang putih, bawang merah, dan cabai',
            'Panaskan minyak dan tumis bumbu halus',
            'Masukkan nasi dan aduk rata',
            'Tambahkan kecap, garam, dan merica',
            'Goreng telur mata sapi',
            'Sajikan nasi goreng dengan telur di atasnya'
          ],
          'rating': 4.5,
          'reviews': 10,
          'categories': ['Sarapan', 'Makan Siang'],
          'created_at': DateTime.now(),
          'likes': 15
        },
        {
          '_id': ObjectId(),
          'title': 'Mie Goreng Jawa',
          'description': 'Mie goreng dengan bumbu khas Jawa yang lezat',
          'image_url':
              'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?ixlib=rb-4.0.3',
          'chef_id': chefMaria,
          'cooking_time_minutes': 25,
          'ingredients': [
            '1 bungkus mie telur',
            '2 butir telur',
            '100g kol iris',
            '2 batang daun bawang',
            'Bumbu mie goreng',
            'Kecap manis'
          ],
          'instructions': [
            'Rebus mie hingga matang',
            'Tumis bumbu hingga harum',
            'Masukkan sayuran dan telur',
            'Tambahkan mie dan kecap',
            'Aduk rata hingga matang'
          ],
          'rating': 4.7,
          'reviews': 8,
          'categories': ['Makan Siang', 'Makan Malam'],
          'created_at': DateTime.now(),
          'likes': 12
        },
        {
          '_id': ObjectId(),
          'title': 'Ayam Goreng Crispy',
          'description':
              'Ayam goreng tepung yang renyah di luar, juicy di dalam',
          'image_url':
              'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?ixlib=rb-4.0.3',
          'chef_id': chefJohn,
          'cooking_time_minutes': 40,
          'ingredients': [
            '500g ayam potong',
            '200g tepung terigu',
            '1 bungkus tepung bumbu',
            '2 butir telur',
            'Minyak goreng'
          ],
          'instructions': [
            'Marinasi ayam dengan bumbu selama 30 menit',
            'Balur ayam dengan tepung',
            'Celupkan ke telur kocok',
            'Balur lagi dengan tepung',
            'Goreng dalam minyak panas hingga keemasan'
          ],
          'rating': 4.8,
          'reviews': 15,
          'categories': ['Makan Siang', 'Makan Malam'],
          'created_at': DateTime.now(),
          'likes': 20
        },
        {
          '_id': ObjectId(),
          'title': 'Bubur Ayam Special',
          'description':
              'Bubur ayam dengan topping lengkap dan kuah kaldu yang gurih',
          'image_url':
              'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?ixlib=rb-4.0.3',
          'chef_id': chefMaria,
          'cooking_time_minutes': 45,
          'ingredients': [
            '2 cup beras',
            '200g ayam suwir',
            'Kecap asin',
            'Daun bawang',
            'Bawang goreng',
            'Kerupuk'
          ],
          'instructions': [
            'Masak beras dengan air lebih banyak hingga menjadi bubur',
            'Rebus ayam dan suwir-suwir',
            'Siapkan topping: daun bawang, bawang goreng',
            'Sajikan bubur dengan ayam suwir dan topping'
          ],
          'rating': 4.6,
          'reviews': 12,
          'categories': ['Sarapan'],
          'created_at': DateTime.now(),
          'likes': 18
        }
      ];

      print('Inserting recipes...');
      await _recipes!.insertMany(recipes);
      print('Recipes inserted successfully');

      // Create some initial likes
      final likes = [
        {
          '_id': ObjectId(),
          'user_id': chefJohn,
          'recipe_id': recipes[1]['_id'], // John likes Maria's Mie Goreng
          'created_at': DateTime.now()
        },
        {
          '_id': ObjectId(),
          'user_id': chefMaria,
          'recipe_id': recipes[0]['_id'], // Maria likes John's Nasi Goreng
          'created_at': DateTime.now()
        }
      ];

      print('Inserting likes...');
      await _userLikes!.insertMany(likes);
      print('Likes inserted successfully');

      print('Sample data initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing sample data: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to initialize sample data');
    }
  }

  Future<void> disconnect() async {
    try {
      await _db?.close();
    } catch (e) {
      print('Error closing database connection: $e');
    } finally {
      _db = null;
      _recipes = null;
      _users = null;
      _userLikes = null;
      _isConnected = false;
    }
  }

  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  // Get trending recipes
  Future<List<Recipe>> getTrendingRecipes() async {
    if (!_ensureConnected()) return [];

    try {
      print('Getting trending recipes...');

      // Simplify the query to just get recipes sorted by likes
      final results = await _recipes!
          .find(where.sortBy('likes', descending: true).limit(10))
          .toList();

      print('Raw results from MongoDB: ${results.length} documents');
      if (results.isEmpty) {
        print('No trending recipes found in database');
        return [];
      }

      print('Starting to map documents to Recipe objects...');
      final recipes = <Recipe>[];

      // Get all users first to avoid multiple lookups
      final userIds = results.map((doc) => doc['chef_id']).toSet();
      final usersMap = <String, Map<String, dynamic>>{};

      for (final userId in userIds) {
        try {
          final user = await _users!.findOne(where.id(userId));
          if (user != null) {
            usersMap[userId.toHexString()] = user;
          }
        } catch (e) {
          print('Error fetching user $userId: $e');
        }
      }

      for (final doc in results) {
        try {
          final chefId = doc['chef_id'].toHexString();
          final user = usersMap[chefId];

          final recipe = Recipe.fromMap({
            ...doc,
            'id': doc['_id'].toHexString(),
            'chef_name': user?['name'] ?? 'Unknown Chef',
            'chef_image_url': user?['image_url'],
          });
          print('Successfully mapped recipe: ${recipe.title}');
          recipes.add(recipe);
        } catch (e, stackTrace) {
          print('Error mapping individual recipe: $e');
          print('Stack trace: $stackTrace');
          continue;
        }
      }

      print('Successfully mapped ${recipes.length} recipes');
      return recipes;
    } catch (e, stackTrace) {
      print('Error getting trending recipes: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get recipes by category
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    if (!_ensureConnected()) return [];

    try {
      print('Getting recipes for category: $category');

      // Simplify the query to just get recipes by category
      final results = await _recipes!
          .find(
            where
                .eq('categories', category)
                .sortBy('created_at', descending: true)
                .limit(10),
          )
          .toList();

      print('Raw category results from MongoDB: ${results.length} documents');
      if (results.isEmpty) {
        print('No recipes found for category $category');
        return [];
      }

      print('Starting to map category documents to Recipe objects...');
      final recipes = <Recipe>[];

      // Get all users first to avoid multiple lookups
      final userIds = results.map((doc) => doc['chef_id']).toSet();
      final usersMap = <String, Map<String, dynamic>>{};

      for (final userId in userIds) {
        try {
          final user = await _users!.findOne(where.id(userId));
          if (user != null) {
            usersMap[userId.toHexString()] = user;
          }
        } catch (e) {
          print('Error fetching user $userId: $e');
        }
      }

      for (final doc in results) {
        try {
          final chefId = doc['chef_id'].toHexString();
          final user = usersMap[chefId];

          final recipe = Recipe.fromMap({
            ...doc,
            'id': doc['_id'].toHexString(),
            'chef_name': user?['name'] ?? 'Unknown Chef',
            'chef_image_url': user?['image_url'],
          });
          print('Successfully mapped category recipe: ${recipe.title}');
          recipes.add(recipe);
        } catch (e, stackTrace) {
          print('Error mapping individual category recipe: $e');
          print('Stack trace: $stackTrace');
          continue;
        }
      }

      print('Successfully mapped ${recipes.length} category recipes');
      return recipes;
    } catch (e, stackTrace) {
      print('Error getting recipes by category: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Search recipes
  Future<List<Recipe>> searchRecipes(String query) async {
    if (!_ensureConnected()) return [];

    try {
      print('Searching for recipes with query: $query');

      // Create a case-insensitive regex pattern
      final pattern = RegExp(query, caseSensitive: false);

      final pipeline = [
        {
          '\$match': {
            '\$or': [
              {
                'title': {'\$regex': pattern.pattern, '\$options': 'i'}
              },
              {
                'description': {'\$regex': pattern.pattern, '\$options': 'i'}
              }
            ]
          }
        },
        {
          '\$lookup': {
            'from': 'users',
            'localField': 'chef_id',
            'foreignField': '_id',
            'as': 'chef'
          }
        },
        {'\$unwind': '\$chef'},
        {
          '\$sort': {'created_at': -1}
        },
        {'\$limit': 10}
      ];

      print('Executing aggregation pipeline...');
      final results = await _recipes!.aggregateToStream(pipeline).toList();
      print('Found ${results.length} results');

      return results
          .map((doc) {
            try {
              return Recipe.fromMap({
                ...doc,
                'id': doc['_id'].toHexString(),
                'chef_name': doc['chef']['name'],
                'chef_image_url': doc['chef']['image_url'],
              });
            } catch (e) {
              print('Error mapping recipe document: $e');
              print('Problematic document: $doc');
              return null;
            }
          })
          .where((recipe) => recipe != null)
          .cast<Recipe>()
          .toList();
    } catch (e) {
      print('Error searching recipes: $e');
      throw Exception('Failed to search recipes: $e');
    }
  }

  // Get recipe by id
  Future<Recipe?> getRecipeById(String id) async {
    final pipeline = AggregationPipelineBuilder()
        .addStage(Match(where.id(ObjectId.fromHexString(id))))
        .addStage(Lookup(
            from: 'users',
            localField: 'chef_id',
            foreignField: '_id',
            as: 'chef'))
        .addStage(Unwind(Field('chef')))
        .build();

    final results = await _recipes!.aggregateToStream(pipeline).toList();
    if (results.isEmpty) return null;

    return Recipe.fromMap({
      ...results.first,
      'id': results.first['_id'].toHexString(),
      'chef_name': results.first['chef']['name'],
      'chef_image_url': results.first['chef']['image_url'],
    });
  }

  // Add recipe
  Future<String> addRecipe(Recipe recipe) async {
    final doc = {
      'title': recipe.title,
      'description': recipe.description,
      'image_url': recipe.imageUrl,
      'chef_id': ObjectId.fromHexString(recipe.chefId),
      'cooking_time_minutes': recipe.cookingTimeMinutes,
      'ingredients': recipe.ingredients,
      'instructions': recipe.instructions,
      'rating': recipe.rating,
      'reviews': recipe.reviews,
      'categories': recipe.categories,
      'created_at': recipe.createdAt,
      'likes': recipe.likes,
    };

    final result = await _recipes!.insertOne(doc);
    return result.id.toHexString();
  }

  // Update recipe
  Future<void> updateRecipe(Recipe recipe) async {
    await _recipes!.updateOne(
      where.id(ObjectId.fromHexString(recipe.id!)),
      modify
          .set('title', recipe.title)
          .set('description', recipe.description)
          .set('image_url', recipe.imageUrl)
          .set('cooking_time_minutes', recipe.cookingTimeMinutes)
          .set('ingredients', recipe.ingredients)
          .set('instructions', recipe.instructions)
          .set('rating', recipe.rating)
          .set('reviews', recipe.reviews)
          .set('categories', recipe.categories)
          .set('likes', recipe.likes),
    );
  }

  // Delete recipe
  Future<void> deleteRecipe(String id) async {
    await _recipes!.deleteOne(where.id(ObjectId.fromHexString(id)));
  }

  // Like recipe
  Future<void> likeRecipe(String recipeId, String userId) async {
    final recipeObjectId = ObjectId.fromHexString(recipeId);
    final userObjectId = ObjectId.fromHexString(userId);

    // Check if user already liked the recipe
    final existingLike = await _userLikes!.findOne(
        where.eq('user_id', userObjectId).eq('recipe_id', recipeObjectId));

    if (existingLike == null) {
      // Add like
      await _userLikes!.insertOne({
        'user_id': userObjectId,
        'recipe_id': recipeObjectId,
        'created_at': DateTime.now(),
      });
      await _recipes!.updateOne(
        where.id(recipeObjectId),
        modify.inc('likes', 1),
      );
    } else {
      // Remove like
      await _userLikes!.deleteOne(
          where.eq('user_id', userObjectId).eq('recipe_id', recipeObjectId));
      await _recipes!.updateOne(
        where.id(recipeObjectId),
        modify.inc('likes', -1),
      );
    }
  }
}
