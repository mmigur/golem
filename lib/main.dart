import 'package:flutter/material.dart';
import 'package:golem/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://wfbdsnfswnvjkpottwxr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmYmRzbmZzd252amtwb3R0d3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1NTEyNTUsImV4cCI6MjA1ODEyNzI1NX0.z0-fnkmVSqcglD2PpjIuc4PKAFKmufIEMlT8N5yr9WA',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Ваш стартовый экран
    );
  }
}
