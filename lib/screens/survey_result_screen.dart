import 'package:flutter/material.dart';
import '../data/management_strategies.dart';
import 'management_strategies_screen.dart';

/// Screen shown after the survey questionnaire is submitted.
/// Displays the identified pest based on majority answers and management strategies.
class SurveyResultScreen extends StatelessWidget {
  final String identifiedPest;
  final String scientificName;
  final String riskLevel;
  final Map<String, int> answerCounts; // count per pest choice

  const SurveyResultScreen({
    super.key,
    required this.identifiedPest,
    required this.scientificName,
    required this.riskLevel,
    required this.answerCounts,
  });

  Color _getRiskColor() {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return const Color(0xFFd32f2f);
      case 'high':
        return const Color(0xFFf57c00);
      case 'medium':
        return const Color(0xFFfbc02d);
      case 'low':
        return const Color(0xFF388e3c);
      default:
        return const Color(0xFF1976D2);
    }
  }

  String _getRiskLabel() {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return 'KRITIKAL';
      case 'high':
        return 'MATAAS';
      case 'medium':
        return 'KATAMTAMAN';
      case 'low':
        return 'MABABA';
      default:
        return riskLevel.toUpperCase();
    }
  }

  String _getPestEmoji() {
    final lower = identifiedPest.toLowerCase();
    if (lower.contains('rhinoceros')) return '🪲';
    if (lower.contains('brontispa')) return '🐛';
    if (lower.contains('apw') || lower.contains('weevil')) return '🪲';
    if (lower.contains('slug') || lower.contains('caterpillar')) return '🐛';
    return '🪲';
  }

  @override
  Widget build(BuildContext context) {
    final info = getManagementInfo(identifiedPest);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1b5e20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          'Resulta ng Survey',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Result Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1b5e20), Color(0xFF388e3c)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Survey badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          color: Colors.white70,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Survey-Based Identification',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pest name
                  Row(
                    children: [
                      Text(
                        _getPestEmoji(),
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              identifiedPest,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (scientificName.isNotEmpty)
                              Text(
                                scientificName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Risk badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRiskColor(),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Risk Level: ${_getRiskLabel()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Answer breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.bar_chart,
                          color: Color(0xFF1b5e20),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Damage Pattern Analysis',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1b5e20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...answerCounts.entries.map((entry) {
                      final isWinner = entry.key == identifiedPest;
                      final total = answerCounts.values.fold(
                        0,
                        (a, b) => a + b,
                      );
                      final percentage = total > 0
                          ? (entry.value / total * 100)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isWinner
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isWinner
                                        ? const Color(0xFF1b5e20)
                                        : Colors.black54,
                                  ),
                                ),
                                Text(
                                  '${entry.value}/5 (${percentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isWinner
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isWinner
                                        ? const Color(0xFF1b5e20)
                                        : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isWinner
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade400,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick management preview
            if (info != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Quick Recommendations',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Show first strategy from each category
                      for (final strategy in info.strategies) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strategy.icon,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strategy.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF33691E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      strategy.strategies.first,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4E342E),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // View full management strategies
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1b5e20),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManagementStrategiesScreen(
                              pestName: identifiedPest,
                              scientificName: scientificName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.menu_book,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Tingnan ang Buong Gabay sa Pagkontrol',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Take survey again
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Go back to survey
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        'Sagutin Muli ang Survey',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text(
                      'Bumalik sa Home',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
