import 'package:flutter/material.dart';
// import 'package:mysql1/mysql1.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? imageUrl;
  final bool isVerified;
  final String? bio;
  final int recipeCount;
  final int videoCount;
  final int followerCount;
  final int followingCount;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.imageUrl,
    this.isVerified = false,
    this.bio,
    this.recipeCount = 0,
    this.videoCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['_id'] is ObjectId
          ? map['_id'].toHexString()
          : map['_id'].toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      imageUrl: map['image_url'],
      isVerified: map['is_verified'] ?? false,
      bio: map['bio'],
      recipeCount: map['recipe_count'] ?? 0,
      videoCount: map['video_count'] ?? 0,
      followerCount: map['follower_count'] ?? 0,
      followingCount: map['following_count'] ?? 0,
    );
  }
}

class AuthProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  late final StorageService _storage;
  AuthUser? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      print('Initializing database connection...');
      try {
        if (!_db.isConnected) {
          await _db.connect();
        }
        _storage = StorageService(_db.database!);
        _isInitialized = true;
        print('Database connection initialized successfully');
      } catch (e) {
        print('Error initializing database connection: $e');
        _isInitialized = false;
        throw Exception('Failed to initialize database connection: $e');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _ensureInitialized();
      final hashedPassword = _hashPassword(password);
      final users = _db.users;

      print('Checking database connection...');
      if (users == null) {
        _error = 'Database not initialized';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('Looking up user with email: $email');
      final userDoc = await users.findOne(
          where.eq('email', email).eq('password_hash', hashedPassword));

      if (userDoc == null) {
        _error = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('User found, creating AuthUser instance');
      _user = AuthUser.fromMap(userDoc);

      print('Updating last login timestamp');
      await users.updateOne(
        where.eq('_id', ObjectId.fromHexString(_user!.id)),
        {
          '\$set': {'updated_at': DateTime.now()}
        },
      );

      _isLoading = false;
      notifyListeners();
      print('Login successful');
      return true;
    } catch (e, stackTrace) {
      print('Error during login: $e');
      print('Stack trace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _ensureInitialized();
      final hashedPassword = _hashPassword(password);
      final users = _db.users;

      print('Checking database connection...');
      if (users == null) {
        _error = 'Database not initialized';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('Checking for existing user with email: $email');
      final existingUser = await users.findOne(where.eq('email', email));

      if (existingUser != null) {
        _error = 'Email already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('Creating new user document');
      final ObjectId userId = ObjectId();
      final result = await users.insertOne({
        '_id': userId,
        'email': email,
        'password_hash': hashedPassword,
        'name': name,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      });

      if (result.isSuccess) {
        print('User created successfully, creating AuthUser instance');
        _user = AuthUser(
          id: userId.toHexString(),
          email: email,
          name: name,
        );

        _isLoading = false;
        notifyListeners();
        print('Registration successful');
        return true;
      }

      _error = 'Failed to create user';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('Error during registration: $e');
      print('Stack trace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    print('Logging out user');
    _user = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      // In a real application, you would:
      // 1. Generate a password reset token
      // 2. Save it to the database with an expiration
      // 3. Send an email to the user with a reset link
      // For now, we'll just throw an error
      throw UnimplementedError('Password reset not implemented');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    if (_user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _ensureInitialized();
      final users = _db.users;

      if (users == null) {
        throw Exception('Database not initialized');
      }

      ObjectId userId;
      try {
        userId = ObjectId.fromHexString(_user!.id);
      } catch (e) {
        throw Exception('Invalid user ID format');
      }

      final userDoc = await users.findOne(where.eq('_id', userId));
      if (userDoc != null) {
        _user = AuthUser.fromMap(userDoc);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to refresh user: $_error');
    }
  }

  Future<void> updateProfile({
    required String name,
    String? bio,
    String? phoneNumber,
    File? imageFile,
  }) async {
    if (_user == null) throw Exception('User not authenticated');

    try {
      _isLoading = true;
      notifyListeners();

      await _ensureInitialized();
      final users = _db.users;

      if (users == null) {
        throw Exception('Database not initialized');
      }

      final updateData = {
        'name': name,
        'bio': bio,
        'phone_number': phoneNumber,
        'updated_at': DateTime.now(),
      };

      if (imageFile != null) {
        // Upload the image and get the URL
        final imageUrl = await _storage.uploadImage(imageFile);
        updateData['image_url'] = imageUrl;
      }

      // Remove null values from updateData
      updateData.removeWhere((key, value) => value == null);

      ObjectId userId;
      try {
        userId = ObjectId.fromHexString(_user!.id);
      } catch (e) {
        throw Exception('Invalid user ID format');
      }

      final result = await users.updateOne(
        where.eq('_id', userId),
        {'\$set': updateData},
      );

      if (!result.isSuccess) {
        throw Exception('Failed to update profile');
      }

      // Refresh user data after update
      await refreshUser();
    } catch (e) {
      _error = e.toString();
      throw Exception('Failed to update profile: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to set loading state and notify listeners
  void setState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
