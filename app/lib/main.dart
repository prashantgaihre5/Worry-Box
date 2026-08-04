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

class _WorryBoxAppState extends State<WorryBoxApp>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  late ViewState _currentView;
  late String _locale;
  bool _showConsolation = false;
  bool _devMode = false;

  // Animated gradient background (spec §7: slow, animated gradient between bg0 and bg1)
  late AnimationController _gradientController;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locale = widget.storage.state.settings.locale;
    _currentView = deriveViewState(widget.storage);

    // 8-second cycle, reversing for a smooth continuous animation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _gradientColor1 = ColorTween(
      begin: AppColors.bg0,
      end: AppColors.bg1,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    _gradientColor2 = ColorTween(
      begin: AppColors.bg1,
      end: AppColors.bg0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gradientController.dispose();
    _audio.dispose();
    super.dispose();
  }

  /// Re-derive view state when app resumes from background (spec §6, §10).
  /// This ensures that if the unlock time passed while backgrounded,
  /// the app immediately transitions to REVEAL without waiting for a timer tick.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshView();
    }
  }

  void _refreshView() {
    setState(() {
      _currentView = deriveViewState(widget.storage);
      _showConsolation = false;
    });
  }

  void _onWorryAdded() {
    setState(() {
      _currentView = deriveViewState(widget.storage);
      _showConsolation = true;
    });
  }

  void _toggleLocale() {
    setState(() {
      _locale = _locale == 'en' ? 'ne' : 'en';
    });
    widget.storage.setLocale(_locale);
  }

  /// Toggle dev mode via long-press anywhere on the scaffold (spec §11).
  /// When active, addWorry() sets unlockAt = now + 10 seconds.
  void _toggleDevMode() {
    setState(() {
      _devMode = !_devMode;
    });
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(
          _devMode
              ? 'Dev mode ON — worries unlock in 10 seconds'
              : 'Dev mode OFF — normal unlock schedule',
          style: const TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.bg1,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worry Box',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: GestureDetector(
        onLongPress: _toggleDevMode,
        child: Scaffold(
          key: _scaffoldKey,
          body: AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _gradientColor1.value ?? AppColors.bg0,
                      _gradientColor2.value ?? AppColors.bg1,
                      _gradientColor1.value ?? AppColors.bg0,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey<ViewState>(_currentView),
                      child: _buildCurrentView(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case ViewState.capture:
        return CaptureScreen(
          storage: widget.storage,
          audio: _audio,
          locale: _locale,
          onWorryAdded: _onWorryAdded,
          onToggleLocale: _toggleLocale,
          devMode: _devMode,
        );
      case ViewState.locked:
        return LockedScreen(
          storage: widget.storage,
          locale: _locale,
          onStateChange: _refreshView,
          showConsolation: _showConsolation,
          devMode: _devMode,
        );
      case ViewState.reveal:
        return RevealScreen(
          storage: widget.storage,
          locale: _locale,
          onAllCleared: _refreshView,
        );
    }
  }
}
