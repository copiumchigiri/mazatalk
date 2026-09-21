import 'dart:math';
import 'package:flutter/material.dart';

/// DuoABC-style parent gate: "Tap 7 then 3" on a number pad. Keeps kids out
/// of parent-facing screens without a password. Returns true if passed.
Future<bool> showParentGate(BuildContext context) async {
  final rng = Random();
  final first = 1 + rng.nextInt(9);
  var second = 1 + rng.nextInt(9);
  if (second == first) second = second % 9 + 1;
  final passed = await showDialog<bool>(
    context: context,
    builder: (context) => _ParentGateDialog(first: first, second: second),
  );
  return passed ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  final int first;
  final int second;
  const _ParentGateDialog({required this.first, required this.second});

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  bool _firstTapped = false;
  bool _showError = false;

  void _tap(int number) {
    if (!_firstTapped) {
      if (number == widget.first) {
        setState(() {
          _firstTapped = true;
          _showError = false;
        });
      } else {
        setState(() => _showError = true);
      }
      return;
    }
    if (number == widget.second) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _firstTapped = false;
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('For grown-ups!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tap ${widget.first} then ${widget.second}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (_showError)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Try again',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          for (var row = 0; row < 3; row++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var col = 0; col < 3; col++)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: SizedBox(
                      width: 56,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                        ),
                        onPressed: () => _tap(row * 3 + col + 1),
                        child: Text('${row * 3 + col + 1}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
