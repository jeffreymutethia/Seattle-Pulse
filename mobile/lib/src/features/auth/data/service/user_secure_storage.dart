import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/models/user_model.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _userKey = "logged_in_user";
  static const _SHOW_HOME_KEY = 'show_home_location';

  static Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _userKey, value: user.toJson());
  }

  static Future<UserModel?> getUser() async {
    final jsonString = await _storage.read(key: _userKey);
    if (jsonString == null) return null;
    return UserModel.fromJsonString(jsonString);
  }

  static Future<void> clearUser() async {
    await _storage.delete(key: _userKey);
  }

   static Future<void> saveShowHomeLocation(bool show) {
    return _storage.write(key: _SHOW_HOME_KEY, value: show.toString());
  }

  static Future<bool> getShowHomeLocation() async {
    final v = await _storage.read(key: _SHOW_HOME_KEY);
    if (v == null) return true; // default to visible
    return v.toLowerCase() == 'true';
  }
}
