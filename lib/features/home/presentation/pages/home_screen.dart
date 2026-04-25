import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:loan_lens/features/voice/logic/language_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loan_lens/features/home/presentation/widgets/ambient_particle_aura.dart';
import 'package:loan_lens/features/voice/presentation/widgets/voice_recording_sheet.dart';
import 'package:loan_lens/core/constants/language_constants.dart';
import 'package:loan_lens/features/analysis/logic/analysis_provider.dart';
import 'package:loan_lens/features/analysis/presentation/pages/analysis_result_screen.dart';
import 'package:loan_lens/features/analysis/presentation/pages/scan_history_screen.dart';
import 'package:loan_lens/core/theme/app_theme.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entranceController;
  late AnimationController _floatController;
  
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<double> _shieldScale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _cardsOpacity;
  late Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Staggered Entrance Elements
    _logoOpacity = CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));

    _shieldScale = CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 0.7, curve: Curves.elasticOut));

    _textOpacity = CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 0.8, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)));

    _cardsOpacity = CurvedAnimation(parent: _entranceController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _showLanguageSelector(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    final selectedLang = languageProvider.selectedLanguage;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLang.str('select_language'),
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: LanguageConstants.supportedLanguages.length,
                itemBuilder: (context, index) {
                  final lang = LanguageConstants.supportedLanguages[index];
                  final isSelected = selectedLang.locale == lang.locale;
                  return InkWell(
                    onTap: () {
                      languageProvider.setLanguage(lang);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.googleBlue.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppTheme.googleBlue : Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lang.nativeName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.googleBlue : Colors.white,
                            ),
                          ),
                          Text(lang.name, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startVoiceRecording(BuildContext context) async {
    final String? transcribedText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.95), // Abyssal Scrim (acts like deep dim/blur)
      builder: (context) => const VoiceRecordingSheet(),
    );

    if (transcribedText == null || transcribedText.isEmpty || !mounted) return;

    final bool isOptIn = await _showConsentDialog(context);
    if (!mounted) return;

    final selectedLang = context.read<LanguageProvider>().selectedLanguage;
    final provider = context.read<AnalysisProvider>();

    _showLoadingDialog(context, showAnimation: true);
    await provider.analyzeVoiceInput(transcribedText, selectedLang.name, userOptIn: isOptIn);
    
    if (!mounted) return;
    Navigator.pop(context);
    _handleAnalysisResult(context, provider);
  }

  Future<bool> _showConsentDialog(BuildContext context) async {
    final selectedLang = context.read<LanguageProvider>().selectedLanguage;
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212), // Deep Guardian Surface
        elevation: 24,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // Sleek, modern curve
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.0),
        ),
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: AppTheme.googleBlue.withOpacity(0.8), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedLang.str('consent_title'), 
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)
              ),
            ),
          ],
        ),
        content: Text(
          selectedLang.str('consent_msg'), 
          style: GoogleFonts.outfit(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white70, height: 1.4)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(selectedLang.str('consent_no'), style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.googleBlue),
            child: Text(selectedLang.str('consent_yes'), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showLoadingDialog(BuildContext context, {bool showAnimation = true}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black.withOpacity(0.98), // Abyssal Dark Overlay
        child: Consumer<AnalysisProvider>(
          builder: (context, provider, child) {
            final bool isAnimating = showAnimation || provider.status == AnalysisStatus.loading;
            return isAnimating 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. NEURAL PULSE
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) => Container(
                                width: 140 + (40 * _pulseController.value),
                                height: 140 + (40 * _pulseController.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.googleBlue.withOpacity(0.2 * (1 - _pulseController.value)),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 2. FOCUS ICON
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.googleBlue.withOpacity(0.1),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.filter_center_focus_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                            const _ScanningPulse(),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(); // Pure Dark Overlay while camera is preparing
          },
        ),
      ),
    );
  }

  void _handleAnalysisResult(BuildContext context, AnalysisProvider provider) {
    if (provider.status == AnalysisStatus.success || provider.status == AnalysisStatus.error) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AnalysisResultScreen()),
      );
    }
  }

  void _showImageSourceSelector(BuildContext context) async {
    final selectedLang = context.read<LanguageProvider>().selectedLanguage;
    
    final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 56),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLang.str('upload_photo'),
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(context, Icons.camera_alt_rounded, selectedLang.str('camera'), ImageSource.camera, AppTheme.googleBlue),
                _buildSourceOption(context, Icons.photo_library_rounded, selectedLang.str('gallery'), ImageSource.gallery, AppTheme.googleGreen),
              ],
            ),
          ],
        ),
      ),
    );

    if (selectedSource == null || !mounted) return;

    final bool isOptIn = await _showConsentDialog(context);
    if (!mounted) return;

    final provider = context.read<AnalysisProvider>();
    _showLoadingDialog(context, showAnimation: false);
    await provider.analyzeLoanDocument(selectedSource, selectedLang.name, userOptIn: isOptIn);

    if (!mounted) return;
    Navigator.pop(context);
    _handleAnalysisResult(context, provider);
  }

  Widget _buildSourceOption(BuildContext context, IconData icon, String label, ImageSource source, Color color) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLang = context.watch<LanguageProvider>().selectedLanguage;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          // 1. CREATIVE BACKDROP (Abstract Nebula in Header)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset('assets/images/guardian_home_bg.png', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.6, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.0),
                    const Color(0xFF080808).withOpacity(0.8),
                    const Color(0xFF080808),
                  ],
                ),
              ),
            ),
          ),
          
          // 1.5. DYNAMIC AMBIENT CORE (Fills the Void)
          const Positioned.fill(
            child: AmbientParticleAura(),
          ),

          // 2. MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // TOP NAV
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Text(
                              'LOANLENS',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            _buildTopIcon(Icons.translate_rounded, () => _showLanguageSelector(context)),
                            const SizedBox(width: 12),
                            _buildTopIcon(Icons.history_rounded, () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanHistoryScreen()));
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PULSING HERO SECTION
                  FadeTransition(
                    opacity: _textOpacity,
                    child: ScaleTransition(
                      scale: _shieldScale,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Column(
                            children: [
                              AnimatedBuilder(
                                animation: _floatController,
                                builder: (context, shieldChild) {
                                  return Transform.translate(
                                    offset: Offset(0, 8 * (1.0 - _floatController.value * 2)),
                                    child: shieldChild,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05 * _pulseController.value),
                                    border: Border.all(color: Colors.white.withOpacity(0.1 * _pulseController.value), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.googleBlue.withOpacity(0.1 * _pulseController.value),
                                        blurRadius: 40 * _pulseController.value,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.shield_rounded, 
                                    size: 48, 
                                    color: Colors.white.withOpacity(0.8 + (0.2 * _pulseController.value)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SlideTransition(
                                position: _textSlide,
                                child: Column(
                                  children: [
                                    Text(
                                      selectedLang.str('namaste'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                    ),
                                    ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // PRIMARY ACTION CARDS
                  FadeTransition(
                    opacity: _cardsOpacity,
                    child: SlideTransition(
                      position: _cardsSlide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: Column(
                          children: [
                            _buildHeroActionCard(
                              context,
                              title: selectedLang.str('upload_photo'),
                              subtitle: selectedLang.str('scan_subtitle'),
                              icon: Icons.document_scanner_rounded,
                              color: AppTheme.googleBlue,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _showImageSourceSelector(context);
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildHeroActionCard(
                              context,
                              title: selectedLang.str('speak_to_me'),
                              subtitle: selectedLang.str('speak_subtitle'),
                              icon: Icons.mic_rounded,
                              color: AppTheme.googleRed,
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                _startVoiceRecording(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildHeroActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                height: 115, // Ultra-compact height for zero-overflow guaranty
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03), // Thin glassmorphic layer
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.0),
                ),
                child: Stack(
                  children: [
                    // 1. MASSIVE BLEEDING ICON
                    Positioned(
                      right: -25,
                      top: 5,
                      bottom: -10,
                      child: Transform.rotate(
                        angle: -0.15, // Subtle dynamic tilt
                        child: Icon(
                          icon,
                          size: 130, // Optimized for compact card
                          color: color.withOpacity(0.10), // Elegant watermarked glow
                        ),
                      ),
                    ),
                    
                    // 2. FOREGROUND CONTENT & SMALL ICON
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 28),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      title.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 17, 
                                        fontWeight: FontWeight.w900, 
                                        color: Colors.white, 
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      subtitle.toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white54,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8), // Buffer for chevron
                          ],
                        ),
                      ),
                    ),
                    // 3. ACTION CHEVRON
                    const Positioned(
                      right: 24,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 28),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanningPulse extends StatefulWidget {
  const _ScanningPulse();

  @override
  State<_ScanningPulse> createState() => _ScanningPulseState();
}

class _ScanningPulseState extends State<_ScanningPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // FAST Scan Pulse
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -80, end: 80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 180,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.googleBlue.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.googleBlue.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
