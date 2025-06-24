import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'governate_repository_interface.dart';

class GovernateRepository implements GovernateRepositoryInterface {
  final SharedPreferences sharedPreferences;

  GovernateRepository({required this.sharedPreferences});

  static const String _key = 'selected_governate';

  @override
  Future<void> saveGovernate(dynamic id) async {
    await sharedPreferences.setString(_key, jsonEncode([id]));
  }


  @override
  String? getGovernate() {
    return sharedPreferences.getString(_key);
  }
}
