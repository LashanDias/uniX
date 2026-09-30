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
    for (final field in ['id', 'ownerId', 'title', 'company', 'text']) {
      if (requirement[field] is! String ||
          (requirement[field] as String).trim().isEmpty) {
        throw StateError('Missing $field.');
      }
    }
    if ((requirement['title'] as String).length > 150 ||
        (requirement['company'] as String).length > 150 ||
        (requirement['text'] as String).length > 100000) {
      throw StateError('Requirements exceed the allowed length.');
    }
    final entries = await requirements();
    if (entries.any(
      (entry) =>
          entry['id'] == requirement['id'] &&
          entry['ownerId'] != requirement['ownerId'],
    )) {
      throw StateError('Only the author can edit these requirements.');
    }
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
