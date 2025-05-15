import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:golem/screen/home_screen.dart';
import 'package:golem/screen/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase
  await Supabase.initialize(
    url: 'https://wfbdsnfswnvjkpottwxr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmYmRzbmZzd252amtwb3R0d3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1NTEyNTUsImV4cCI6MjA1ODEyNzI1NX0.z0-fnkmVSqcglD2PpjIuc4PKAFKmufIEMlT8N5yr9WA',
  );

  // Инициализация локализации для дат
  await initializeDateFormatting('ru_RU', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Локализация Material компонентов
        GlobalWidgetsLocalizations.delegate, // Локализация базовых виджетов
        GlobalCupertinoLocalizations.delegate, // Локализация Cupertino (iOS) компонентов
      ],
      supportedLocales: const [
        Locale('ru', 'RU'), // Русский язык
      ],
      home: HomeScreen(),
    );
  }
}