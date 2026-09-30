import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecruitmentStore {
  Future<Map<String, dynamic>> loadCv(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString('recruitment.cv.$accountId'));
  }

  Future<void> saveCv(String accountId, String name, String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      'recruitment.cv.$accountId',
      jsonEncode({'name': name, 'text': text}),
    )) {
      throw StateError('Could not save your CV.');
    }
  }

  Future<void> removeCv(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove('recruitment.cv.$accountId')) {
      throw StateError('Could not remove the saved CV.');
    }
  }

  Future<List<Map<String, dynamic>>> requirements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recruitment.requirements.v1');
    return raw == null
        ? []
        : (jsonDecode(raw) as List)
              .map((value) => Map<String, dynamic>.from(value as Map))
              .toList();
  }

  Future<void> saveRequirements(Map<String, dynamic> requirement) async {
    final entries = await requirements();
    entries.removeWhere((entry) => entry['id'] == requirement['id']);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      'recruitment.requirements.v1',
      jsonEncode([requirement, ...entries]),
    )) {
      throw StateError('Could not save the requirements.');
    }
  }

  Map<String, dynamic> _decode(String? raw) =>
      raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
}
