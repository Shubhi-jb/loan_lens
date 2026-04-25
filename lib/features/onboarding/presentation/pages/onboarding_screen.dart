import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:loan_lens/core/constants/language_constants.dart';
import 'package:loan_lens/core/services/hive_service.dart';
import 'package:loan_lens/features/home/presentation/pages/home_screen.dart';
import 'package:loan_lens/core/theme/app_theme.dart';
import 'package:loan_lens/features/voice/logic/language_provider.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final selectedLang = languageProvider.selectedLanguage;

    final List<String> backgroundImages = [
      'assets/images/onboarding_language.png',
      'assets/images/onboarding_guardian.png',
      'assets/images/onboarding_analysis.png',
      'assets/images/onboarding_safety.png',
    ];

    final List<Widget> slides = [
      _buildLanguageSlide(context, languageProvider),
      _buildContentSlide(
        context,
        title: selectedLang.str('onboarding_title_1'),
        subtitle: selectedLang.str('onboarding_subtitle_1'),
      ),
      _buildContentSlide(
        context,
        title: selectedLang.str('onboarding_title_2'),
        subtitle: selectedLang.str('onboarding_subtitle_2'),
      ),
      _buildContentSlide(
        context,
        title: selectedLang.str('onboarding_title_3'),
        subtitle: selectedLang.str('onboarding_subtitle_3'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image with Animated Switcher and Opacity for better contrast
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Opacity(
              opacity: 0.75, // Dims the image slightly
              child: Image.asset(
                backgroundImages[_currentPage],
                key: ValueKey<int>(_currentPage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          
          // Cinematic Backdrop Diffusion (Blur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Cinematic Dark Gradient Overlay (Deepened for contrast)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.7, 1.0],
                  colors: [
                    Colors.black87,
                    Colors.black45, // Deepened from black26 for contrast
                    Colors.black87, // Deepened from black54 for contrast
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: slides,
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                child: Column(
                  children: [
                    // Premium Dot Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppTheme.googleBlue
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Action Buttons
                    _buildActionButton(context, selectedLang),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, LanguageModel selectedLang) {
    if (_currentPage == 0) return const SizedBox(height: 70);

    final bool isLastPage = _currentPage == 3;

    return Row(
      children: [
        if (!isLastPage)
          TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              selectedLang.str('onboarding_skip_button'),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
          ),
        if (!isLastPage) const Spacer(),
        
        // Use Expanded only on the last page to fill width safely
        isLastPage 
          ? Expanded(child: _buildPillButton(selectedLang, true))
          : _buildPillButton(selectedLang, false),
      ],
    );
  }

  Widget _buildPillButton(LanguageModel selectedLang, bool isFullWidth) {
    final bool isLastPage = _currentPage == 3;
    
    return GestureDetector(
      onTap: isLastPage ? _completeOnboarding : () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      },
      child: Container(
        height: 70,
        width: isFullWidth ? null : 180,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.googleBlue,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppTheme.googleBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: isLastPage ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.white, size: 28),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isLastPage 
                    ? selectedLang.str('onboarding_start_button').toUpperCase()
                    : selectedLang.str('onboarding_next_button'),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),

            if (isLastPage)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.double_arrow_rounded, color: Colors.white, size: 28),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSlide(BuildContext context, LanguageProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Text(
            provider.selectedLanguage.str('choose_language'),
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              shadows: [
                const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            provider.selectedLanguage.nativeName,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              shadows: [
                const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: LanguageConstants.supportedLanguages.length,
              itemBuilder: (context, index) {
                final lang = LanguageConstants.supportedLanguages[index];
                final isSelected = provider.selectedLanguage.locale == lang.locale;

                return InkWell(
                  onTap: () {
                    provider.setLanguage(lang);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_pageController.hasClients) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.googleBlue.withOpacity(0.2) 
                          : Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.googleBlue 
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            lang.nativeName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.name,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSlide(BuildContext context, {required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
              shadows: [
                const Shadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 4)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 20,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
              fontWeight: FontWeight.w400,
              shadows: [
                const Shadow(color: Colors.black, blurRadius: 25, offset: Offset(0, 4)),
              ],
            ),
          ),
          const SizedBox(height: 120), // Leave space for the bottom UI
        ],
      ),
    );
  }

  void _completeOnboarding() async {
    await HiveService.saveSetting('onboarding_seen', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }
}
