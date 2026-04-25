import 'package:flutter/material.dart';
import 'package:loan_lens/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CinematicRiskGauge extends StatelessWidget {
  final double score; // 0.0 (Danger) to 1.0 (Safe)
  final Color scoreColor;
  final String fairnessLabel;
  final String safeLabel;
  final String modLabel;
  final String dangerLabel;

  const CinematicRiskGauge({
    super.key,
    required this.score,
    required this.scoreColor,
    required this.fairnessLabel,
    required this.safeLabel,
    required this.modLabel,
    required this.dangerLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Determine Verdict Label based on score (0.0=Danger, 1.0=Safe)
    final String verdictLabel = score >= 0.8 
        ? safeLabel 
        : score >= 0.5 
            ? modLabel 
            : dangerLabel;

    return Container(
      // Compact container with minimal padding
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score and fairness header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                fairnessLabel,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                ),
              ),
              Text(
                (score * 10).toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal Bar System
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final markerPosition = barWidth * score.clamp(0.0, 1.0);
              
              return Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  // Gradient Score Bar
                  Container(
                    height: 6,
                    width: barWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.googleRed,
                          AppTheme.googleYellow,
                          AppTheme.googleGreen,
                        ],
                      ),
                    ),
                  ),
                  // Dot Marker with Glow
                  Positioned(
                    left: markerPosition - 9,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: scoreColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Direct Verdict Label (Sentence Case & Clean)
          Container(
            width: double.infinity,
            alignment: Alignment.centerLeft,
            child: Text(
              verdictLabel,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
