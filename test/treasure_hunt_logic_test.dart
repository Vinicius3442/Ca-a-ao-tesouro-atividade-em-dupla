import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caca_ao_tesouro/models/treasure_model.dart';
import 'package:caca_ao_tesouro/services/location_service.dart';

void main() {
  group('Regras de Negócio do Tesouro', () {
    test('1. Coordenadas do Tesouro Fixo padrão', () {
      final treasure = TreasureModel.defaultTreasure();
      expect(treasure.latitude, equals(-23.11443));
      expect(treasure.longitude, equals(-45.70780));
    });

    test('2. Cálculo de Passos (1 passo = 0.8 metros)', () {
      expect(TreasureModel.calculateSteps(8.0), equals(10.0));
      expect(TreasureModel.calculateSteps(40.0), equals(50.0));
      expect(TreasureModel.calculateSteps(0.0), equals(0.0));
    });

    test('3. Dicas Textuais de Proximidade conforme a faixa de passos', () {
      // < 10 passos: "Muito quente! Está quase lá!"
      expect(
        TreasureModel.getProximityHint(5),
        equals('Muito quente! Está quase lá!'),
      );

      // < 25 passos: "Quente! Está perto!"
      expect(
        TreasureModel.getProximityHint(15),
        equals('Quente! Está perto!'),
      );

      // < 50 passos: "Morno! Continue procurando."
      expect(
        TreasureModel.getProximityHint(35),
        equals('Morno! Continue procurando.'),
      );

      // >= 50 passos: "Frio! Está longe do tesouro."
      expect(
        TreasureModel.getProximityHint(50),
        equals('Frio! Está longe do tesouro.'),
      );
      expect(
        TreasureModel.getProximityHint(100),
        equals('Frio! Está longe do tesouro.'),
      );
    });

    test('4. Cor de fundo conforme a distância em passos', () {
      // dist < 50 passos: vermelho (#FF4500)
      expect(
        TreasureModel.getBackgroundColor(10),
        equals(const Color(0xFFFF4500)),
      );
      expect(
        TreasureModel.getBackgroundColor(49.9),
        equals(const Color(0xFFFF4500)),
      );

      // dist >= 50 passos: azul claro (#87CEFA)
      expect(
        TreasureModel.getBackgroundColor(50.0),
        equals(const Color(0xFF87CEFA)),
      );
      expect(
        TreasureModel.getBackgroundColor(80),
        equals(const Color(0xFF87CEFA)),
      );
    });

    test('5. Geração de Tesouro Aleatório (máximo 60m)', () {
      const currentLat = -23.11443;
      const currentLon = -45.70780;

      final randomTreasure = LocationService.generateRandomTreasureNear(
        currentLat,
        currentLon,
        maxDistanceMeters: 60.0,
      );

      final distance = LocationService.calculateDistanceInMeters(
        currentLat,
        currentLon,
        randomTreasure.latitude,
        randomTreasure.longitude,
      );

      expect(distance, lessThanOrEqualTo(65.0)); // Tolerância pequena de precisão
      expect(randomTreasure.type, equals(TreasureType.random));
    });
  });
}
