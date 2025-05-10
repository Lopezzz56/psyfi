import 'package:encrypt/encrypt.dart' as encrypt;

class MessageCryptoHelper {
  // WARNING: In production, don't hardcode keys! Use secure storage!
  static final _key = encrypt.Key.fromUtf8('16charslongkey!!'); // 16/24/32 chars
  static final _iv = encrypt.IV.fromUtf8('8bytesiv12345678');   // 16 chars

  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  static String encryptText(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  static String decryptText(String encryptedText) {
    return _encrypter.decrypt64(encryptedText, iv: _iv);
  }
}
