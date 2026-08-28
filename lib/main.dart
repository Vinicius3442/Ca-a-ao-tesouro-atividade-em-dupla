import 'package:flutter/material.dart';
import 'screens/treasure_hunt_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CacaAoTesouroApp());
}

class CacaAoTesouroApp extends StatelessWidget {
  const CacaAoTesouroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caça ao Tesouro Geolocalizada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4500),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TreasureHuntScreen(),
    );
  }
}
