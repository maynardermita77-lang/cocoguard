import 'package:flutter/material.dart';
import 'survey_result_screen.dart';
import '../services/api_endpoints.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // Store selected answer index for each question (null = unanswered)
  final Map<int, int> _answers = {};

  static const List<Map<String, dynamic>> _questions = [
    {
      'question':
          'Question 1: Which part of the coconut plant is primarily affected?',
      'options': [
        'A. The unopened spear leaf and young folded leaves',
        'B. The trunk or crown with holes and internal damage',
        'C. Mature leaves showing heavy defoliation or eaten leaf surfaces',
        'D. The crown with V-shaped cuts or bore holes on emerging fronds',
      ],
    },
    {
      'question':
          'Question 2: Where is the pest or its activity usually noticed?',
      'options': [
        'A. Inside tightly folded leaflets, hidden from direct view',
        'B. Inside the trunk or crown, often detected indirectly',
        'C. On the surface of leaves or hanging cocoons on fronds',
        'D. Around the crown area, especially near leaf axils',
      ],
    },
    {
      'question': 'Question 3: What type of damage is most visible?',
      'options': [
        'A. Browning, scorched-looking leaflets that fail to open properly',
        'B. Holes, oozing sap, frass, or unusual sounds inside the trunk',
        'C. Leaves eaten extensively, sometimes leaving only veins',
        'D. V-shaped cuts and chewed tissue on newly opened fronds',
      ],
    },
    {
      'question':
          'Question 4: At what stage or condition is the damage most noticeable?',
      'options': [
        'A. When new leaves emerge but remain deformed or dried',
        'B. When the palm suddenly wilts or collapses despite no leaf damage',
        'C. When caterpillars or cocoons are visible on leaves',
        'D. When young palms show crown damage soon after beetle attack',
      ],
    },
    {
      'question':
          'Question 5: Which description best matches what you observe?',
      'options': [
        'A. Damage is hidden at first and becomes obvious only when leaves open',
        'B. The palm shows internal damage with little early external warning',
        'C. Defoliation is rapid and obvious, especially on young palms',
        'D. Damage appears as clean cuts and holes caused by a strong adult insect',
      ],
    },
  ];

  bool get _allAnswered => _answers.length == _questions.length;

  /// Determine pest based on majority answer pattern.
  /// A=Brontispa, B=APW, C=Slug Caterpillar, D=Rhinoceros Beetle
  Map<String, dynamic> _determinePest() {
    final pestMap = {
      0: 'Brontispa',
      1: 'APW',
      2: 'Slug Caterpillar',
      3: 'Rhinoceros Beetle',
    };

    // Count how many times each pest was selected
    final counts = <String, int>{
      'Brontispa': 0,
      'APW': 0,
      'Slug Caterpillar': 0,
      'Rhinoceros Beetle': 0,
    };

    for (final answer in _answers.values) {
      final pest = pestMap[answer];
      if (pest != null) {
        counts[pest] = (counts[pest] ?? 0) + 1;
      }
    }

    // Find pest with highest count
    String topPest = 'Brontispa';
    int topCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > topCount) {
        topCount = entry.value;
        topPest = entry.key;
      }
    }

    return {'pest': topPest, 'counts': counts};
  }

  String _getScientificName(String pest) {
    const names = {
      'APW': 'Rhynchophorus ferrugineus',
      'Brontispa': 'Brontispa longissima',
      'Rhinoceros Beetle': 'Oryctes rhinoceros',
      'Slug Caterpillar': 'Parasa lepida',
    };
    return names[pest] ?? '';
  }

  String _getRiskLevel(String pest) {
    const risks = {
      'APW': 'critical',
      'Brontispa': 'high',
      'Rhinoceros Beetle': 'critical',
      'Slug Caterpillar': 'medium',
    };
    return risks[pest] ?? 'medium';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pest Identification Survey',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Coconut Pest Assessment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Answer each question by selecting the option that best describes the damage or pest activity you observed.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              // Progress indicator
              Text(
                '${_answers.length} of ${_questions.length} answered',
                style: TextStyle(
                  fontSize: 13,
                  color: _allAnswered
                      ? const Color(0xFF2d7a3e)
                      : Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _answers.length / _questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2d7a3e),
                ),
              ),
              const SizedBox(height: 24),

              // Questions
              for (int qi = 0; qi < _questions.length; qi++) ...[
                _buildQuestionCard(qi),
                const SizedBox(height: 20),
              ],

              // Submit Button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allAnswered
                        ? const Color(0xFF1b5e20)
                        : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _allAnswered
                      ? () {
                          final result = _determinePest();
                          final pest = result['pest'] as String;
                          final counts = result['counts'] as Map<String, int>;

                          // Save survey result to backend (non-blocking)
                          ScansApi.saveSurveyResult(
                                pestType: pest,
                                answerCounts: counts,
                              )
                              .then((_) {
                                debugPrint('Survey result saved to backend');
                              })
                              .catchError((e) {
                                debugPrint('Failed to save survey result: $e');
                              });

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SurveyResultScreen(
                                identifiedPest: pest,
                                scientificName: _getScientificName(pest),
                                riskLevel: _getRiskLevel(pest),
                                answerCounts: counts,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text(
                    'Submit Survey',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final q = _questions[questionIndex];
    final questionText = q['question'] as String;
    final options = q['options'] as List<String>;
    final selectedOption = _answers[questionIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedOption != null
              ? const Color(0xFF2d7a3e).withValues(alpha: 0.4)
              : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          for (int oi = 0; oi < options.length; oi++)
            _buildOptionTile(questionIndex, oi, options[oi]),
        ],
      ),
    );
  }

  Widget _buildOptionTile(int questionIndex, int optionIndex, String text) {
    final isSelected = _answers[questionIndex] == optionIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _answers[questionIndex] = optionIndex;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2d7a3e).withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2d7a3e) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF2d7a3e)
                  : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.black87 : Colors.black54,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
