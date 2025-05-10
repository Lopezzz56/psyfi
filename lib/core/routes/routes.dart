import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/Community/screens/community_screen.dart';
import 'package:psy_fi/Motivations/screens/motivation_screen.dart';
import 'package:psy_fi/aichat/aichat_screen.dart';
import 'package:psy_fi/auth/screens/login_screen.dart';
import 'package:psy_fi/auth/screens/signup_screen.dart';
import 'package:psy_fi/bottomnav/main_screen.dart';
import 'package:psy_fi/chat/controllers/chat_controller.dart';
import 'package:psy_fi/chat/repos/chat_repo.dart';
import 'package:psy_fi/chat/screens/chat_screen.dart';
import 'package:psy_fi/chat/screens/chatdetail_screen.dart';
import 'package:psy_fi/core/components/global_state.dart';
import 'package:psy_fi/home/screens/grounding/feedback_screen.dart';
import 'package:psy_fi/home/screens/home_screen.dart';
import 'package:psy_fi/home/screens/breathing/breathing_exercise_screen.dart';
import 'package:psy_fi/home/screens/breathing/breathing_info_screen.dart';
import 'package:psy_fi/home/screens/calming%20audio/calming_audio_info_screen.dart';
import 'package:psy_fi/home/screens/calming%20audio/calming_audio_screen.dart';
import 'package:psy_fi/home/screens/grounding/grounding_form_screen.dart';
import 'package:psy_fi/home/screens/grounding/grounding_info_screen.dart';
import 'package:psy_fi/main.dart';
import 'package:psy_fi/profile/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ✅ Auth listener
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      notifyListeners();
    });
  }
}

/// ✅ Final Clean Router
final GoRouter router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/login',
  observers: [routeObserver], // ✅ Add here

  refreshListenable: AuthChangeNotifier(),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggingIn = state.uri.path == '/login';

    if (session == null && !isLoggingIn) {
      return '/login';
    }
    if (session != null && isLoggingIn) {
      return '/home';
    }
    return null;
  },
  routes: [
    /// 🔵 Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),

    /// 🟡 Main App Shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        /// Bottom nav pages
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
                GoRoute(
          path: '/motivations',
          builder: (context, state) => const MotivationScreen(),
        ),
        GoRoute(
          path: '/aichat',
          builder: (context, state) {
            final global = Provider.of<GlobalState>(context, listen: false);
            return AIChatScreen(
              userId: global.userId!,
              userRole: global.userRole!,
              supabase: global.supabase,
            );
          },
        ),
GoRoute(
  path: '/chat',
  builder: (context, state) {
    final global = Provider.of<GlobalState>(context, listen: false);
    if (global.userId != null && global.userRole != null) {
      return ChatScreen(
        userId: global.userId!,
        role: global.userRole!,
      );
    } else {
      return const Scaffold(
        body: Center(child: Text("Missing global data")),
      );
    }
  },
),



        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        /// Subpages (exercise info etc.) are also inside the ShellRoute 👇
        GoRoute(
          path: '/grounding-info',
          builder: (context, state) => const GroundingInfoScreen(),
        ),
       GoRoute(
  path: '/grounding-form',
  builder: (context, state) => const GroundingFormScreen(),

  // builder: (context, state) {
  //   final global = Provider.of<GlobalState>(context, listen: false);
  //   return GroundingFormScreen(
  //     userId: global.userId!,         // Pass the userId
  //     userRole: global.userRole!,     // Pass the userRole
  //   );
  // },
),
GoRoute(
  path: '/chat-detail',
  builder: (context, state) {
    final data = state.extra as Map<String, dynamic>;
    return ChatDetailScreen(
      currentUserId: data['currentUserId'],
      peerId: data['peerId'],
      peerName: data['peerName'],
      peerImage: data['peerImage'],
      supabase: Supabase.instance.client,
    );
  },
),

        GoRoute(
          path: '/breathing-info',
          builder: (context, state) => const BreathingInfoScreen(),
        ),
        GoRoute(
          path: '/breathing-exercise',
          builder: (context, state) => const BreathingExerciseScreen(),
        ),
        GoRoute(
          path: '/calming-info',
          builder: (context, state) => const CalmingAudioInfoScreen(),
        ),
        GoRoute(
          path: '/calming-audio',
          builder: (context, state) => const CalmingAudioScreen(),
        ),
  GoRoute(
  path: '/feedback',
  builder: (context, state) {
    final feedbackMessage = state.extra as String;
    return FeedbackScreen(feedbackMessage: feedbackMessage);
  },
)

      ],
    ),
  ],
);
