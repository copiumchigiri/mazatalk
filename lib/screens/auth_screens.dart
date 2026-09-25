import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/application/auth_controller.dart';

// --- Shared Components ---

class LogoPlaceholder extends StatelessWidget {
  const LogoPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryLight, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
    );
  }
}

class DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WireframeButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const WireframeButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isPrimary
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: AppColors.cardShadow,
              ),
              onPressed: onPressed,
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: AppColors.primaryLight,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
    );
  }
}

/// Called once a one-tap auth method (Google/Facebook/OTP) has succeeded.
/// Creates-or-signs-in the passwordless account, then routes new sign-ups
/// into child creation and returning users to child selection.
Future<void> _completeLogin(
  BuildContext context,
  WidgetRef ref, {
  required bool isSignUp,
  required String accountId,
}) async {
  await ref
      .read(authControllerProvider.notifier)
      .signInWithProvider(accountId: accountId);
  if (!context.mounted) return;
  context.go(isSignUp ? '/child/new' : '/select-child');
}

// --- Screens ---

/// Method picker shown for both "Log In" and "Sign Up" — only Email collects
/// a password; Google, Facebook and Phone are one-tap / OTP based.
class AuthMethodScreen extends ConsumerWidget {
  final bool isSignUp;
  const AuthMethodScreen({super.key, required this.isSignUp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isSignUp ? "Бүртгүүлэх" : "Нэвтрэх";
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        automaticallyImplyLeading: context.canPop(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoPlaceholder(),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            WireframeButton(
              text: isSignUp ? "Google-ээр бүртгүүлэх" : "Google-ээр нэвтрэх",
              onPressed: () => _completeLogin(
                context,
                ref,
                isSignUp: isSignUp,
                accountId: 'google-demo-user',
              ),
            ),
            const SizedBox(height: 12),
            WireframeButton(
              text: isSignUp
                  ? "Facebook-ээр бүртгүүлэх"
                  : "Facebook-ээр нэвтрэх",
              onPressed: () => _completeLogin(
                context,
                ref,
                isSignUp: isSignUp,
                accountId: 'facebook-demo-user',
              ),
            ),
            const SizedBox(height: 12),
            WireframeButton(
              text: isSignUp
                  ? "Утасны дугаараар бүртгүүлэх"
                  : "Утасны дугаараар нэвтрэх",
              onPressed: () =>
                  context.push('/${isSignUp ? "signup" : "login"}/phone'),
            ),
            const SizedBox(height: 12),
            WireframeButton(
              text: isSignUp ? "И-мэйлээр бүртгүүлэх" : "И-мэйлээр нэвтрэх",
              onPressed: () =>
                  context.push('/${isSignUp ? "signup" : "login"}/email'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => isSignUp
                  ? (context.canPop() ? context.pop() : context.go('/login'))
                  : context.push('/signup'),
              child: Text(
                isSignUp ? "Бүртгэлтэй юу? Нэвтрэх" : "Шинэ бүртгэл үүсгэх",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailAuthScreen extends ConsumerStatefulWidget {
  final bool isSignUp;
  const EmailAuthScreen({super.key, required this.isSignUp});
  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = widget.isSignUp;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LogoPlaceholder(),
            const SizedBox(height: 12),
            Text(
              isSignUp ? "И-мэйлээр бүртгүүлэх" : "И-мэйлээр нэвтрэх",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "И-мэйл"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Нууц үг"),
            ),
            if (isSignUp) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Нууц үгээ давтах",
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            WireframeButton(
              text: isSignUp ? "Бүртгүүлэх" : "Дараах",
              isPrimary: true,
              onPressed: _submitting
                  ? () {}
                  : () => isSignUp ? _submitSignUp() : _submitLogin(),
            ),
            if (!isSignUp)
              TextButton(
                onPressed: () => context.push('/reset-password'),
                child: const Text(
                  "Нууц үгээ мартсан уу? Сэргээх.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => isSignUp
                  ? (context.canPop() ? context.pop() : context.go('/login'))
                  : context.push('/signup'),
              child: Text(
                isSignUp ? "Бүртгэлтэй юу? Нэвтрэх" : "Шинэ бүртгэл үүсгэх",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Бүх талбарыг бөглөнө үү.");
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: password);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      context.go('/select-child');
    } else {
      setState(() => _error = error);
    }
  }

  Future<void> _submitSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = "Бүх талбарыг бөглөнө үү.");
      return;
    }
    if (password != confirmPassword) {
      setState(() => _error = "Нууц үг таарахгүй байна.");
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    // Actually creates the account (v2 silently discarded the credentials
    // here) — email format/duplicate/password-length errors come back from
    // the repository as user-facing messages.
    final error = await ref
        .read(authControllerProvider.notifier)
        .signUp(email: email, password: password);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      context.go('/child/new');
    } else {
      setState(() => _error = error);
    }
  }
}

class PhoneAuthScreen extends StatefulWidget {
  final bool isSignUp;
  const PhoneAuthScreen({super.key, required this.isSignUp});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendCode() {
    final phone = _phoneController.text.trim();
    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      setState(() => _error = "Утасны дугаараа зөв оруулна уу.");
      return;
    }
    setState(() => _error = null);
    context.push(
      '/verify?signup=${widget.isSignUp}&phone=${Uri.encodeComponent(phone)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = widget.isSignUp;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LogoPlaceholder(),
            const SizedBox(height: 12),
            Text(
              isSignUp
                  ? "Утасны дугаараар бүртгүүлэх"
                  : "Утасны дугаараар нэвтрэх",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(height: 40),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Утасны дугаар"),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            WireframeButton(
              text: "Код илгээх",
              isPrimary: true,
              onPressed: _sendCode,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => isSignUp
                  ? (context.canPop() ? context.pop() : context.go('/login'))
                  : context.push('/signup'),
              child: Text(
                isSignUp ? "Бүртгэлтэй юу? Нэвтрэх" : "Шинэ бүртгэл үүсгэх",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationCodeScreen extends ConsumerWidget {
  final bool isSignUp;
  final String phone;
  const VerificationCodeScreen({
    super.key,
    this.isSignUp = false,
    this.phone = '',
  });

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Код буруу байна"),
        content: const Text(
          "Нэг удаагийн код буруу байна. Дахин оролдох эсвэл шинэ код авна уу.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Дахин оролдох"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Шинэ код"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LogoPlaceholder(),
            const SizedBox(height: 20),
            const Text(
              "Код илгээгдлээ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 44,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(counterText: ""),
                    maxLength: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            WireframeButton(
              text: "Үргэлжлүүлэх",
              isPrimary: true,
              // Demo OTP: any code passes; the phone number is the account key.
              onPressed: () => _completeLogin(
                context,
                ref,
                isSignUp: isSignUp,
                accountId: 'phone-${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
              ),
            ),
            TextButton(
              onPressed: () => _showErrorDialog(context),
              child: const Text(
                "Баталгаажуулах кодыг дахин илгээх",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  // Local-backend reset: verify the email exists, then set a new password
  // directly. When Firebase lands this becomes the send-reset-email flow.
  bool _emailVerified = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    final exists = await ref
        .read(authControllerProvider.notifier)
        .accountExists(email);
    if (!mounted) return;
    if (!exists) {
      setState(() => _error = "Энэ и-мэйлээр бүртгэл олдсонгүй.");
      return;
    }
    setState(() {
      _error = null;
      _emailVerified = true;
    });
  }

  Future<void> _setNewPassword() async {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(() => _error = "Нууц үг хамгийн багадаа 6 тэмдэгттэй байна.");
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = "Нууц үг таарахгүй байна.");
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          email: _emailController.text.trim(),
          newPassword: password,
        );
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = "Энэ и-мэйлээр бүртгэл олдсонгүй.");
      return;
    }
    context.push('/success?title=Нууц үг амжилттай сэргээгдлээ&type=password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const LogoPlaceholder(),
            const SizedBox(height: 20),
            const Text(
              "Нууц үг сэргээх",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              enabled: !_emailVerified,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "И-мэйл"),
            ),
            if (_emailVerified) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Шинэ нууц үг"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Шинэ нууц үгээ давтах",
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            WireframeButton(
              text: _emailVerified ? "Шинэ нууц үг тохируулах" : "Үргэлжлүүлэх",
              isPrimary: true,
              onPressed: () =>
                  _emailVerified ? _setNewPassword() : _checkEmail(),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  final String title;
  final bool isPasswordReset;
  const SuccessScreen({
    super.key,
    required this.title,
    this.isPasswordReset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoPlaceholder(),
            const SizedBox(height: 40),
            const Icon(
              Icons.check_circle_rounded,
              size: 68,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            WireframeButton(
              text: "Нэвтрэх",
              isPrimary: true,
              onPressed: () => context.go('/login'),
            ),
            const SizedBox(height: 12),
            WireframeButton(
              text: "Бүртгүүлэх",
              onPressed: () => context.push('/signup'),
            ),
          ],
        ),
      ),
    );
  }
}
