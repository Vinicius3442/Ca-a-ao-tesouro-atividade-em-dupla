// Pietro Rennó e Vinicius Montuani N23 e 29
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _hasPlayedForCurrentFind = false;

  bool get isPlaying => _isPlaying;

  AudioService() {
    _init();
  }

  void _init() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
    });
  }

  /// Toca a música de fundo/vitória quando o tesouro for encontrado
  Future<void> playVictorySound() async {
    if (_hasPlayedForCurrentFind) return;
    _hasPlayedForCurrentFind = true;
    _isPlaying = true;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/victory.mp3'));
    } catch (e) {
      // Se por algum motivo o asset MP3 não tocar em plataformas restritas, tentar WAV
      try {
        await _audioPlayer.play(AssetSource('audio/victory.wav'));
      } catch (_) {}
    }
  }

  /// Reinicia a trava para permitir tocar o som em uma nova busca
  void resetFindState() {
    _hasPlayedForCurrentFind = false;
  }

  /// Para a reprodução de áudio
  Future<void> stop() async {
    _isPlaying = false;
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
