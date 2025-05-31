class Recipe {
  final String? id;
  final String title;
  final String description;
  final String imageUrl;
  final String chefId;
  final String chefName;
  final String? chefImageUrl;
  final int cookingTimeMinutes;
  final List<String> ingredients;
  final List<String> instructions;
  final double rating;
  final int reviews;
  final List<String> categories;
  final DateTime createdAt;
  final int likes;

  Recipe({
    this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.chefId,
    required this.chefName,
    this.chefImageUrl,
    required this.cookingTimeMinutes,
    required this.ingredients,
    required this.instructions,
    required this.rating,
    required this.reviews,
    required this.categories,
    required this.createdAt,
    required this.likes,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    try {
      return Recipe(
        id: map['_id']?.toHexString() ?? map['id'],
        title: map['title'] as String? ?? 'Untitled Recipe',
        description:
            map['description'] as String? ?? 'No description available',
        imageUrl:
            map['image_url'] as String? ?? 'https://via.placeholder.com/400',
        chefId: map['chef_id']?.toString() ?? '',
        chefName: map['chef_name'] as String? ?? 'Unknown Chef',
        chefImageUrl: map['chef_image_url'] as String?,
        cookingTimeMinutes: map['cooking_time_minutes'] as int? ?? 30,
        ingredients: List<String>.from(map['ingredients'] ?? []),
        instructions: List<String>.from(map['instructions'] ?? []),
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        reviews: map['reviews'] as int? ?? 0,
        categories: List<String>.from(map['categories'] ?? []),
        createdAt: map['created_at'] is DateTime
            ? map['created_at']
            : DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                DateTime.now(),
        likes: map['likes'] as int? ?? 0,
      );
    } catch (e, stackTrace) {
      print('Error creating Recipe from map: $e');
      print('Stack trace: $stackTrace');
      print('Problematic map: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'chef_id': chefId,
        'chef_name': chefName,
        'chef_image_url': chefImageUrl,
        'cooking_time_minutes': cookingTimeMinutes,
        'ingredients': ingredients,
        'instructions': instructions,
        'rating': rating,
        'reviews': reviews,
        'categories': categories,
        'created_at': createdAt.toIso8601String(),
        'likes': likes,
      };
    } catch (e, stackTrace) {
      print('Error converting Recipe to map: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? chefId,
    String? chefName,
    String? chefImageUrl,
    int? cookingTimeMinutes,
    List<String>? ingredients,
    List<String>? instructions,
    double? rating,
    int? reviews,
    List<String>? categories,
    DateTime? createdAt,
    int? likes,
  }) {
    try {
      return Recipe(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        chefId: chefId ?? this.chefId,
        chefName: chefName ?? this.chefName,
        chefImageUrl: chefImageUrl ?? this.chefImageUrl,
        cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
        ingredients: ingredients ?? this.ingredients,
        instructions: instructions ?? this.instructions,
        rating: rating ?? this.rating,
        reviews: reviews ?? this.reviews,
        categories: categories ?? this.categories,
        createdAt: createdAt ?? this.createdAt,
        likes: likes ?? this.likes,
      );
    } catch (e, stackTrace) {
      print('Error copying Recipe: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, chefName: $chefName)';
  }
}
