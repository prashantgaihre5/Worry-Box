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

class _WorryBoxAppState extends State<WorryBoxApp> {
  final AudioService _audio = AudioService();
  late ViewState _currentView;
  late String _locale;
  bool _showConsolation = false;

  @override
  void initState() {
    super.initState();
    _locale = widget.storage.state.settings.locale;
    _currentView = deriveViewState(widget.storage);
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worry Box',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        body: Container(
          // Animated gradient background
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.bg0, AppColors.bg1, AppColors.bg0],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: _buildCurrentView(),
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
        );
      case ViewState.locked:
        return LockedScreen(
          storage: widget.storage,
          locale: _locale,
          onStateChange: _refreshView,
          showConsolation: _showConsolation,
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
