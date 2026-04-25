import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loan_lens/features/analysis/logic/analysis_provider.dart';
import 'package:loan_lens/features/analysis/logic/analysis_models.dart';
import 'package:loan_lens/features/voice/logic/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:loan_lens/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loan_lens/features/analysis/presentation/widgets/risk_gauge.dart';
import 'package:loan_lens/core/constants/language_constants.dart';
import 'package:loan_lens/features/home/presentation/widgets/ambient_particle_aura.dart';
import 'dart:ui';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<AnalysisProvider>().stopTTS();
        }
      },
      child: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.status == AnalysisStatus.loading) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.googleBlue),
                    const SizedBox(height: 24),
                    Text(context.read<LanguageProvider>().selectedLanguage.str('analyzing'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            );
          }

          if (provider.status == AnalysisStatus.error) {
            final isNetworkError = provider.error?.contains('Guardian Unreachable') ?? false;
            final selectedLang = context.read<LanguageProvider>().selectedLanguage;
            
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1.1),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                        onEnd: () {},
                        child: Icon(
                          isNetworkError ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                          size: 80,
                          color: AppTheme.googleYellow.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        isNetworkError 
                          ? selectedLang.str('error_network_title') 
                          : selectedLang.str('error'),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isNetworkError 
                          ? selectedLang.str('error_network_msg')
                          : (provider.error ?? 'Something unexpected happened.'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Colors.white54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (isNetworkError) ...[
                        FilledButton.icon(
                          onPressed: () => provider.retryLastAnalysis(),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            backgroundColor: AppTheme.googleGreen,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            selectedLang.str('btn_retry'), 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextButton(
                        onPressed: () {
                          provider.reset();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(60),
                          foregroundColor: Colors.white38,
                        ),
                        child: Text(selectedLang.str('btn_home')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final score = provider.score;
          final isSafe = score >= 0.7;
          final isWarning = score >= 0.4 && score < 0.7;
          final selectedLang = context.watch<LanguageProvider>().selectedLanguage;

          final Color scoreColor = isSafe
              ? AppTheme.googleGreen
              : isWarning
                  ? AppTheme.googleYellow
                  : AppTheme.googleRed;

          final IconData scoreIcon = isSafe
              ? Icons.verified_user_rounded
              : isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.gpp_bad_rounded;

          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(
                provider.uiTranslations['hdr_scorecard'] ?? 'Fairness Scorecard',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900, 
                  fontSize: 20, 
                  letterSpacing: 0.5
                ),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white70),
              actions: [
                IconButton(
                  onPressed: () => _shareResult(context, provider),
                  icon: const Icon(Icons.share_rounded, size: 22),
                ),
                IconButton(
                  onPressed: () => provider.replayVerdict(),
                  icon: const Icon(Icons.volume_up_rounded, size: 22),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // 1. DYNAMIC BREATHING CORE (Guardian Identity)
                const Positioned.fill(
                  child: AmbientParticleAura(),
                ),
                
                // 2. SCROLLABLE DASHBOARD CONTENT
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // GLASSMORPHIC RISK HERO
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: score),
                          duration: const Duration(milliseconds: 1800),
                          curve: Curves.elasticOut,
                          builder: (context, animatedScore, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  padding: const EdgeInsets.all(2), // Boundary glow shell
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.04),
                                        Colors.white.withOpacity(0.01),
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                    child: CinematicRiskGauge(
                                      score: animatedScore,
                                      scoreColor: scoreColor,
                                      fairnessLabel: provider.uiTranslations['lbl_fairness'] ?? 'FAIRNESS INDEX',
                                      safeLabel: provider.uiTranslations['safe_label'] ?? 'SAFE',
                                      modLabel: provider.uiTranslations['mod_label'] ?? 'MODERATE RISK',
                                      dangerLabel: provider.uiTranslations['high_label'] ?? 'PREDATORY',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // SECTION HEADER
                        Text(
                          (provider.uiTranslations['hdr_detailed'] ?? 'DETAILED AUDIT').toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                            color: Colors.white24,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // MINIMALIST FINDINGS LIST
                        provider.findings.isEmpty
                            ? _buildPremiumEmptyState(context)
                            : Builder(
                                builder: (context) {
                                  final sorted = [...provider.findings]..sort((a, b) {
                                      int rank(FairnessLevel l) => l == FairnessLevel.danger ? 0 : l == FairnessLevel.warning ? 1 : 2;
                                      return rank(a.level).compareTo(rank(b.level));
                                    });
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: sorted.length,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) => _AnimatedFindingCard(
                                      index: index,
                                      finding: sorted[index],
                                    ),
                                  );
                                },
                              ),
                        
                        const SizedBox(height: 12),
                        if (provider.isPredatory) _buildActionCard(context, provider, selectedLang),
                        const SizedBox(height: 110), // Footer clearance
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // ACTION PILL FOOTER
            bottomNavigationBar: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.backgroundColor.withOpacity(0.8),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
                  child: _CinematicActionButton(
                    onPressed: () {
                      provider.reset();
                      Navigator.pop(context);
                    },
                    label: provider.uiTranslations['btn_scan'] ?? 'SCAN ANOTHER',
                    icon: Icons.filter_center_focus_rounded,
                    baseColor: AppTheme.googleBlue,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _shareResult(BuildContext context, AnalysisProvider provider) {
    final selectedLang = context.read<LanguageProvider>().selectedLanguage;
    final scoreValue = (provider.score * 10).toStringAsFixed(1);
    final statusLabel = provider.score >= 0.7 
        ? (provider.uiTranslations['safe_label'] ?? 'SAFE') 
        : provider.score >= 0.4 
            ? (provider.uiTranslations['mod_label'] ?? 'WARNING') 
            : (provider.uiTranslations['high_label'] ?? 'DANGER');
    
    final scorecardHdr = provider.uiTranslations['hdr_scorecard'] ?? selectedLang.str('share_title');
    String message = '🛡️ $scorecardHdr\n\nScore: $scoreValue/10 — $statusLabel\n\n';
    for (var finding in provider.findings.take(3)) {
      message += '• ${finding.term}: ${finding.description}\n';
    }
    message += '\nProtect yourself with LoanLens! 🛡️';
    Share.share(message);
  }

  Widget _buildActionCard(BuildContext context, AnalysisProvider provider, LanguageModel selectedLang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          final Uri url = Uri.parse('https://cms.rbi.org.in/');
          await launchUrl(url, mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF150808),
            borderRadius: BorderRadius.circular(8), // Sharp minimalist corners
            border: Border.all(color: AppTheme.googleRed.withOpacity(0.4), width: 1.0),
          ),
          child: Center(
            child: Text(
              provider.uiTranslations['btn_rbi'] ?? 'File RBI Complaint',
              style: GoogleFonts.outfit(
                color: AppTheme.googleRed.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumEmptyState(BuildContext context) {
    final selectedLang = context.read<LanguageProvider>().selectedLanguage;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.googleGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.googleGreen.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppTheme.googleGreen, size: 48),
          const SizedBox(height: 16),
          Text(
            selectedLang.str('all_clear'),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.googleGreen),
          ),
          const SizedBox(height: 8),
          Text(
            selectedLang.str('all_clear_msg'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFindingCard extends StatefulWidget {
  final int index;
  final Finding finding;
  const _AnimatedFindingCard({required this.index, required this.finding});

  @override
  State<_AnimatedFindingCard> createState() => _AnimatedFindingCardState();
}

class _AnimatedFindingCardState extends State<_AnimatedFindingCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _chevronController;
  late Animation<double> _chevronRotation;
  late Animation<double> _bodyFade;
  late Animation<Offset> _bodySlide;

  @override
  void initState() {
    super.initState();
    // Start collapsed by default as requested
    _isExpanded = false;

    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _isExpanded ? 1.0 : 0.0,
    );

    _chevronRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOut),
    );

    _bodyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chevronController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _bodySlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _chevronController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _chevronController.forward();
    } else {
      _chevronController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.finding.level == FairnessLevel.danger
        ? AppTheme.googleRed
        : widget.finding.level == FairnessLevel.warning
            ? AppTheme.googleYellow
            : AppTheme.googleGreen;

    final IconData severityIcon = widget.finding.level == FairnessLevel.danger
        ? Icons.gpp_bad_rounded
        : widget.finding.level == FairnessLevel.warning
            ? Icons.warning_amber_rounded
            : Icons.verified_rounded;

    final String chipLabel = widget.finding.level == FairnessLevel.danger
        ? 'DANGER'
        : widget.finding.level == FairnessLevel.warning
            ? 'WARNING'
            : 'SAFE';

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Color.lerp(Colors.white.withOpacity(0.02), cardColor.withOpacity(0.12), _isExpanded ? 0.6 : 0.0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cardColor.withOpacity(_isExpanded ? 0.4 : 0.1),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── MINIMALIST HEADER ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        // Small indicator dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cardColor.withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Term name
                        Expanded(
                          child: Text(
                            widget.finding.term.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Rotating Minimalist Chevron
                        RotationTransition(
                          turns: _chevronRotation,
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: Colors.white38,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── EXPANDED REVEAL ─────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pure Line Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Divider(
                                  color: Colors.white.withOpacity(0.05),
                                  height: 1,
                                  thickness: 1,
                                ),
                              ),
                              // Description
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                                child: Text(
                                  widget.finding.description,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.white60,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}

class _CinematicActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color baseColor;

  const _CinematicActionButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.baseColor,
  });

  @override
  State<_CinematicActionButton> createState() => _CinematicActionButtonState();
}

class _CinematicActionButtonState extends State<_CinematicActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
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
    const Color deepNavy = Color(0xFF001226);
    const Color electricCyan = Color(0xFF00E5FF);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) => Container(
            height: 52, // Leaner 52px profile
            decoration: BoxDecoration(
              color: Colors.black, // Stadium Shell
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                // Minimal depth shadow (zero light spill)
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.5), // Precise outer shell
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: deepNavy,
              ),
              child: Stack(
                children: [
                  // THE INTERNAL DIFFUSION (Scattered light within borders)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0),
                          radius: 2.2, // wide scattering
                          colors: [
                            electricCyan.withOpacity(0.35 * _glowAnimation.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // SUBTLE RIM HIGHLIGHT
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800, // Balanced weight
                              fontSize: 14.5, // Refined proportional size
                              letterSpacing: 0.8, // Elite readability
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
