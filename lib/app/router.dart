import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/companion/presentation/skin_select_screen.dart';
import '../features/lesson/presentation/lesson_player_screen.dart';
import '../features/path/presentation/path_screen.dart';
import '../features/placement/presentation/assessment_summary_screen.dart';
import '../features/placement/presentation/handoff_screen.dart';
import '../features/placement/presentation/playground_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/profile/application/child_controller.dart';
import '../features/curriculum/presentation/course_complete_screen.dart';
import '../screens/auth_screens.dart';
import '../screens/child_select_screen.dart';
import '../screens/onboarding_screens.dart';
import '../screens/parent_dashboard.dart';
import '../screens/parent_questionnaire_screen.dart';

const _authFlowPaths = {
  '/',
  '/login',
  '/login/email',
  '/login/phone',
  '/signup',
  '/signup/email',
  '/signup/phone',
  '/verify',
  '/reset-password',
  '/success',
};

const _childSetupPaths = {
  '/select-child',
  '/child/new',
  '/child/questionnaire',
  '/child/handoff',
  '/playground',
};

/// Bridges Riverpod state changes into the [Listenable] go_router expects
/// for its `refreshListenable` redirect-recheck hook.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (prev, next) => notifyListeners());
    ref.listen(childControllerProvider, (prev, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final childSession = ref.read(childControllerProvider);
      final path = state.matchedLocation;
      final isAuthFlow = _authFlowPaths.contains(path);
      final isChildSetup = _childSetupPaths.contains(path);

      // Hold on the splash screen until both the persisted session and the
      // account's children are loaded, so launch never flashes the wrong
      // screen and resume can route in one hop.
      final isBooting =
          auth.isRestoring || (auth.isLoggedIn && childSession.isLoading);
      if (isBooting) return path == '/splash' ? null : '/splash';

      if (!auth.isLoggedIn) {
        return isAuthFlow ? null : '/';
      }
      // Signed-in users never see the auth flow: land on the path screen,
      // auto-scrolled to the current lesson (resume is one tap on START).
      if (isAuthFlow || path == '/splash') {
        return childSession.selectedChildId != null
            ? '/assessment-summary'
            : '/select-child';
      }
      if (childSession.selectedChildId == null && !isChildSetup) {
        return '/select-child';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthMethodScreen(isSignUp: false),
      ),
      GoRoute(
        path: '/login/email',
        builder: (context, state) => const EmailAuthScreen(isSignUp: false),
      ),
      GoRoute(
        path: '/login/phone',
        builder: (context, state) => const PhoneAuthScreen(isSignUp: false),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const AuthMethodScreen(isSignUp: true),
      ),
      GoRoute(
        path: '/signup/email',
        builder: (context, state) => const EmailAuthScreen(isSignUp: true),
      ),
      GoRoute(
        path: '/signup/phone',
        builder: (context, state) => const PhoneAuthScreen(isSignUp: true),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) {
          final isSignUp = state.uri.queryParameters['signup'] == 'true';
          final phone = state.uri.queryParameters['phone'] ?? '';
          return VerificationCodeScreen(isSignUp: isSignUp, phone: phone);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/success',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Амжилттай';
          final isPasswordReset =
              state.uri.queryParameters['type'] == 'password';
          return SuccessScreen(title: title, isPasswordReset: isPasswordReset);
        },
      ),
      GoRoute(
        path: '/select-child',
        builder: (context, state) => const ChildSelectScreen(),
      ),
      GoRoute(
        path: '/child/new',
        builder: (context, state) => const ChildProfileScreen(),
      ),
      GoRoute(
        path: '/child/questionnaire',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ParentQuestionnaireScreen(
            name: extra?['name'] as String? ?? '',
            age: extra?['age'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/child/handoff',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return HandoffScreen(
            name: extra?['name'] as String? ?? '',
            age: extra?['age'] as int? ?? 0,
            parentExpressiveRating: extra?['parentExpressiveRating'] as int?,
            parentPeerCommunicationRating:
                extra?['parentPeerCommunicationRating'] as int?,
            parentVocabularyRating: extra?['parentVocabularyRating'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/playground',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PlaygroundScreen(
            name: extra?['name'] as String?,
            age: extra?['age'] as int?,
            parentExpressiveRating: extra?['parentExpressiveRating'] as int?,
            parentPeerCommunicationRating:
                extra?['parentPeerCommunicationRating'] as int?,
            parentVocabularyRating: extra?['parentVocabularyRating'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/assessment-summary',
        builder: (context, state) => const AssessmentSummaryScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const PathScreen()),
      GoRoute(
        path: '/lesson',
        builder: (context, state) {
          final lessonId = state.uri.queryParameters['lessonId'];
          return LessonPlayerScreen(lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) => const LessonPlayerScreen(practice: true),
      ),
      GoRoute(
        path: '/course-complete',
        builder: (context, state) => const CourseCompleteScreen(),
      ),
      GoRoute(
        path: '/skins',
        builder: (context, state) => const SkinSelectScreen(),
      ),
      GoRoute(
        path: '/parent-dashboard',
        builder: (context, state) => const ParentDashboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
