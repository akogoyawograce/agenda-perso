import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime selectedDate;
  const EventFormScreen({super.key, required this.selectedDate});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();

  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _endTime   = const TimeOfDay(hour: 9,  minute: 0);
  String    _color     = '#1A73E8';
  List<int> _reminders = [];
  bool      _loading   = false;
  String    _error     = '';

  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': '5 min',  'value': 5   },
    {'label': '15 min', 'value': 15  },
    {'label': '1h',     'value': 60  },
    {'label': '1 jour', 'value': 1440},
  ];

  final List<String> _colorOptions = [
    '#1A73E8', '#E8711A', '#0F966E',
    '#E8001A', '#9C27B0', '#FF9800',
  ];

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else         _endTime   = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) {
      setState(() => _error = 'Le titre est requis');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    try {
      final startAt = DateTime(
        _date.year, _date.month, _date.day,
        _startTime.hour, _startTime.minute,
      );
      final endAt = DateTime(
        _date.year, _date.month, _date.day,
        _endTime.hour, _endTime.minute,
      );

      await ApiService.createEvent({
        'title':       _titleCtrl.text,
        'description': _descCtrl.text,
        'location':    _locationCtrl.text,
        'start_at':    startAt.toUtc().toIso8601String(),
        'end_at':      endAt.toUtc().toIso8601String(),
        'color':       _color,
        'reminders':   _reminders,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Erreur lors de la création');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Nouvel événement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Titre
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Titre *',
                prefixIcon: const Icon(Icons.title),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Date
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.calendar_today,
                color: Color(0xFF1A73E8)),
              title: const Text('Date'),
              subtitle: Text(
                DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_date)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),

            // Heures
            Row(children: [
              Expanded(
                child: ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.access_time,
                    color: Color(0xFF1A73E8)),
                  title: const Text('Début'),
                  subtitle: Text(_startTime.format(context)),
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.access_time_filled,
                    color: Color(0xFF1A73E8)),
                  title: const Text('Fin'),
                  subtitle: Text(_endTime.format(context)),
                  onTap: () => _pickTime(false),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Lieu
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: 'Lieu (optionnel)',
                prefixIcon: const Icon(Icons.location_on),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optionnel)',
                prefixIcon: const Icon(Icons.notes),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Rappels
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.notifications, color: Color(0xFF1A73E8)),
                    SizedBox(width: 8),
                    Text('Rappels', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _reminderOptions.map((r) {
                      final selected = _reminders.contains(r['value']);
                      return FilterChip(
                        label: Text(r['label']),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) _reminders.add(r['value']);
                            else     _reminders.remove(r['value']);
                          });
                        },
                        selectedColor: const Color(0xFF1A73E8).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF1A73E8),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Couleurs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.palette, color: Color(0xFF1A73E8)),
                    SizedBox(width: 8),
                    Text('Couleur', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    children: _colorOptions.map((c) {
                      final selected = _color == c;
                      final col = Color(int.parse(c.replaceAll('#','0xFF')));
                      return GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.black : Colors.transparent,
                              width: 3),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Résumé
            if (_titleCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1A73E8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_titleCtrl.text} — '
                      '${DateFormat('d MMM', 'fr_FR').format(_date)} '
                      'à ${_startTime.format(context)}'
                      '${_locationCtrl.text.isNotEmpty ? ' • ${_locationCtrl.text}' : ''}',
                      style: const TextStyle(color: Color(0xFF1A73E8)),
                    ),
                  ),
                ]),
              ),
            ],

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Créer l\'événement',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}