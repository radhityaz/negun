import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoService {
  // Key must be 32 bytes (256 bits)
  
  // Decrypt AES-GCM (compatible with Go implementation)
  static String decryptAES(String ciphertextB64, String ivHex, String keyStr) {
    final key = encrypt.Key.fromUtf8(keyStr); // In real app, key might be hex or derived
    final iv = encrypt.IV.fromBase16(ivHex);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypt.Encrypted.fromBase64(ciphertextB64);
    
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // Encrypt AES-GCM (compatible with Go implementation)
  static Map<String, String> encryptAES(String plaintext, String keyStr) {
    final key = encrypt.Key.fromUtf8(keyStr);
    final iv = encrypt.IV.fromSecureRandom(12); // GCM standard nonce
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    return {
      'ciphertext': encrypted.base64,
      'iv': iv.base16,
    };
  }

  // Compute HMAC-SHA256
  static String computeHMAC(String data, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(data);
    
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    
    return digest.toString(); // Hex string
  }
}
