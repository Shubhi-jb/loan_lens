import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loan_lens/features/voice/logic/voice_provider.dart';
import 'package:loan_lens/features/voice/logic/language_provider.dart';
import 'package:loan_lens/features/voice/presentation/widgets/siri_wave_visualizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loan_lens/core/theme/app_theme.dart';

class VoiceRecordingSheet extends StatefulWidget {
  const VoiceRecordingSheet({super.key});

  @override
  State<VoiceRecordingSheet> createState() => _VoiceRecordingSheetState();
}

class _VoiceRecordingSheetState extends State<VoiceRecordingSheet> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Auto-start recording when sheet opens
    Future.microtask(() {
      if (!mounted) return;
      final lang = context.read<LanguageProvider>().selectedLanguage;
      context.read<VoiceProvider>().startRecording(lang.locale);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom), // Includes Navigation Bar safe area
          decoration: BoxDecoration(
            color: const Color(0xFF070707), // Pitch black background
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // Slightly sharper curve
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Transcription Display (Unboxed, pure text)
              Container(
                constraints: const BoxConstraints(minHeight: 80), // Prevent UI jitter
                alignment: Alignment.center,
                child: Text(
                  provider.lastWords.isEmpty 
                      ? context.read<LanguageProvider>().selectedLanguage.str('speak_now') 
                      : provider.lastWords,
                  style: GoogleFonts.outfit(
                    fontSize: provider.lastWords.isEmpty ? 18 : 22,
                    fontWeight: provider.lastWords.isEmpty ? FontWeight.w300 : FontWeight.w500,
                    color: provider.lastWords.isEmpty ? Colors.white38 : Colors.white,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              // Compact Cinematic Waveform
              SizedBox(
                height: 70, // Slimmer profile to save space
                width: double.infinity,
                child: SiriWaveVisualizer(soundLevel: provider.soundLevel),
              ),
              const SizedBox(height: 24),
              // Minimalist Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      provider.stopRecording();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      context.read<LanguageProvider>().selectedLanguage.str('cancel'), 
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      provider.stopRecording();
                      Navigator.pop(context, provider.lastWords);
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      context.read<LanguageProvider>().selectedLanguage.str('finish'), 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF651FFF).withOpacity(0.15), // Deep Violet Core
                      foregroundColor: const Color(0xFF00E5FF), // Electric Cyan text/icon
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: BorderSide(color: const Color(0xFF651FFF).withOpacity(0.4), width: 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
