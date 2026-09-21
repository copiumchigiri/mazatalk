import 'dart:async';
import 'package:flutter/widgets.dart';

/// Shared "every level always completes" timer (PROJECT_V4.md §5 rule #3).
/// Mix into a level's `State`, call [startLevelTimeout] once (from
/// `initState`) with the level's timeout window and what to do if nothing
/// happens, and call [cancelLevelTimeout] the moment the child answers for
/// real so the timeout never fires after the fact.
mixin PlaygroundLevelTimeoutMixin<T extends StatefulWidget> on State<T> {
  Timer? _timeoutTimer;

  void startLevelTimeout(Duration duration, VoidCallback onTimeout) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(duration, () {
      if (!mounted) return;
      onTimeout();
    });
  }

  void cancelLevelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
