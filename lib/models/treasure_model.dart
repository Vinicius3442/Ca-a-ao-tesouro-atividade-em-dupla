import 'package:flutter/material.dart';

enum TreasureType { fixed, random, custom }

class TreasureModel {
  static const double fixedLatitude = -23.11443;
  static const double fixedLongitude = -45.70780;

  final double latitude;
  final double longitude;
  final String title;
  final TreasureType type;

  const TreasureModel({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.type = TreasureType.fixed,
  });

  static TreasureModel defaultTreasure() {
    return const TreasureModel(
      latitude: fixedLatitude,
      longitude: fixedLongitude,
      title: 'Tesouro Principal (Fixo)',
      type: TreasureType.fixed,
    );
  }

  /// Converte distância em metros para passos (1 passo = 0.8m)
  static double calculateSteps(double distanceInMeters) {
    return distanceInMeters / 0.8;
  }

  /// Retorna a dica textual conforme a distância em passos
  static String getProximityHint(double steps) {
    if (steps < 10) {
      return 'Muito quente! Está quase lá!';
    } else if (steps < 25) {
      return 'Quente! Está perto!';
    } else if (steps < 50) {
      return 'Morno! Continue procurando.';
    } else {
      return 'Frio! Está longe do tesouro.';
    }
  }

  /// Retorna a cor de fundo conforme a distância em passos:
  /// dist < 50 passos: vermelho (#FF4500)
  /// dist >= 50 passos: azul claro (#87CEFA)
  static Color getBackgroundColor(double steps) {
    if (steps < 50) {
      return const Color(0xFFFF4500); // Vermelho Quente
    } else {
      return const Color(0xFF87CEFA); // Azul Claro Frio
    }
  }
}
