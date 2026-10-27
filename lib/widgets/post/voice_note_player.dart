import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class VoiceNotePlayer extends StatefulWidget {
  final int durationSeconds;
  final List<double>? waveform;

  const VoiceNotePlayer({
    super.key,
    required this.durationSeconds,
    this.waveform,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  bool _isPlaying = false;
  int _currentSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_currentSeconds >= widget.durationSeconds) {
          timer.cancel();
          setState(() {
            _isPlaying = false;
            _currentSeconds = 0;
          });
        } else {
          setState(() {
            _currentSeconds++;
          });
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bars = widget.waveform ??
        [0.3, 0.5, 0.8, 0.4, 0.9, 0.7, 0.3, 0.6, 0.8, 0.5, 0.4, 0.7, 0.9, 0.6, 0.3, 0.5];

    final progressRatio = widget.durationSeconds > 0
        ? (_currentSeconds / widget.durationSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Play/Pause circular button
          InkWell(
            onTap: _togglePlay,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.verifiedGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.verifiedGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform bars
          Expanded(
            child: SizedBox(
              height: 34,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(bars.length, (index) {
                  final barHeight = 6.0 + (bars[index] * 24.0);
                  final isPlayed = (index / bars.length) <= progressRatio;

                  return Container(
                    width: 3.5,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: isPlayed
                          ? AppColors.verifiedGreen
                          : AppColors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Time counter
          Text(
            _formatDuration(_isPlaying ? _currentSeconds : widget.durationSeconds),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
