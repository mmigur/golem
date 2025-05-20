import 'package:flutter/material.dart';
import 'package:golem/screen/sign_in_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSession();

    // Анимация появления
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2)); // Задержка для анимации

    if (!mounted) return;

    final session = _supabase.auth.currentSession;
    
    if (session != null) {
      // Сессия активна - переходим на главный экран
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    } else {
      // Сессия не активна - переходим на экран входа
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/sign_in',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 1),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 250,
              height: 250,
              child: Image.asset('assets/splash_screen_logo.png'),
            ),
          ),
        ),
      ),
    );
  }
}