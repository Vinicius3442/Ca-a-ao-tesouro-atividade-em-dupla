import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../models/treasure_model.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../widgets/compass_arrow_widget.dart';

class TreasureHuntScreen extends StatefulWidget {
  const TreasureHuntScreen({super.key});

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen> {
  // Serviços
  final AudioService _audioService = AudioService();

  // Estado do Tesouro
  TreasureModel _currentTreasure = TreasureModel.defaultTreasure();

  // Posição Atual do Jogador (GPS real ou simulado)
  double _playerLat = -23.11480; // Posição inicial próxima do tesouro para teste
  double _playerLon = -45.70780;

  // Direção do dispositivo (Bússola) em graus (0-360)
  double _heading = 0.0;

  // Distância e Passos calculados
  double _distanceInMeters = 0.0;
  double _steps = 0.0;
  double _bearingToTreasure = 0.0;

  // Stream Subscriptions
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  // Status e Modo de Simulação
  bool _isLoading = true;
  bool _useSimulation = false;
  bool _hasGpsPermission = false;
  bool _showVictoryDialog = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    bool hasPermission = await LocationService.checkLocationPermission();
    setState(() {
      _hasGpsPermission = hasPermission;
    });

    if (hasPermission) {
      // Posição inicial via GPS real
      Position? pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        _playerLat = pos.latitude;
        _playerLon = pos.longitude;
      }

      // Inicia escuta em tempo real do GPS
      _positionSubscription = LocationService.getPositionStream().listen((pos) {
        if (!_useSimulation) {
          setState(() {
            _playerLat = pos.latitude;
            _playerLon = pos.longitude;
            _recalculateMetrics();
          });
        }
      });
    }

    // Inicia escuta da Bússola do celular (se disponível)
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        setState(() {
          _heading = (event.heading! + 360) % 360;
        });
      }
    });

    _recalculateMetrics();

    setState(() {
      _isLoading = false;
    });
  }

  /// Recalcula distância em metros, passos, rumo e checa se encontrou o tesouro
  void _recalculateMetrics() {
    _distanceInMeters = LocationService.calculateDistanceInMeters(
      _playerLat,
      _playerLon,
      _currentTreasure.latitude,
      _currentTreasure.longitude,
    );

    _steps = TreasureModel.calculateSteps(_distanceInMeters);

    _bearingToTreasure = LocationService.calculateBearing(
      _playerLat,
      _playerLon,
      _currentTreasure.latitude,
      _currentTreasure.longitude,
    );

    // Tocar música quando encontrar o tesouro (< 10 passos)
    if (_steps < 10) {
      _audioService.playVictorySound();
      if (!_showVictoryDialog) {
        _showVictoryDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _displayVictoryDialog();
        });
      }
    } else {
      _showVictoryDialog = false;
    }
  }

  /// Altera para Tesouro Fixo de teste (-23.11443, -45.70780)
  void _setFixedTreasure() {
    setState(() {
      _currentTreasure = TreasureModel.defaultTreasure();
      _audioService.resetFindState();
      _showVictoryDialog = false;
      _recalculateMetrics();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tesouro definido para o ponto fixo de teste!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Gerar Tesouro Aleatório próximo à posição atual (no máximo 60m)
  void _generateRandomTreasure() {
    final randomTreasure = LocationService.generateRandomTreasureNear(
      _playerLat,
      _playerLon,
      maxDistanceMeters: 60.0,
    );

    setState(() {
      _currentTreasure = randomTreasure;
      _audioService.resetFindState();
      _showVictoryDialog = false;
      _recalculateMetrics();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Novo tesouro aleatório gerado a ~${_distanceInMeters.toStringAsFixed(0)}m (${_steps.toStringAsFixed(0)} passos)!',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.deepOrangeAccent,
      ),
    );
  }

  /// Movimenta o jogador na simulação (Norte, Sul, Leste, Oeste)
  void _moveSimulatedPlayer(double deltaLat, double deltaLon) {
    setState(() {
      _useSimulation = true;
      _playerLat += deltaLat;
      _playerLon += deltaLon;
      _recalculateMetrics();
    });
  }

  /// Exibe o Modal de Vitória ao Encontrar o Tesouro
  void _displayVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.yellow.shade800,
        title: const Row(
          children: [
            Icon(Icons.stars, color: Colors.amberAccent, size: 32),
            SizedBox(width: 8),
            Text(
              'PARABÉNS!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🏆 Você encontrou o tesouro! 🏆',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Distância final: ${_steps.toStringAsFixed(1)} passos (${_distanceInMeters.toStringAsFixed(1)}m)',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'FECHAR',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.brown,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _generateRandomTreasure();
            },
            child: const Text('NOVO TESOURO'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Regra 5: Cor de fundo conforme a distância em passos
    // dist < 50 passos: vermelho (#FF4500)
    // dist >= 50 passos: azul claro (#87CEFA)
    final Color bgColor = TreasureModel.getBackgroundColor(_steps);

    // Regra 4: Dica textual de proximidade
    final String hintText = TreasureModel.getProximityHint(_steps);

    // Ângulo efetivo da seta (Rumo ao tesouro menos rotação da bússola)
    final double effectiveArrowAngle = (_bearingToTreasure - _heading + 360) % 360;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: bgColor,
        child: SafeArea(
          child: Column(
            children: [
              // Barra Superior / Cabeçalho
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Caça ao Tesouro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_currentTreasure.title} • ${_hasGpsPermission ? "GPS Ativo" : "Simulação"}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _useSimulation ? Icons.tune : Icons.gps_fixed,
                        color: Colors.white,
                      ),
                      tooltip: _useSimulation ? 'Modo Simulação Ativo' : 'GPS em Tempo Real',
                      onPressed: () {
                        setState(() {
                          _useSimulation = !_useSimulation;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _useSimulation
                                  ? 'Modo de Simulação Manual Ativado!'
                                  : 'Usando GPS real do dispositivo.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white24, height: 1),

              // Conteúdo Principal Flexível
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Cartão de Dica Textual (Regra 4)
                      Card(
                        elevation: 8,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.black.withValues(alpha: 0.35),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            children: [
                              Text(
                                hintText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Seta Giratória em Direção ao Tesouro (Regra 6)
                      CompassArrowWidget(
                        angleInDegrees: effectiveArrowAngle,
                        steps: _steps,
                        isFound: _steps < 10,
                      ),

                      const SizedBox(height: 24),

                      // Indicador de Passos & Metros (Regra 3)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMetricTile(
                            icon: Icons.directions_walk,
                            label: 'Distância em Passos',
                            value: '${_steps.toStringAsFixed(0)} passos',
                            subValue: '(1 passo = 0.8m)',
                          ),
                          const SizedBox(width: 16),
                          _buildMetricTile(
                            icon: Icons.straighten,
                            label: 'Distância Real',
                            value: '${_distanceInMeters.toStringAsFixed(1)} m',
                            subValue: 'Coordenadas GPS',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Botões de Ação Principais
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.pin_drop, color: Colors.blueAccent),
                            label: const Text('Tesouro Fixo (Teste)'),
                            onPressed: _setFixedTreasure,
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.casino, color: Colors.white),
                            label: const Text('Gerar Tesouro Aleatório (máx 60m)'),
                            onPressed: _generateRandomTreasure,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Painel de Simulação Manual de Movimento (para Testes Práticos no VSCode / Web)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🎮 Simulação de Movimentos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _useSimulation ? 'Modo Livre Ativo' : 'GPS Real',
                          style: TextStyle(
                            color: _useSimulation ? Colors.greenAccent : Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSimButton('Aproximar (Norte)', () => _moveSimulatedPlayer(0.0001, 0.0)),
                        _buildSimButton('Afastar (Sul)', () => _moveSimulatedPlayer(-0.0001, 0.0)),
                        _buildSimButton('Leste (+Lon)', () => _moveSimulatedPlayer(0.0, 0.0001)),
                        _buildSimButton('Oeste (-Lon)', () => _moveSimulatedPlayer(0.0, -0.0001)),
                        _buildSimButton('Ir ao Tesouro', () {
                          setState(() {
                            _useSimulation = true;
                            _playerLat = _currentTreasure.latitude + 0.00002;
                            _playerLon = _currentTreasure.longitude + 0.00002;
                            _recalculateMetrics();
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subValue,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white38),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }
}
