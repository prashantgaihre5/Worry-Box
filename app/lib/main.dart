import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/storage.dart';
import 'services/audio_service.dart';
import 'services/state.dart';
import 'screens/capture_screen.dart';
import 'screens/locked_screen.dart';
import 'screens/reveal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  runApp(WorryBoxApp(storage: storage));
}

class WorryBoxApp extends StatefulWidget {
  final StorageService storage;

  const WorryBoxApp({super.key, required this.storage});

  @override
  State<WorryBoxApp> createState() => _WorryBoxAppState();
}

class _WorryBoxAppState extends State<WorryBoxApp> with WidgetsBindingObserver {
  final AudioService _audio = AudioService();
  late ViewState _currentView;
  ViewState? _manualOverrideView;
  late String _locale;
  String? _lastAddedWorryText;

  ViewState get _effectiveView => _manualOverrideView ?? _currentView;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locale = widget.storage.state.settings.locale;
    _currentView = deriveViewState(widget.storage);

    // Listen to storage changes and re-derive view state.
    widget.storage.addListener(_onStorageChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.storage.removeListener(_onStorageChanged);
    _audio.dispose();
    super.dispose();
  }

  /// Re-derive view state when the app returns from background.
  /// Handles the case where unlock time passed while the app was suspended.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshView();
    }
  }

  void _onStorageChanged() {
    _refreshView();
  }

  void _refreshView() {
    final newView = deriveViewState(widget.storage);
    if (newView != _currentView || _lastAddedWorryText != null) {
      setState(() {
        _currentView = newView;
        _manualOverrideView = null; // Reset override on significant state change
        _lastAddedWorryText = null;
      });
    } else {
      setState(() {
        // Just refresh to ensure timer states might be updated
      });
    }
  }

  void _onWorryAdded(String text) {
    setState(() {
      _currentView = deriveViewState(widget.storage);
      _manualOverrideView = null; // Always reset when they add a worry
      _lastAddedWorryText = text;
    });
  }

  void _toggleLocale() {
    setState(() {
      _locale = _locale == 'en' ? 'ne' : 'en';
    });
    widget.storage.setLocale(_locale);
  }

  /// Dev mode: long-press the title to toggle 10-second unlock.
  void _toggleDevMode() {
    if (widget.storage.isDevMode) {
      widget.storage.disableDevMode();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Dev mode disabled'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      widget.storage.enableDevMode(60);
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Dev mode enabled — worries unlock in 1 minute'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    setState(() {});
  }

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Worry Box',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        body: Stack(
          children: [
            // ── Animated gradient background ──
            const _AnimatedBackground(),

            // ── Main content with AnimatedSwitcher transitions ──
            SafeArea(
              child: Column(
                children: [
                  // Global Top Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Worry Box',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _audio.isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () async {
                                await _audio.toggle();
                                setState(() {});
                              },
                            ),
                            TextButton(
                              onPressed: _toggleLocale,
                              child: Text(
                                _locale.toUpperCase(),
                                style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Segmented Control (Visual Indicator)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceStrong,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _buildSegment('Capture', ViewState.capture, Icons.edit_outlined),
                          _buildSegment('Locked', ViewState.locked, Icons.lock_outline),
                          _buildSegment('Reveal', ViewState.reveal, Icons.lock_open_outlined),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: KeyedSubtree(
                        key: ValueKey<ViewState>(_effectiveView),
                        child: _buildCurrentView(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Dev mode badge ──
            if (widget.storage.isDevMode)
              Positioned(
                top: 48,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'dev mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // ── Storage unavailable warning ──
            if (!widget.storage.isAvailable)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: AppColors.error.withValues(alpha: 0.9),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _locale == 'ne'
                        ? 'यो एप बन्द गरेपछि तपाईंका चिन्ताहरू सुरक्षित हुनेछैनन्।'
                        : "Your worries won't be saved after you close this app.",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_effectiveView) {
      case ViewState.capture:
        return CaptureScreen(
          storage: widget.storage,
          audio: _audio,
          locale: _locale,
          onWorryAdded: _onWorryAdded,
          onToggleLocale: _toggleLocale,
          onToggleDevMode: _toggleDevMode,
        );
      case ViewState.locked:
        return LockedScreen(
          storage: widget.storage,
          audio: _audio,
          locale: _locale,
          onStateChange: _refreshView,
        );
      case ViewState.reveal:
        return RevealScreen(
          storage: widget.storage,
          locale: _locale,
          onAllCleared: _refreshView,
        );
    }
  }

  Widget _buildSegment(String text, ViewState state, IconData icon) {
    final isActive = _effectiveView == state;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _manualOverrideView = state;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? AppColors.accent : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slow-breathing animated gradient background.
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 15 seconds for a very slow, calming breath effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Evaluate the gradient stops based on the animation value
        final val = _controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: const [
                AppColors.bg1,
                AppColors.bg0,
              ],
              stops: [
                0.3 + (val * 0.2), // pulses between 0.3 and 0.5
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}
