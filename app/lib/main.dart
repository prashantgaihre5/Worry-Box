import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/storage.dart';
import 'services/audio_service.dart';
import 'services/state.dart';
import 'screens/capture_screen.dart';
import 'screens/locked_screen.dart';
import 'screens/reveal_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'widgets/animated_background.dart';
import 'widgets/expired_bookmarks_banner.dart';
import 'l10n/app_strings.dart';
import 'models/worry.dart';
import 'dart:async';

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
  String _activeSection = 'home';

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

  void _navigateToCapture() {
    setState(() {
      _manualOverrideView = ViewState.capture;
    });
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
            const AnimatedBackground(),

            // ── Main content with AnimatedSwitcher transitions ──
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                  child: Column(
                    children: [
                      // Global Top Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.glassPanelBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.glassPanelBorder),
                                    ),
                                    child: const Icon(Icons.layers, color: AppColors.accentSoft, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  const Flexible(
                                    child: Text(
                                      'Worry Box',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Actions
                            Row(
                              children: [
                                // Audio
                                GestureDetector(
                                  onTap: () async {
                                    await _audio.toggle();
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _audio.isPlaying ? AppColors.accent.withValues(alpha: 0.25) : AppColors.glassPanelBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _audio.isPlaying ? AppColors.accent.withValues(alpha: 0.5) : AppColors.glassPanelBorder,
                                      ),
                                    ),
                                    child: Icon(
                                      _audio.isPlaying ? Icons.volume_up : Icons.volume_off,
                                      size: 16,
                                      color: _audio.isPlaying ? AppColors.accentSoft : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Language — icon only to save space
                                GestureDetector(
                                  onTap: _toggleLocale,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassPanelBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.glassPanelBorder),
                                    ),
                                    child: Text(
                                      _locale.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentSoft,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Menu
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    setState(() {
                                      _activeSection = value;
                                    });
                                  },
                                  color: AppColors.glassPanelBg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  offset: const Offset(0, 40),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassPanelBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.glassPanelBorder),
                                    ),
                                    child: const Icon(Icons.menu, size: 16, color: AppColors.textMuted),
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'home',
                                      child: Row(
                                        children: [
                                          Icon(Icons.home_outlined, size: 16, color: AppColors.accentSoft),
                                          SizedBox(width: 8),
                                          Text('Home', style: TextStyle(color: Colors.white, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'meditation',
                                      child: Row(
                                        children: [
                                          Icon(Icons.self_improvement, size: 16, color: AppColors.accentSoft),
                                          SizedBox(width: 8),
                                          Text('Meditation', style: TextStyle(color: Colors.white, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'bookmarks',
                                      child: Row(
                                        children: [
                                          Icon(Icons.bookmark_border, size: 16, color: AppColors.accentSoft),
                                          SizedBox(width: 8),
                                          Text('Bookmarks', style: TextStyle(color: Colors.white, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      
                      // Section Content
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildSectionContent(),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildSectionContent() {
    if (_activeSection == 'meditation') {
      return Center(
        key: const ValueKey('meditation'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.self_improvement, size: 48, color: AppColors.accentSoft),
            const SizedBox(height: 16),
            const Text(
              'Meditation Area',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    if (_activeSection == 'bookmarks') {
      return KeyedSubtree(
        key: const ValueKey('bookmarks'),
        child: BookmarksScreen(
          storage: widget.storage,
          locale: _locale,
        ),
      );
    }

    // Default Home Section
    return Column(
      key: const ValueKey('home'),
      children: [
        // Expired bookmarks banner — inline in home screen
        ExpiredBookmarksBanner(storage: widget.storage),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.glassPanelBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassPanelBorder),
            ),
            child: Row(
              children: [
                _buildSegment('Capture', ViewState.capture, Icons.edit_outlined),
                _buildSegment('Locked', ViewState.locked, Icons.lock_outline),
                _buildSegment('Reveal', ViewState.reveal, Icons.auto_awesome),
              ],
            ),
          ),
        ),
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
          onNavigateToCapture: _navigateToCapture,
        );
      case ViewState.reveal:
        return RevealScreen(
          storage: widget.storage,
          locale: _locale,
          onAllCleared: _refreshView,
          onNavigateToCapture: _navigateToCapture,
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

