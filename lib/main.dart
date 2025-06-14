import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authFlowType: AuthFlowType.pkce, // Supaya sesi tetap aktif
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(), // Auto-check login
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// 🔒 AuthGate: Cek status login saat app dibuka
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Future.microtask(() {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } else {
      Future.microtask(() {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
