import 'package:encrypt/encrypt.dart';

class Encrypt {

  final plainText;
  final key = Key.fromUtf8('my 32 length key................');
  final iv = IV.fromLength(16);

  Encrypt({this.plainText});

    String encryption() {
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    String res=encrypted.base64;
    return res;
  }

    String decryption(dynamic encrypted) {
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }

}
