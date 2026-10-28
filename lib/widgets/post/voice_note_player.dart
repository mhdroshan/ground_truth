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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.bentoSurfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bentoBorder, width: 0.9),
      ),
      child: Row(
        children: [
          // Play/Pause circular button with liquid emerald glow
          InkWell(
            onTap: _togglePlay,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.verifiedGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.verifiedGreen.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform bars with liquid progress
          Expanded(
            child: SizedBox(
              height: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: bars.asMap().entries.map((entry) {
                  final barIdx = entry.key;
                  final heightFraction = entry.value;
                  final barProgress = barIdx / bars.length;
                  final isPassed = barProgress <= progressRatio;

                  return Container(
                    width: 3.5,
                    height: 28 * heightFraction.clamp(0.2, 1.0),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? AppColors.primaryNavy
                          : AppColors.primaryNavy.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Duration pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _formatTime(_isPlaying ? _currentSeconds : widget.durationSeconds),
              style: const TextStyle(
                color: AppColors.primaryNavy,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
