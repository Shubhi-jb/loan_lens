import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:loan_lens/features/voice/logic/language_provider.dart';
import 'package:intl/intl.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedLang = context.watch<LanguageProvider>().selectedLanguage;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(selectedLang.str('history_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: kIsWeb 
          ? _buildWebOptimizationMessage(context, theme, selectedLang)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('scans')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_moon_rounded,
                        size: 80,
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      selectedLang.str('history_empty_title'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedLang.str('history_empty_body'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.add_moderator_rounded),
                      label: Text(selectedLang.str('history_start_audit')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              final String appName = data['appName'] ?? selectedLang.str('history_unknown_app');
              final String biasType = data['bias_type'] ?? 'Unknown Bias';
              final String deviation = data['interest_rate_deviation'] ?? 'N/A';
              final int riskScore = data['risk_score'] ?? 0;
              final Timestamp? timestamp = data['timestamp'] as Timestamp?;
              
              final bool isDanger = riskScore <= 4;
              final Color scoreColor = isDanger 
                  ? (isDark ? Colors.red.shade400 : Colors.red.shade600)
                  : (riskScore >= 8 
                      ? (isDark ? Colors.green.shade400 : Colors.green.shade600)
                      : (isDark ? Colors.orange.shade400 : Colors.orange.shade600));

              String dateStr = selectedLang.str('history_unknown_date');
              if (timestamp != null) {
                dateStr = DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate());
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                color: isDark ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3) : Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              appName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${selectedLang.str('history_score_prefix')} $riskScore/10',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMetricRow(Icons.category_rounded, selectedLang.str('history_bias'), biasType, isDanger ? scoreColor : theme.colorScheme.onSurface),
                      const SizedBox(height: 8),
                      _buildMetricRow(Icons.trending_up_rounded, selectedLang.str('history_deviation'), deviation, theme.colorScheme.onSurface),
                      const SizedBox(height: 16),
                      Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWebOptimizationMessage(BuildContext context, ThemeData theme, dynamic selectedLang) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.devices_other_rounded,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Mobile-First Experience",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Cloud History is currently optimized for the LoanLens mobile build. To sync and view your audit history across devices, please use our Android or iOS application.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text("Back to Audit"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
