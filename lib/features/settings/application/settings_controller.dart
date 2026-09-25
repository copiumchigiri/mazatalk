import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/application/auth_controller.dart';

class SettingsState {
  final bool soundOn;
  const SettingsState({this.soundOn = true});
}

/// Per-account app settings (currently just the sound/voice toggle).
class SettingsController extends Notifier<SettingsState> {
  String? _accountId;

  @override
  SettingsState build() {
    final accountId = ref.watch(
      authControllerProvider.select((s) => s.accountId),
    );
    _accountId = accountId;
    _load(accountId);
    return const SettingsState();
  }

  String _key(String accountId) => 'mazatalk_settings_v3_$accountId';

  Future<void> _load(String? accountId) async {
    if (accountId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final soundOn = prefs.getBool('${_key(accountId)}_soundOn') ?? true;
    if (_accountId != accountId) return;
    state = SettingsState(soundOn: soundOn);
  }

  Future<void> setSoundOn(bool value) async {
    state = SettingsState(soundOn: value);
    final accountId = _accountId;
    if (accountId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_key(accountId)}_soundOn', value);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
