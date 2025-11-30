import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://mucqeufuymtxmkewlcfo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11Y3FldWZ1eW10eG1rZXdsY2ZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyMzkwMjcsImV4cCI6MjA3OTgxNTAyN30.XJjEGe8r9uWg3Rcjv9Jxk_bg2lmydq-aGhTJ3L7_gqA',
  );
  
  runApp(const AstraApp());
}

class AstraApp extends StatelessWidget {
  const AstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASTRA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(AppTheme.purple),
      darkTheme: AppTheme.darkTheme(AppTheme.purple),
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
