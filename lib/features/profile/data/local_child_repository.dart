import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/child_profile.dart';
import 'child_repository.dart';

/// Persists child profiles locally, **scoped to one parent account** so two
/// logins on the same device never see each other's children. A null
/// [accountId] (signed out) reads empty and writes nowhere.
class LocalChildRepository implements ChildRepository {
  final String? accountId;

  const LocalChildRepository({this.accountId});

  String get _prefsKey => 'mazatalk_children_v3_$accountId';

  @override
  Future<List<ChildProfile>> loadChildren() async {
    if (accountId == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final data = jsonDecode(raw) as List;
    return data
        .map((e) => ChildProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveChildren(List<ChildProfile> children) async {
    if (accountId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(children.map((c) => c.toJson()).toList()),
    );
  }
}
