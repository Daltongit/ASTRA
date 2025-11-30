import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Map<String, dynamic>> _scheduled = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduled();
  }

  Future<void> _loadScheduled() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final res = await Supabase.instance.client
          .from('scheduled_sessions')
          .select()
          .eq('user_id', user.id)
          .order('scheduled_at', ascending: true);

      if (!mounted) return;

      setState(() {
        _scheduled = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading scheduled: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _createScheduledOnServer(DateTime scheduledAt) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    await Supabase.instance.client.from('scheduled_sessions').insert({
      'user_id': user.id,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': 30,
    });
    return true;
  }

  Future<void> _addScheduled() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: now,
    );
    if (selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (selectedTime == null) return;

    final scheduledAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final ok = await _createScheduledOnServer(scheduledAt);
    if (!ok || !mounted) return;

    _showSnack('Sesión programada');
    _loadScheduled();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDateTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final date = DateFormat('dd/MM/yyyy').format(dt);
    final time = DateFormat('HH:mm').format(dt);
    return '$date • $time';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Sesiones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadScheduled,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addScheduled,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Programar sesión'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scheduled.isEmpty
              ? Center(
                  child: Text(
                    'No tienes sesiones programadas.\nToca el botón para añadir una.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scheduled.length,
                  itemBuilder: (context, index) {
                    final item = _scheduled[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.event_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          item['title'] ?? 'Sesión con ASTRA',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(_formatDateTime(item['scheduled_at'])),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(item['status'] ?? 'upcoming'),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (item['status'] ?? 'upcoming') == 'upcoming'
                                ? 'Próxima'
                                : (item['status'] ?? '').toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
