import 'package:encrypt/encrypt.dart';
import 'dart:core';

var keyString = '969d9c9717ce3a416646eef722c191b2';
final key = Key.fromUtf8(keyString); //32 chars
final iv = IV.fromUtf8(keyString.substring(0,16)); //16 chars

//encrypt
String encryptMyData(String text) {
  final e = Encrypter(AES(key, mode: AESMode.cbc));
  final encryptedData = e.encrypt(text, iv: iv);
  return encryptedData.base64;
}

//dycrypt
String decryptMyData(String text) {
  final e = Encrypter(AES(key, mode: AESMode.cbc));
  final decryptedData = e.decrypt(Encrypted.fromBase64(text), iv: iv);
  return decryptedData;
}