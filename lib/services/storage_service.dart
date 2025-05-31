import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class StorageService {
  final Db _db;

  StorageService(this._db);

  Future<String> uploadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<int>> getImage(String id) async {
    try {
      final bucket = GridFS(_db);
      final fileId = ObjectId.fromHexString(id);

      // Get the file chunks
      final chunk = await bucket.chunks.findOne(where.eq('files_id', fileId));

      if (chunk == null) {
        throw Exception('Image not found');
      }

      return chunk['data'] as List<int>;
    } catch (e) {
      throw Exception('Failed to get image: $e');
    }
  }
}
