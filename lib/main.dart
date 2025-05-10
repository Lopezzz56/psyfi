import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psy_fi/auth/auth_controller.dart';
import 'package:psy_fi/auth/auth_repo.dart';
import 'package:psy_fi/chat/controllers/chat_controller.dart';
import 'package:psy_fi/chat/repos/chat_repo.dart';

import 'package:psy_fi/core/components/global_state.dart';
import 'package:psy_fi/core/components/loading_screen.dart';
import 'package:psy_fi/core/components/splashscreen.dart';
import 'package:psy_fi/core/components/wifichecker_screen.dart';
import 'package:psy_fi/core/routes/routes.dart';
import 'package:psy_fi/home/controllers/home_controller.dart';
import 'package:psy_fi/notification_service.dart';
import 'package:psy_fi/profile/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    // Initialize Firebase
  await Firebase.initializeApp();
await FirebaseAnalytics.instance.logAppOpen();

  // 🔔 Initialize notifications
  // await NotificationService().init();

  await Supabase.initialize(
    url: "https://yakwebqtwodfdpgvmanx.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlha3dlYnF0d29kZmRwZ3ZtYW54Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0MjI2ODksImV4cCI6MjA1ODk5ODY4OX0.VA0Q6QPo1t2EIlq1Wea8M-_JP2iBt-WtzWnq84lNlUI",
  debug: true
  );
final supabase = Supabase.instance.client;
//   final globalState = GlobalState(supabase: supabase);

  if (kIsWeb) {
    final refreshToken = supabase.auth.currentSession?.refreshToken;
    if (refreshToken != null) {
      await supabase.auth.recoverSession(refreshToken);
    }
  }
  // await Firebase.initializeApp();
  //   FirebaseMessaging messaging = FirebaseMessaging.instance;
  // NotificationSettings settings = await messaging.requestPermission(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );

  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   // Handle foreground messages
  // });

  // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //   // Handle notification tap
  // });

  // await globalState.restoreUser(); // after recoverSession

  runApp(
    ChangeNotifierProvider(
      create: (_) => GlobalState(supabase: Supabase.instance.client),
      child:  MyApp(),
    ),
  );
}
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
   MyApp({super.key});

  Future<bool> _initialization(BuildContext context) async {
    final globalState = Provider.of<GlobalState>(context, listen: false);
    await globalState.restoreUser(); // safely await restore logic
        return true; // signal that initialization is done

  //     try {
  //   debugPrint('Starting restoreUser...');
  //   await globalState.restoreUser();
  //   debugPrint('restoreUser completed');
  //   return true;
  // } catch (e, st) {
  //   debugPrint('Error in _initialization: $e\n$st');
  //   return false;
  // }
  }

@override
Widget build(BuildContext context) {
  return FutureBuilder<bool>(
    future: _initialization(context),
    builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        );
      } else if (snapshot.hasError) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          ),
        );
      } else if (snapshot.data == true) {
                final global = Provider.of<GlobalState>(context, listen: false); // ✅ FIX HERE
          // Initialize NotificationService here with the context
      final notificationService = NotificationService();
        notificationService.init(context);
        return MultiProvider(
          providers: [
            Provider<AuthRepo>(create: (_) => AuthRepo()),
            ChangeNotifierProvider(create: (_) => AuthController()),
            ChangeNotifierProvider(create: (_) => ProfileController()),
    ChangeNotifierProvider(
      create: (_) => ChatScreenController(
        repository: ChatScreenRepository(global.supabase!),
      ),
    ),
ChangeNotifierProvider(
  create: (_) => HomeScreenController(supabase: Supabase.instance.client),
)

    
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'PSY FI',
            routerConfig: router,
            builder: (context, child) {
              return WifiAutoChecker(child: child ?? const SizedBox());
            },
          ),
        );
      } else {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        );
      }
    },
  );
}

}
//   final Future<bool> _initFuture = Future.delayed(const Duration(seconds: 1)); // your restoreUser()

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         Provider<AuthRepo>(create: (_) => AuthRepo()),
//         ChangeNotifierProvider(create: (_) => AuthController()),
//         ChangeNotifierProvider(create: (_) => ProfileController()),
//       ],
//       child: MaterialApp.router(
//         debugShowCheckedModeBanner: false,
//         title: 'PSY FI',
//         routerConfig: router,
//         builder: (context, child) {
//           return FutureBuilder<bool>(
//             future: _initFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const SplashScreen(); // GoRouter will be available here
//               } else if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               } else {
//                 return WifiAutoChecker(child: child ?? const SizedBox());
//               }
//             },
//           );
//         },
//       ),
//     );
//   }
// }