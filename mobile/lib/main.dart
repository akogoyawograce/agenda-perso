import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);

  await Hive.initFlutter();
  await Hive.openBox('events');
  await Hive.openBox('auth');

  if (!kIsWeb) {
    OneSignal.initialize('1702283e-a508-4e9b-bb49-2190dd8453ab');
    await OneSignal.Notifications.requestPermission(true);
  }

  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
    GoRoute(path: '/home',  builder: (ctx, state) => const HomeScreen()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Agenda Personnel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}