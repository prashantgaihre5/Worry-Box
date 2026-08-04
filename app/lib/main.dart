import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'theme.dart';
import 'services/storage.dart';
import 'services/audio_service.dart';
import 'services/state.dart';
import 'screens/capture_screen.dart';
import 'screens/locked_screen.dart';
import 'screens/reveal_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/meditation_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/analytics_screen.dart';
import 'widgets/animated_background.dart';
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
  Timer? _expirationTimer;

  ViewState get _effectiveView => _manualOverrideView ?? _currentView;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locale = widget.storage.state.settings.locale;
    _currentView = deriveViewState(widget.storage);

    // Listen to storage changes and re-derive view state.
    widget.storage.addListener(_onStorageChanged);
    
    _expirationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Project Abhaya',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
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
                            Row(
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
                                Text(
                                  AppStrings.get('appTitle', locale: _locale),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            // Actions
                            Row(
                              children: [
                                // Language
                                GestureDetector(
                                  onTap: _toggleLocale,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassPanelBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.glassPanelBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.language, size: 16, color: AppColors.accentSoft),
                                        const SizedBox(width: 6),
                                        Text(
                                          _locale,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.accentSoft,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
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
                                    const PopupMenuItem(
                                      value: 'archive',
                                      child: Row(
                                        children: [
                                          Icon(Icons.history, size: 16, color: AppColors.accentSoft),
                                          SizedBox(width: 8),
                                          Text('Archive', style: TextStyle(color: Colors.white, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'analytics',
                                      child: Row(
                                        children: [
                                          Icon(Icons.bar_chart, size: 16, color: AppColors.accentSoft),
                                          SizedBox(width: 8),
                                          Text('Analytics', style: TextStyle(color: Colors.white, fontSize: 13)),
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

            // ── Expired Bookmarks Overlay ──
            if (widget.storage.getExpiredBookmarks().isNotEmpty)
              _buildExpiredOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredOverlay() {
    final expired = widget.storage.getExpiredBookmarks();
    return Positioned.fill(
      child: Container(
        color: const Color(0xE60B1020), // Dark semi-transparent background
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notification_important, size: 64, color: Color(0xFFFDA4AF)),
                const SizedBox(height: 16),
                const Text(
                  'Needs Review',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'The following items have passed their deadlines. Please resolve them to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: expired.length,
                    itemBuilder: (context, index) {
                      final w = expired[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xCC1E1B4B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x66F43F5E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.title.isNotEmpty ? w.title : w.text,
                              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => widget.storage.removeWorry(w.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0x3310B981),
                                      foregroundColor: const Color(0xFF6EE7B7),
                                    ),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Mark Done', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _extendDeadline(w.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0x3360A5FA),
                                      foregroundColor: const Color(0xFF93C5FD),
                                    ),
                                    icon: const Icon(Icons.edit_calendar, size: 16),
                                    label: const Text('Extend', style: TextStyle(fontSize: 12)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _extendDeadline(String id) async {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    
    final now = DateTime.now();
    final date = await showDatePicker(
      context: navContext,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF60A5FA),
            onPrimary: Colors.white,
            surface: Color(0xFF151D3B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    if (!mounted) return;
    
    final time = await showTimePicker(
      context: navContext,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF60A5FA),
            onPrimary: Colors.white,
            surface: Color(0xFF151D3B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final finalDeadline = deadline.isBefore(now) ? now.add(const Duration(minutes: 1)) : deadline;

    await widget.storage.extendBookmarkDeadline(id, finalDeadline.millisecondsSinceEpoch);
  }

  Widget _buildSectionContent() {
    if (_activeSection == 'meditation') {
      return KeyedSubtree(
        key: const ValueKey('meditation'),
        child: MeditationScreen(
          audio: _audio,
        ),
      );
    }

    if (_activeSection == 'archive') {
      return KeyedSubtree(
        key: const ValueKey('archive'),
        child: ArchiveScreen(
          storage: widget.storage,
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

    if (_activeSection == 'analytics') {
      return KeyedSubtree(
        key: const ValueKey('analytics'),
        child: AnalyticsScreen(
          storage: widget.storage,
          locale: _locale,
        ),
      );
    }

    // Default Home Section
    return Column(
      key: const ValueKey('home'),
      children: [
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

