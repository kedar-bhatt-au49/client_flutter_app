import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

/// Uploads files (payment documents, installation photos) to Supabase Storage
/// and returns a public URL to store in Firestore.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get available => _client != null;

  /// Uploads [bytes] under [folder]/<timestamp>_[name] and returns the public URL.
  Future<String> uploadBytes(
    Uint8List bytes,
    String name, {
    String folder = 'misc',
    String contentType = 'image/jpeg',
  }) async {
    final c = _client;
    if (c == null) throw Exception('Storage is not available.');
    final path =
        '$folder/${DateTime.now().millisecondsSinceEpoch}_${_sanitize(name)}';
    await c.storage.from(SupabaseConfig.bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return c.storage.from(SupabaseConfig.bucket).getPublicUrl(path);
  }

  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
}
