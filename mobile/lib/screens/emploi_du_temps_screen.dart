import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';

class EmploiDuTempsScreen extends StatefulWidget {
  const EmploiDuTempsScreen({super.key});

  @override
  State<EmploiDuTempsScreen> createState() => _EmploiDuTempsScreenState();
}

class _EmploiDuTempsScreenState extends State<EmploiDuTempsScreen> {
  DateTime _weekStart = _getWeekStart(DateTime.now());
  List<dynamic> _events = [];
  bool _loading = false;

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> get _weekDays =>
    List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  final List<int> _hours = List.generate(14, (i) => i + 7);

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getEvents(_weekStart.year, _weekStart.month);
      setState(() => _events = data);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _getEventsAt(DateTime day, int hour) {
    return _events.where((e) {
      final d = DateTime.parse(e['start_at']).toLocal();
      return d.year == day.year &&
             d.month == day.month &&
             d.day == day.day &&
             d.hour == hour;
    }).toList();
  }

  void _prevWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
    _loadEvents();
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Emploi du temps'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (val) async {
              if (val == 'pdf') {
                await ExportService.exportEmploiDuTempsPDF(_events, _weekStart);
              } else if (val == 'excel') {
                await ExportService.exportExcel(_events);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pdf',   child: Text('📄 Export PDF')),
              const PopupMenuItem(value: 'excel', child: Text('📊 Export Excel')),
            ],
          ),
        ],
      ),

      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [

              // Navigation semaine
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _prevWeek,
                    ),
                    Column(
                      children: [
                        Text(
                          'Semaine du ${DateFormat('d MMM yyyy', 'fr_FR').format(_weekStart)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${DateFormat('d MMM', 'fr_FR').format(_weekStart)} → '
                          '${DateFormat('d MMM', 'fr_FR').format(_weekStart.add(const Duration(days: 6)))}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextWeek,
                    ),
                  ],
                ),
              ),

              // Grille
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [

                        // En-tête jours
                        Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              color: Colors.grey[100],
                              child: const Center(
                                child: Text('H', style: TextStyle(
                                  fontSize: 11, color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                )),
                              ),
                            ),
                            ..._weekDays.map((day) {
                              final isToday = DateFormat('yyyy-MM-dd').format(day) ==
                                              DateFormat('yyyy-MM-dd').format(DateTime.now());
                              return Container(
                                width: 110, height: 50,
                                decoration: BoxDecoration(
                                  color: isToday
                                    ? const Color(0xFF1A73E8)
                                    : Colors.grey[50],
                                  border: const Border(
                                    right: BorderSide(color: Color(0xFFE5E7EB)),
                                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('EEE', 'fr_FR').format(day).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.bold,
                                        color: isToday ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      day.day.toString(),
                                      style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold,
                                        color: isToday ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),

                        // Lignes horaires
                        ..._hours.map((hour) => Row(
                          children: [
                            Container(
                              width: 50, height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: const Border(
                                  right: BorderSide(color: Color(0xFFE5E7EB)),
                                  bottom: BorderSide(color: Color(0xFFF3F4F6)),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${hour.toString().padLeft(2,'0')}h',
                                  style: const TextStyle(
                                    fontSize: 11, color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            ..._weekDays.map((day) {
                              final dayEvents = _getEventsAt(day, hour);
                              return GestureDetector(
                                onTap: () => _openAddEvent(day, hour),
                                child: Container(
                                  width: 110, height: 60,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Color(0xFFE5E7EB)),
                                      bottom: BorderSide(color: Color(0xFFF3F4F6)),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: dayEvents.map((e) {
                                      final color = e['color'] != null
                                        ? Color(int.parse(e['color'].replaceAll('#', '0xFF')))
                                        : const Color(0xFF1A73E8);
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          e['title'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 9, color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _openAddEvent(DateTime day, int hour) {
    final titleCtrl = TextEditingController();
    final locCtrl   = TextEditingController();
    TimeOfDay startTime = TimeOfDay(hour: hour, minute: 0);
    TimeOfDay endTime   = TimeOfDay(hour: hour + 1, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvel événement — ${DateFormat('EEEE d MMMM', 'fr_FR').format(day)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ListTile(
                    tileColor: const Color(0xFFF0F4FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text('Début', style: TextStyle(fontSize: 13)),
                    subtitle: Text(startTime.format(ctx)),
                    onTap: () async {
                      final t = await showTimePicker(context: ctx, initialTime: startTime);
                      if (t != null) setModalState(() => startTime = t);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    tileColor: const Color(0xFFF0F4FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: const Text('Fin', style: TextStyle(fontSize: 13)),
                    subtitle: Text(endTime.format(ctx)),
                    onTap: () async {
                      final t = await showTimePicker(context: ctx, initialTime: endTime);
                      if (t != null) setModalState(() => endTime = t);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: InputDecoration(
                  labelText: 'Lieu (optionnel)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty) return;
                    final startAt = DateTime(
                      day.year, day.month, day.day,
                      startTime.hour, startTime.minute,
                    );
                    final endAt = DateTime(
                      day.year, day.month, day.day,
                      endTime.hour, endTime.minute,
                    );
                    await ApiService.createEvent({
                      'title':    titleCtrl.text,
                      'location': locCtrl.text,
                      'start_at': startAt.toUtc().toIso8601String(),
                      'end_at':   endAt.toUtc().toIso8601String(),
                      'color':    '#1A73E8',
                      'reminders': [],
                    });
                    if (mounted) Navigator.pop(ctx);
                    _loadEvents();
                  },
                  child: const Text('Créer', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}