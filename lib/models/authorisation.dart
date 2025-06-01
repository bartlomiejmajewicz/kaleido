import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:script_editor/authKeys/keys.dart';
import 'package:convert/convert.dart';
import 'package:script_editor/models/unique_device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseDetails{
  DateTime licenseStart;
  DateTime licenseEnd;
  String deviceId;
  String email;
  String licenseId;

  LicenseDetails(this.licenseStart, this.licenseEnd, this.deviceId, this.email, this.licenseId);

  @override
  String toString() {
    return "$licenseStart - $licenseEnd - $deviceId - $email - $licenseId";
  }
}
/// Use await initialize() before using the class
class Authorisation {

  /// Use await initialize() before using the class
  static Future<void> initialize() async {
    final sharedPreferences = await SharedPreferences.getInstance();

    String? sharedPreferencesLicenseData = sharedPreferences.getString("licenseData");
    if (sharedPreferencesLicenseData != null) {
      _licenseEncryptedData = sharedPreferencesLicenseData;
    }
    String? sharedPreferencesLicenseIv = sharedPreferences.getString("licenseIv");
    if (sharedPreferencesLicenseIv != null) {
      _licenseEncryptedIv = sharedPreferencesLicenseIv;
    }
    String? sharedPreferencesLicenseEmail = sharedPreferences.getString("licenseEmail");
    if (sharedPreferencesLicenseEmail != null) {
      _licenseEmail = sharedPreferencesLicenseEmail;
    }
    String? sharedPreferencesLicenseId = sharedPreferences.getString("licenseId");
    if (sharedPreferencesLicenseId != null) {
      _licenseId = sharedPreferencesLicenseId;
    }

    _deviceId = await UniqueDeviceId.getDeviceUuid();
  }

/// returns true if the license is active right now
  static bool isLicenseActive() {
    LicenseDetails? license = extractLicenseDetails();
    DateTime current = DateTime.now();
    if (license == null) {
      return false;
    }

    if (license.licenseStart.isBefore(current) && license.licenseEnd.isAfter(current) && license.deviceId == _deviceId) {
      return true;
    }

    return false;
  }
/// returns true if the license is present on the device
/// doesn't matter if active
  static bool isLicensePresent() {
    LicenseDetails? license = extractLicenseDetails();
    if (license == null) {
      return false;
    }

    if (license.deviceId == _deviceId) {
      return true;
    }

    return false;
  }

  static String licenseStatusText(){
    LicenseDetails? license = extractLicenseDetails();
    DateTime current = DateTime.now();
    String message = "No license";

    if (license == null) {
      String message = "No license";
      return message;
    }

    if (license.licenseStart.isAfter(current)) {
      message = "The current license is not active yet";
      return message;
    }

    if (license.licenseEnd.isBefore(current)) {
      message = "The current license has expired";  
      return message;    
    }

    message = "Your license is active";

    return message;
  }

  Authorisation._privateConstructor();

  static Authorisation? _instance;

  factory Authorisation(){
    return _instance ??= Authorisation._privateConstructor();
  }

  static String? _licenseEncryptedData;
  static String? _licenseEncryptedIv;
  static String? _licenseEmail;
  static String? _licenseId;
  static String? _deviceId;


/// clears all license data from the class.
/// use only for removing dummy or damaged licenses
  static void clearAllLicenseData(){
    _licenseEncryptedData = null;
    _licenseEncryptedIv = null;
    _licenseEmail = null;
    _licenseId = null;
    _deviceId = null;
  }

  static LicenseDetails? extractLicenseDetails(){
    if (_licenseEncryptedData == null || _licenseEncryptedIv == null || _licenseEmail == null || _licenseId == null) {
      return null;
    }
    return _extractLicenseDetailsFromData(_licenseEncryptedData!, _licenseEncryptedIv!, _licenseEmail!, _licenseId!);
  }

  static LicenseDetails? _extractLicenseDetailsFromData(String encData, String encIv, String email, String licenseId){
    LicenseDetails? license;
    try {
      String decryptedString = _decrypt(encData, encIv);
      List<String> splittedString = decryptedString.split("|");
      license = LicenseDetails(
        DateTime(int.parse(splittedString[0].split(".")[2]), int.parse(splittedString[0].split(".")[1]), int.parse(splittedString[0].split(".")[0])),
        DateTime(int.parse(splittedString[1].split(".")[2]), int.parse(splittedString[1].split(".")[1]), int.parse(splittedString[1].split(".")[0])),
        splittedString[2], email, licenseId
        );
    // ignore: empty_catches
    } catch (e) {
      
    }
    return license;
    
  }

  Future<String> pullLicenseFromServer(String email, String licenseId, String? deviceId) async {
    if (_licenseEncryptedData != null && _licenseEncryptedIv != null) {
      return "License is already present on the device";
    }
    return await _licenseServerOperations(email, licenseId, "pull", deviceId);
  }

  Future<String> pushLicenseToServer() async {
    if (_licenseEncryptedData == null || _licenseEncryptedIv == null) {
      return "There is no license on this device";
    }
    return await _licenseServerOperations(_licenseEmail!, _licenseId!, "push", await UniqueDeviceId.getDeviceUuid());
  }

  Future<String> destroyExpiredLicense() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.remove('licenseData');
    sharedPreferences.remove('licenseIv');
    sharedPreferences.remove('licenseEmail');
    sharedPreferences.remove('licenseId');
    return "The license has been succesfully removed from your device";
  }


  Future<String> _licenseServerOperations(String email, String licenseId, String operationType, String? deviceId) async {
    deviceId ??= await UniqueDeviceId.getDeviceUuid();

    // headers
    final headers = {
      'Content-Type': 'application/json',
    };

    // JSON license data
    final body = {
      'email': email,
      'licenseId': licenseId,
      "deviceId" : deviceId
    };

    try {
      final response = await http.patch(
        Uri.parse("$licenseApiUrl/$operationType"),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 202) {
        // Success
        if (operationType == "pull") {
          final responseData = jsonDecode(response.body);
          _licenseEncryptedIv = responseData['activationCode']['iv'];
          _licenseEncryptedData = responseData['activationCode']['encryptedData'];
          _licenseEmail = email;
          _licenseId = licenseId;
          SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
          sharedPreferences.setString('licenseData', _licenseEncryptedData!);
          sharedPreferences.setString('licenseIv', _licenseEncryptedIv!);
          sharedPreferences.setString('licenseEmail', _licenseEmail!);
          sharedPreferences.setString('licenseId', _licenseId!);
        }
        if (operationType == "push") {
          _licenseEncryptedIv = null;
          _licenseEncryptedData = null;
          _licenseEmail = null;
          _licenseId = null;
          SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
          sharedPreferences.remove('licenseData');
          sharedPreferences.remove('licenseIv');
          sharedPreferences.remove('licenseEmail');
          sharedPreferences.remove('licenseId');

        }
        return "The license operation success";
      } else {
        // Error
        return "An error has occured: ${response.body}";
      }
    } catch (e) {
      // Exceptions
      return "An error has occured: $e";
    }
  }



  static String _decrypt(String encryptedText, String ivBase64) {
    final key = encrypt.Key.fromUtf8(keyString);
    final iv = encrypt.IV.fromBase64(ivBase64);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);

    return encrypter.decrypt(encrypted, iv: iv);
  }




  static String _encryptText(String text, String secretKey) {
    var key = encrypt.Key.fromBase64(base64Encode(utf8.encode(secretKey)).padRight(32, '0').substring(0, 32));

    final iv = encrypt.IV.fromLength(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(text, iv: iv);

    return json.encode({
      'iv': hex.encode(iv.bytes),
      'encryptedData': encrypted.base64,
    });
  }


/// status code returned:
/// 0 == ok license activated
/// 1 == the license data is not correct
/// 2 == missing some data
  static Future<int> authoriseLocally(String email, String licenseId, String activationCodeEnc, String activationCodeIv) async {
    if (email.isEmpty || licenseId.isEmpty || activationCodeEnc.isEmpty || activationCodeIv.isEmpty) {
      return 2;
    }

    final LicenseDetails? license = _extractLicenseDetailsFromData(activationCodeEnc, activationCodeIv, email, licenseId);
    if (license == null) {
      return 1;
    }

    _licenseEncryptedIv = activationCodeIv;
    _licenseEncryptedData = activationCodeEnc;
    _licenseEmail = email;
    _licenseId = licenseId;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString('licenseData', _licenseEncryptedData!);
    sharedPreferences.setString('licenseIv', _licenseEncryptedIv!);
    sharedPreferences.setString('licenseEmail', _licenseEmail!);
    sharedPreferences.setString('licenseId', _licenseId!);

    return 0;
  }

}