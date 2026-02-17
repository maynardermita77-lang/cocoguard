import 'package:flutter/material.dart';
import '../data/management_strategies.dart';

/// Screen that displays management strategies for a specific pest.
/// Can be navigated to from ResultsScreen's "Gabay sa Pagkontrol" button
/// or from the SurveyResultScreen.
class ManagementStrategiesScreen extends StatelessWidget {
  final String pestName;
  final String? scientificName;

  const ManagementStrategiesScreen({
    super.key,
    required this.pestName,
    this.scientificName,
  });

  @override
  Widget build(BuildContext context) {
    final info = getManagementInfo(pestName);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1b5e20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gabay sa Pagkontrol',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: info == null
          ? _buildNoDataView()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  _buildHeaderCard(info),
                  const SizedBox(height: 16),
                  // Strategy sections
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Management Strategies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1b5e20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Source: Nature Damage of Coconut Pests – PDF (${info.referencePages})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (int i = 0; i < info.strategies.length; i++) ...[
                          _buildStrategyCard(info.strategies[i], i),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Disclaimer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCC80)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFE65100),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kumunsulta sa Philippine Coconut Authority (PCA) bago gumamit ng anumang chemical treatment. Ang mga rekomendasyon dito ay batay sa PCA reference materials.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4E342E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(PestManagementInfo info) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1b5e20), Color(0xFF2e7d32)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🪲 Pest Identified',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pestName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (scientificName != null && scientificName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              scientificName!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            info.referencePages.isNotEmpty
                ? 'Reference: ${info.referencePages}'
                : '',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(ManagementStrategy strategy, int index) {
    final colors = [
      const Color(0xFFE8F5E9), // Cultural - light green
      const Color(0xFFE3F2FD), // Mechanical - light blue
      const Color(0xFFFCE4EC), // Biological - light pink
      const Color(0xFFFFF8E1), // Chemical - light yellow
    ];
    final borderColors = [
      const Color(0xFF81C784),
      const Color(0xFF64B5F6),
      const Color(0xFFF48FB1),
      const Color(0xFFFFD54F),
    ];
    final headerColors = [
      const Color(0xFF2E7D32),
      const Color(0xFF1565C0),
      const Color(0xFFC62828),
      const Color(0xFFF57F17),
    ];

    final colorIdx = index % colors.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors[colorIdx],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColors[colorIdx]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: borderColors[colorIdx].withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Text(strategy.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  strategy.category,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: headerColors[colorIdx],
                  ),
                ),
              ],
            ),
          ),
          // Strategy items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: strategy.strategies.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: headerColors[colorIdx],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Walang management strategies na available para sa pest na ito.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Kumunsulta sa PCA para sa karagdagang impormasyon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
