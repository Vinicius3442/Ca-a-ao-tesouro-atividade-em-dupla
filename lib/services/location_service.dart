// Pietro Rennó e Vinicius Montuani N23 e 29
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/treasure_model.dart';

class LocationService {
  /// Verifica se os serviços de localização estão ativos e se as permissões foram concedidas
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtém a localização atual do jogador
  static Future<Position?> getCurrentPosition() async {
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Escuta atualizações da posição do jogador em tempo real
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Atualiza a cada 1 metro
      ),
    );
  }

  /// Calcula a distância em metros entre dois pontos (Haversine)
  static double calculateDistanceInMeters(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  /// Calcula o rumo (bearing/azimuth em graus de 0 a 360) da posição do jogador até o tesouro
  static double calculateBearing(
    double playerLat,
    double playerLon,
    double treasureLat,
    double treasureLon,
  ) {
    double bearing = Geolocator.bearingBetween(
      playerLat,
      playerLon,
      treasureLat,
      treasureLon,
    );
    // Garante que esteja no intervalo 0° - 360°
    return (bearing + 360) % 360;
  }

  /// Gera um novo tesouro aleatório a no máximo [maxDistanceMeters] (padrão 60m) da posição atual
  static TreasureModel generateRandomTreasureNear(
    double currentLat,
    double currentLon, {
    double maxDistanceMeters = 60.0,
  }) {
    final random = Random();
    // Distância aleatória entre 15 e maxDistanceMeters (ex: 60m)
    final distanceInMeters = 15.0 + random.nextDouble() * (maxDistanceMeters - 15.0);
    // Ângulo aleatório de 0 a 2*pi
    final angleRad = random.nextDouble() * 2 * pi;

    // Aproximação de conversão metros -> graus de latitude/longitude
    // 1 grau de lat = ~111,320m
    final deltaLat = (distanceInMeters * cos(angleRad)) / 111320.0;
    final deltaLon = (distanceInMeters * sin(angleRad)) /
        (111320.0 * cos(currentLat * pi / 180.0));

    final newLat = currentLat + deltaLat;
    final newLon = currentLon + deltaLon;

    return TreasureModel(
      latitude: double.parse(newLat.toStringAsFixed(5)),
      longitude: double.parse(newLon.toStringAsFixed(5)),
      title: 'Tesouro Aleatório (~${distanceInMeters.toStringAsFixed(0)}m)',
      type: TreasureType.random,
    );
  }
}
