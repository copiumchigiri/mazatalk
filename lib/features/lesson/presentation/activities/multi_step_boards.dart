import 'dart:async';
import 'package:flutter/material.dart';
import '../../../curriculum/domain/activity.dart';

/// Multi-step boards share one contract: per-tap evaluation — a correct tap
/// locks in green, a wrong tap flashes red and the child simply tries again
/// — then `onFinished(clean)` once the board is solved, where `clean` means
/// no wrong taps (the player requeues the activity otherwise).

const _flashDuration = Duration(milliseconds: 450);

Color _tileColor(bool locked, bool flashing) {
  if (locked) return Colors.green.shade200;
  if (flashing) return Colors.red.shade200;
  return Colors.white;
}

Color _tileBorder(bool locked, bool flashing, {bool selected = false}) {
  if (locked) return Colors.green.shade700;
  if (flashing) return Colors.red.shade700;
  if (selected) return Colors.black;
  return Colors.black;
}

Widget _boardTile({
  required String text,
  required VoidCallback onTap,
  bool locked = false,
  bool flashing = false,
  bool selected = false,
  double fontSize = 22,
}) {
  return Material(
    color: selected && !locked && !flashing
        ? Colors.grey.shade300
        : _tileColor(locked, flashing),
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: _tileBorder(locked, flashing, selected: selected),
        width: selected ? 3 : 2,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

/// Tap a left tile, then its match on the right; matched pairs lock green.
class MatchPairsBoard extends StatefulWidget {
  final Activity activity;
  final void Function(bool clean) onFinished;

  const MatchPairsBoard({
    super.key,
    required this.activity,
    required this.onFinished,
  });

  @override
  State<MatchPairsBoard> createState() => _MatchPairsBoardState();
}

class _MatchPairsBoardState extends State<MatchPairsBoard> {
  int? _selectedLeft;
  final Set<int> _matchedLeft = {};
  final Set<int> _matchedRight = {};
  int? _flashRight;
  bool _hadMistake = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _tapLeft(int index) {
    if (_matchedLeft.contains(index)) return;
    setState(() => _selectedLeft = index);
  }

  void _tapRight(int index) {
    final left = _selectedLeft;
    if (_matchedRight.contains(index) || left == null) return;
    if (widget.activity.correctOrder[left] == index) {
      setState(() {
        _matchedLeft.add(left);
        _matchedRight.add(index);
        _selectedLeft = null;
      });
      if (_matchedLeft.length == widget.activity.choices.length) {
        widget.onFinished(!_hadMistake);
      }
    } else {
      _hadMistake = true;
      setState(() => _flashRight = index);
      _flashTimer = Timer(_flashDuration, () {
        if (mounted) setState(() => _flashRight = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < activity.choices.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: _boardTile(
                      text: activity.choices[i],
                      locked: _matchedLeft.contains(i),
                      selected: _selectedLeft == i,
                      onTap: () => _tapLeft(i),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < activity.rightColumn.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: _boardTile(
                      text: activity.rightColumn[i],
                      locked: _matchedRight.contains(i),
                      flashing: _flashRight == i,
                      onTap: () => _tapRight(i),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Single gap, letter tiles; wrong letters flash red and stay tappable.
class FillBlankBoard extends StatefulWidget {
  final Activity activity;
  final void Function(bool clean) onFinished;

  const FillBlankBoard({
    super.key,
    required this.activity,
    required this.onFinished,
  });

  @override
  State<FillBlankBoard> createState() => _FillBlankBoardState();
}

class _FillBlankBoardState extends State<FillBlankBoard> {
  bool _solved = false;
  int? _flash;
  bool _hadMistake = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _tap(int index) {
    if (_solved) return;
    if (index == widget.activity.correctIndex) {
      setState(() => _solved = true);
      widget.onFinished(!_hadMistake);
    } else {
      _hadMistake = true;
      setState(() => _flash = index);
      _flashTimer = Timer(_flashDuration, () {
        if (mounted) setState(() => _flash = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < activity.choices.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _boardTile(
                    text: activity.choices[i],
                    locked: _solved && i == activity.correctIndex,
                    flashing: _flash == i,
                    fontSize: 32,
                    onTap: () => _tap(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Tap tiles in the right order; each correct tap locks in with its number.
class SequenceBoard extends StatefulWidget {
  final Activity activity;
  final void Function(bool clean) onFinished;

  const SequenceBoard({
    super.key,
    required this.activity,
    required this.onFinished,
  });

  @override
  State<SequenceBoard> createState() => _SequenceBoardState();
}

class _SequenceBoardState extends State<SequenceBoard> {
  int _nextPosition = 0;
  final Map<int, int> _lockedOrder = {}; // choice index → 1-based order
  int? _flash;
  bool _hadMistake = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _tap(int index) {
    if (_lockedOrder.containsKey(index)) return;
    if (widget.activity.correctOrder[_nextPosition] == index) {
      setState(() {
        _lockedOrder[index] = _nextPosition + 1;
        _nextPosition++;
      });
      if (_nextPosition == widget.activity.correctOrder.length) {
        widget.onFinished(!_hadMistake);
      }
    } else {
      _hadMistake = true;
      setState(() => _flash = index);
      _flashTimer = Timer(_flashDuration, () {
        if (mounted) setState(() => _flash = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 120,
          child: Row(
            children: [
              for (var i = 0; i < activity.choices.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 18,
                        child: Text(
                          _lockedOrder.containsKey(i)
                              ? '${_lockedOrder[i]}'
                              : '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: _boardTile(
                            text: activity.choices[i],
                            locked: _lockedOrder.containsKey(i),
                            flashing: _flash == i,
                            fontSize: 26,
                            onTap: () => _tap(i),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
