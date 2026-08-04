import 'dart:math';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_service.dart';
import '../theme.dart';

class MeditationScreen extends StatefulWidget {
  final AudioService audio;
  
  const MeditationScreen({
    super.key,
    required this.audio,
  });

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // 16s total cycle for Box Breathing
  // 0.0 to 0.25: Inhale (4s)
  // 0.25 to 0.50: Hold (4s)
  // 0.50 to 0.75: Exhale (4s)
  // 0.75 to 1.0: Hold (4s)
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _breathingPhaseText {
    final val = _controller.value;
    if (val < 0.25) return "Breathe In...";
    if (val < 0.50) return "Hold...";
    if (val < 0.75) return "Breathe Out...";
    return "Hold...";
  }

  double get _circleScale {
    final val = _controller.value;
    if (val < 0.25) {
      // Inhale: Scale 1.0 -> 1.5
      return 1.0 + (val / 0.25) * 0.5;
    } else if (val < 0.50) {
      // Hold: Scale 1.5
      return 1.5;
    } else if (val < 0.75) {
      // Exhale: Scale 1.5 -> 1.0
      return 1.5 - ((val - 0.50) / 0.25) * 0.5;
    } else {
      // Hold: Scale 1.0
      return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Meditation',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Center yourself with box breathing and ambient sounds.',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFFBFDBFE).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 48),
          
          // Breathing Animation
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _circleScale,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withValues(alpha: 0.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            _breathingPhaseText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          // Audio Player
          _buildAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return ListenableBuilder(
      listenable: widget.audio,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soundscapes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFBFDBFE).withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Track.meditativeTracks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final track = Track.meditativeTracks[index];
                  final isPlaying = widget.audio.isPlaying && widget.audio.currentTrackId == track.id;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => widget.audio.toggleTrack(track.id, track.url),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPlaying 
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : AppColors.glassInputBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isPlaying
                                ? AppColors.accent.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(track.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              track.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                                color: isPlaying ? Colors.white : const Color(0xFFBFDBFE).withValues(alpha: 0.7),
                              ),
                            ),
                            if (isPlaying) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.pause, size: 16, color: Colors.white),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
