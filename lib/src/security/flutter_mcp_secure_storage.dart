import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manager for secure credential storage
class FlutterMcpSecureStorage {
  static final FlutterMcpSecureStorage _instance = FlutterMcpSecureStorage._();
  
  /// Get singleton instance
  static FlutterMcpSecureStorage get instance => _instance;
  
  /// Secure storage instance
  final _storage = const FlutterSecureStorage();
  
  /// Storage options
  final _options = const IOSOptions(
    accountName: 'flutter_mcp_secure_storage',
  );
  
  /// Prefix for MCP keys
  static const String _keyPrefix = 'flutter_mcp_';
  
  /// Key for stored auth token
  static const String _authTokenKey = '${_keyPrefix}auth_token';
  
  /// Private constructor
  FlutterMcpSecureStorage._();
  
  /// Write a string value securely
  Future<void> write(String key, String value) async {
    await _storage.write(
      key: _prefixKey(key),
      value: value,
      iOptions: _options,
    );
  }
  
  /// Read a string value securely
  Future<String?> read(String key) async {
    return await _storage.read(
      key: _prefixKey(key),
      iOptions: _options,
    );
  }
  
  /// Delete a value
  Future<void> delete(String key) async {
    await _storage.delete(
      key: _prefixKey(key),
      iOptions: _options,
    );
  }
  
  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(
      key: _prefixKey(key),
      iOptions: _options,
    );
  }
  
  /// Delete all values with the MCP prefix
  Future<void> deleteAll() async {
    final allKeys = await _storage.readAll(iOptions: _options);
    
    for (final key in allKeys.keys) {
      if (key.startsWith(_keyPrefix)) {
        await _storage.delete(key: key, iOptions: _options);
      }
    }
  }
  
  /// Store an authentication token
  Future<void> storeAuthToken(String token) async {
    await write(_authTokenKey, token);
  }
  
  /// Get the stored authentication token
  Future<String?> getAuthToken() async {
    return await read(_authTokenKey);
  }
  
  /// Delete the stored authentication token
  Future<void> deleteAuthToken() async {
    await delete(_authTokenKey);
  }
  
  /// Simple encryption for non-critical data
  ///
  /// Note: This is not a secure encryption method for truly sensitive data.
  /// It provides basic obfuscation only.
  Future<String> encrypt(String data) async {
    final random = Random.secure();
    final key = List<int>.generate(16, (_) => random.nextInt(256));
    final iv = List<int>.generate(16, (_) => random.nextInt(256));
    
    // Store the key and IV
    final keyString = base64.encode(key);
    final ivString = base64.encode(iv);
    
    await write('${_keyPrefix}encryption_key', keyString);
    await write('${_keyPrefix}encryption_iv', ivString);
    
    // Very basic XOR-based encryption for demonstration
    // Not suitable for real security needs
    final bytes = utf8.encode(data);
    final encrypted = List<int>.filled(bytes.length, 0);
    
    for (var i = 0; i < bytes.length; i++) {
      encrypted[i] = bytes[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    
    return base64.encode(encrypted);
  }
  
  /// Simple decryption for non-critical data
  ///
  /// Note: This is not a secure decryption method for truly sensitive data.
  /// It provides basic deobfuscation only.
  Future<String> decrypt(String encryptedData) async {
    final keyString = await read('${_keyPrefix}encryption_key');
    final ivString = await read('${_keyPrefix}encryption_iv');
    
    if (keyString == null || ivString == null) {
      throw Exception('Encryption key or IV not found');
    }
    
    final key = base64.decode(keyString);
    final iv = base64.decode(ivString);
    
    // Decode the base64 encrypted data
    final encrypted = base64.decode(encryptedData);
    final decrypted = List<int>.filled(encrypted.length, 0);
    
    // Perform XOR decryption
    for (var i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    
    return utf8.decode(decrypted);
  }
  
  /// Add prefix to key for namespace isolation
  String _prefixKey(String key) {
    if (key.startsWith(_keyPrefix)) {
      return key;
    }
    return '$_keyPrefix$key';
  }
}
