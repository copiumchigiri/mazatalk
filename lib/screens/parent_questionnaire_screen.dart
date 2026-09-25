import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import 'onboarding_screens.dart';

class _Question {
  final String text;
  const _Question(this.text);
}

const _questions = [
  _Question(
    'Таны хүүхэд өөрийн мэдрэмж, хэрэгцээгээ хэр сайн '
    'илэрхийлдэг вэ?',
  ),
  _Question(
    'Үе тэнгийнхэнтэйгээ харьцуулахад хүүхэд тань хэр сайн '
    'харилцдаг вэ?',
  ),
  _Question(
    'Хүүхэд тань насныхаа хэмжээнд тохирсон үг хэллэг '
    'хэрэглэдэг үү?',
  ),
];

/// Asked right after the parent creates the child's profile, before the
/// phone is handed over (PROJECT context: "parent questions before
/// handoff"). Three 1–5 ratings, stored on [ChildProfile] and carried
/// through to the handoff/playground flow.
class ParentQuestionnaireScreen extends StatefulWidget {
  final String name;
  final int age;

  const ParentQuestionnaireScreen({
    super.key,
    required this.name,
    required this.age,
  });

  @override
  State<ParentQuestionnaireScreen> createState() =>
      _ParentQuestionnaireScreenState();
}

class _ParentQuestionnaireScreenState extends State<ParentQuestionnaireScreen> {
  final _answers = List<int?>.filled(_questions.length, null);

  bool get _allAnswered => _answers.every((a) => a != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.name}-ийн тухай хэдэн асуулт',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Утсыг хүүхдэдээ өгөхөөс өмнө эцэг эх бөглөнө үү.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < _questions.length; i++) ...[
                _RatingQuestion(
                  text: _questions[i].text,
                  value: _answers[i],
                  onChanged: (v) => setState(() => _answers[i] = v),
                ),
                const SizedBox(height: 28),
              ],
              OnboardingButton(
                text: 'Дараах',
                isPrimary: true,
                onPressed: _allAnswered ? _handleNext : () => _showError(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Бүх асуултад хариулна уу.')));
  }

  void _handleNext() {
    context.push(
      '/child/handoff',
      extra: {
        'name': widget.name,
        'age': widget.age,
        'parentExpressiveRating': _answers[0],
        'parentPeerCommunicationRating': _answers[1],
        'parentVocabularyRating': _answers[2],
      },
    );
  }
}

class _RatingQuestion extends StatelessWidget {
  final String text;
  final int? value;
  final ValueChanged<int> onChanged;

  const _RatingQuestion({
    required this.text,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 1; i <= 5; i++) ...[
              if (i > 1) const SizedBox(width: 8),
              Expanded(
                child: _RatingChip(
                  number: i,
                  selected: value == i,
                  onTap: () => onChanged(i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Text(
              'Бага',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
            Spacer(),
            Text(
              'Их',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  final int number;
  final bool selected;
  final VoidCallback onTap;

  const _RatingChip({
    required this.number,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.background.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
