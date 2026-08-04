import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/storage.dart';
import '../services/audio_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/box_animation.dart';

class CaptureScreen extends StatefulWidget {
  final StorageService storage;
  final AudioService audio;
  final String locale;
  final Function(String) onWorryAdded;
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleDevMode;

  const CaptureScreen({
    super.key,
    required this.storage,
    required this.audio,
    required this.locale,
    required this.onWorryAdded,
    required this.onToggleLocale,
    required this.onToggleDevMode,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with SingleTickerProviderStateMixin {
  final _inputController = TextEditingController();
  int? _selectedDurationSeconds;
  
  late AnimationController _dropController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String get _locale => widget.locale;

  String _formatDuration(int seconds) {
    if (seconds == 10) return '10 Seconds';
    if (seconds == 60) return '1 Minute';
    if (seconds == 300) return '5 Minutes';
    if (seconds == 3600) return '1 Hour';
    if (seconds == 14400) return '4 Hours';
    if (seconds == 43200) return '12 Hours';
    if (seconds == 86400) return '1 Day';
    return '${seconds ~/ 3600} Hours';
  }

  @override
  void initState() {
    super.initState();
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInBack),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.8)).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInBack),
    );
  }

  @override
  void dispose() {
    _dropController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _submitWorry() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    // Start the drop animation
    await _dropController.forward();

    try {
      if (_selectedDurationSeconds != null) {
        await widget.storage.addWorryWithDuration(
          title: text,
          description: "",
          durationSeconds: _selectedDurationSeconds!,
        );
      } else {
        await widget.storage.addWorry(text);
      }
      
      _inputController.clear();
      FocusScope.of(context).unfocus();
      _dropController.reset();
      
      widget.onWorryAdded(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _addExample(String text) {
    _inputController.text = text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Header Title & Subtitle
          Text(
            AppStrings.get('appTitle', locale: _locale),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ), // A gradient text could be used here via ShaderMask
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('subtitle', locale: _locale),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.accentSoft.withValues(alpha: 0.7),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Box Animation
          const SizedBox(
            width: 144,
            height: 144,
            child: BoxAnimationWidget(
              boxState: BoxState.open,
              size: 144,
            ),
          ),
          const SizedBox(height: 20),

          // Input with Drop Animation
          AnimatedBuilder(
            animation: _dropController,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.glassInputBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassInputBorder),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _inputController,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "What's on your mind? Describe what's troubling you...",
                      hintStyle: TextStyle(color: AppColors.accentSoft.withValues(alpha: 0.35)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Text(
                    '${_inputController.text.length} chars',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.accentSoft.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

        // Custom Duration Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lock Duration',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFBFDBFE).withValues(alpha: 0.8),
                ),
              ),
              PopupMenuButton<int?>(
                initialValue: _selectedDurationSeconds,
                onSelected: (val) => setState(() => _selectedDurationSeconds = val),
                color: const Color(0xFF151D3B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 14, color: AppColors.accentSoft),
                      const SizedBox(width: 6),
                      Text(
                        _selectedDurationSeconds == null 
                            ? 'Scheduled Time' 
                            : _formatDuration(_selectedDurationSeconds!),
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white54),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('Scheduled Worry Time', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 10,
                    child: Text('10 Seconds', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 60,
                    child: Text('1 Minute', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 300,
                    child: Text('5 Minutes', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 3600,
                    child: Text('1 Hour', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 14400,
                    child: Text('4 Hours', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 43200,
                    child: Text('12 Hours', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 86400,
                    child: Text('1 Day', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Put it away button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _inputController.text.trim().isNotEmpty
                  ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5), Color(0xFF3B82F6)])
                  : const LinearGradient(colors: [Color(0x0DFFFFFF), Color(0x0DFFFFFF)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _inputController.text.trim().isNotEmpty
                    ? const Color(0x6660A5FA)
                    : const Color(0x0DFFFFFF),
              ),
              boxShadow: _inputController.text.trim().isNotEmpty
                  ? const [BoxShadow(color: Color(0x732563EB), blurRadius: 25)]
                  : [],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: _inputController.text.trim().isNotEmpty ? Colors.white : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _inputController.text.trim().isEmpty ? null : _submitWorry,
              icon: Icon(Icons.lock, size: 16, color: _inputController.text.trim().isNotEmpty ? AppColors.accentSoft : Colors.grey),
              label: Text(
                AppStrings.get('submitButton', locale: _locale),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Suggestion Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Examples:',
                style: TextStyle(color: AppColors.accentSoft.withValues(alpha: 0.5), fontSize: 11),
              ),
              const SizedBox(width: 8),
              _buildPill('Job evaluation', "I'm anxious about my job evaluation next Tuesday."),
              const SizedBox(width: 8),
              _buildPill('Unreplied text', "Overthinking a text message reply I sent this morning."),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String fullText) {
    return GestureDetector(
      onTap: () => _addExample(fullText),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Text(
          label,
          style: TextStyle(color: AppColors.accentSoft.withValues(alpha: 0.7), fontSize: 11),
        ),
      ),
    );
  }
}
