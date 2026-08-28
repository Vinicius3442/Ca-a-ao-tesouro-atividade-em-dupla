import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompassArrowWidget extends StatelessWidget {
  final double angleInDegrees; // Ângulo para o qual a seta deve apontar
  final double steps;
  final bool isFound;

  const CompassArrowWidget({
    super.key,
    required this.angleInDegrees,
    required this.steps,
    this.isFound = false,
  });

  @override
  Widget build(BuildContext context) {
    // Converte graus para radianos para o Transform.rotate
    final double angleInRadians = angleInDegrees * (math.pi / 180.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Círculo Bússola Decorativo
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Marcadores Cardinais (N, L, S, O)
                  const Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        'L',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        'O',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Seta Giratória em Direção ao Tesouro
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: angleInRadians),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value,
                  child: child,
                );
              },
              child: isFound
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 70,
                        color: Colors.white,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cabeça da Seta (Pontas)
                        Icon(
                          Icons.navigation_rounded,
                          size: 100,
                          color: steps < 25 ? Colors.yellowAccent : Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${angleInDegrees.toStringAsFixed(0)}° em relação ao Norte',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
