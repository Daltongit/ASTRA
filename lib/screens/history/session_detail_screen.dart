import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _analysis;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadSessionData() async {
    setState(() => _isLoading = true);

    try {
      final sessionResponse = await Supabase.instance.client
          .from('therapy_sessions')
          .select()
          .eq('id', widget.sessionId)
          .single();

      final analysisResponse = await Supabase.instance.client
          .from('emotion_analysis')
          .select()
          .eq('session_id', widget.sessionId)
          .maybeSingle();

      final recommendationsResponse = await Supabase.instance.client
          .from('recommendations')
          .select()
          .eq('session_id', widget.sessionId)
          .order('priority', ascending: false);

      setState(() {
        _session = sessionResponse;
        if (analysisResponse != null) {
          // Normalizar tipos a double
          analysisResponse['happiness_score'] =
              _toDouble(analysisResponse['happiness_score']);
          analysisResponse['sadness_score'] =
              _toDouble(analysisResponse['sadness_score']);
          analysisResponse['stress_score'] =
              _toDouble(analysisResponse['stress_score']);
          analysisResponse['anxiety_score'] =
              _toDouble(analysisResponse['anxiety_score']);
          analysisResponse['anger_score'] =
              _toDouble(analysisResponse['anger_score']);
        }
        _analysis = analysisResponse;
        _recommendations =
            List<Map<String, dynamic>>.from(recommendationsResponse);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading session data: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getEmotionColor(double score) {
    if (score >= 70) return Colors.red;
    if (score >= 50) return Colors.orange;
    if (score >= 30) return Colors.yellow;
    return Colors.green;
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'activity':
        return Icons.local_activity_rounded;
      case 'mindfulness':
        return Icons.self_improvement_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'physical':
        return Icons.directions_run_rounded;
      case 'creative':
        return Icons.palette_rounded;
      case 'rest':
        return Icons.nightlight_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No se pudo cargar la sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Sesión'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la sesión
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_session!['started_at']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Duración: ${_session!['duration_seconds'] ~/ 60} minutos',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Análisis emocional
            if (_analysis != null) ...[
              const Text(
                'Análisis Emocional',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildEmotionBar(
                        'Felicidad',
                        _toDouble(_analysis!['happiness_score']),
                        Icons.sentiment_very_satisfied_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildEmotionBar(
                        'Tristeza',
                        _toDouble(_analysis!['sadness_score']),
                        Icons.sentiment_dissatisfied_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildEmotionBar(
                        'Estrés',
                        _toDouble(_analysis!['stress_score']),
                        Icons.psychology_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildEmotionBar(
                        'Ansiedad',
                        _toDouble(_analysis!['anxiety_score']),
                        Icons.warning_amber_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildEmotionBar(
                        'Enojo',
                        _toDouble(_analysis!['anger_score']),
                        Icons.sentiment_very_dissatisfied_rounded,
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.assessment_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Estado General',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _analysis!['overall_mood'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Recomendaciones
            if (_recommendations.isNotEmpty) ...[
              const Text(
                'Recomendaciones Personalizadas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final rec = _recommendations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(rec['category']),
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      title: Text(
                        rec['recommendation_text'],
                        style: const TextStyle(fontSize: 15),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'P${rec['priority']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBar(String label, double score, IconData icon) {
    final color = _getEmotionColor(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 12,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
