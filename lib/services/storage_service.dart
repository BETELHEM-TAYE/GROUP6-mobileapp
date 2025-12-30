import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

// Get the global Supabase client
final supabase = Supabase.instance.client;

class StorageService {
  /// Upload property image to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadPropertyImage({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    try {
      final String filePath = '$userId/$fileName';

      await supabase.storage
          .from('property_images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: _getContentType(p.extension(fileName)),
            ),
          );

      final String publicUrl =
          supabase.storage.from('property_images').getPublicUrl(filePath);

      debugPrint("Property image uploaded successfully: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading property image: $e");
      rethrow;
    }
  }

  /// Upload chat attachment to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadChatAttachment({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    try {
      final String filePath = '$userId/$fileName';

      await supabase.storage
          .from('chat_attachments')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: _getContentType(p.extension(fileName)),
            ),
          );

      final String publicUrl =
          supabase.storage.from('chat_attachments').getPublicUrl(filePath);

      debugPrint("Chat attachment uploaded successfully: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading chat attachment: $e");
      rethrow;
    }
  }

  /// Delete image from storage
  Future<void> deleteImage({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await supabase.storage.from(bucket).remove([filePath]);
      debugPrint("Image deleted successfully from $bucket: $filePath");
    } catch (e) {
      debugPrint("Error deleting image: $e");
      rethrow;
    }
  }

  /// Helper method to get the correct MIME type based on file extension
  String _getContentType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

