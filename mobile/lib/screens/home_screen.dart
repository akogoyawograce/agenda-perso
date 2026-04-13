import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../services/alarm_service.dart';
import 'event_form_screen.dart';
import 'emploi_du_temps_screen.dart';
import 'import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay  = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<dynamic> _events = [];
  bool _loading         = false;
  final _storage        = const FlutterSecureStorage();

  // ── Détail / Modification / Suppression ──────────────────────
  Map<String, dynamic>? _selectedEvent;
  bool _showDetail        = false;
  bool _showEdit          = false;
  bool _showDeleteConfirm = false;
  bool _editLoading       = false;
  bool _linkCopied        = false;

  // Champs édition
  final _editTitleCtrl = TextEditingController();
  final _editLocCtrl   = TextEditingController();
  final _editDescCtrl  = TextEditingController();
  DateTime _editDate         = DateTime.now();
  TimeOfDay _editTimeStart   = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _editTimeEnd     = const TimeOfDay(hour: 9, minute: 0);
  String    _editColor       = '#1A73E8';

  final List<String> _colorOptions = [
    '#1A73E8', '#E8711A', '#0F966E',
    '#E8001A', '#9C27B0', '#FF9800',
  ];

  @override
  void initState() {
    super.initState();
    ApiService.init();
    _loadEvents().then((_) {
      AlarmService.startWatcher(_events, (event) {
        if (!mounted) return;
        HapticFeedback.vibrate();
        _showAlarmDialog(event);
      });
    });
    _registerOneSignal();
  }

  @override
  void dispose() {
    AlarmService.stopWatcher();
    _editTitleCtrl.dispose();
    _editLocCtrl.dispose();
    _editDescCtrl.dispose();
    super.dispose();
  }

  void _showAlarmDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('⏰ ', style: TextStyle(fontSize: 28)),
          Expanded(child: Text(
            event['warning'] == true ? 'Dans 5 minutes !' : "C'est l'heure !",
            style: const TextStyle(fontSize: 16),
          )),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                color: Color(0xFF1A73E8))),
            if (event['location'] != null && event['location'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('📍 ${event['location']}',
                style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () { AlarmService.stopAlarm(); Navigator.pop(context); },
            child: const Text("OK, j'ai vu !"),
          ),
        ],
      ),
    );
  }

  Future<void> _registerOneSignal() async {
    if (kIsWeb) return;
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      try { await ApiService.registerPlayerId(playerId); } catch (_) {}
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getEvents(_focusedDay.year, _focusedDay.month);
      setState(() => _events = data);
      AlarmService.updateEvents(_events, (event) {});
    } catch (e) {
      debugPrint('Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events.where((e) {
      final d = DateTime.parse(e['start_at']).toLocal();
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  Future<void> _logout() async {
    AlarmService.stopWatcher();
    await _storage.delete(key: 'token');
    if (mounted) context.go('/login');
  }

  // ── Détail événement ─────────────────────────────────────────
  void _openDetail(Map<String, dynamic> event) {
    setState(() {
      _selectedEvent = event;
      _showDetail    = true;
      _linkCopied    = false;
    });
  }

  // ── Modification ─────────────────────────────────────────────
  void _openEdit(Map<String, dynamic> event) {
    final start = DateTime.parse(event['start_at']).toLocal();
    final end   = event['end_at'] != null
      ? DateTime.parse(event['end_at']).toLocal()
      : start.add(const Duration(hours: 1));

    setState(() {
      _editTitleCtrl.text = event['title'] ?? '';
      _editLocCtrl.text   = event['location'] ?? '';
      _editDescCtrl.text  = event['description'] ?? '';
      _editDate           = start;
      _editTimeStart      = TimeOfDay(hour: start.hour, minute: start.minute);
      _editTimeEnd        = TimeOfDay(hour: end.hour, minute: end.minute);
      _editColor          = event['color'] ?? '#1A73E8';
      _showDetail         = false;
      _showEdit           = true;
    });
  }

  Future<void> _saveEdit() async {
    if (_editTitleCtrl.text.isEmpty) return;
    setState(() => _editLoading = true);
    try {
      final startAt = DateTime(
        _editDate.year, _editDate.month, _editDate.day,
        _editTimeStart.hour, _editTimeStart.minute,
      ).toUtc().toIso8601String();
      final endAt = DateTime(
        _editDate.year, _editDate.month, _editDate.day,
        _editTimeEnd.hour, _editTimeEnd.minute,
      ).toUtc().toIso8601String();

      await ApiService.updateEvent(_selectedEvent!['id'], {
        'title':       _editTitleCtrl.text,
        'location':    _editLocCtrl.text,
        'description': _editDescCtrl.text,
        'color':       _editColor,
        'start_at':    startAt,
        'end_at':      endAt,
      });

      setState(() => _showEdit = false);
      await _loadEvents();
    } catch (e) {
      _showSnack('Erreur lors de la modification');
    } finally {
      setState(() => _editLoading = false);
    }
  }

  // ── Suppression ───────────────────────────────────────────────
  Future<void> _deleteEvent() async {
    try {
      await ApiService.deleteEvent(_selectedEvent!['id']);
      setState(() {
        _showDeleteConfirm = false;
        _showDetail        = false;
        _selectedEvent     = null;
      });
      await _loadEvents();
    } catch (e) {
      _showSnack('Erreur lors de la suppression');
    }
  }

  // ── Partage ───────────────────────────────────────────────────
  String _buildEventText(Map<String, dynamic> event) {
    final start = DateTime.parse(event['start_at']).toLocal();
    final fmt   = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(start);
    String text = '📅 ${event['title']}\n🕐 $fmt';
    if (event['location'] != null && event['location'].toString().isNotEmpty)
      text += '\n📍 ${event['location']}';
    if (event['description'] != null && event['description'].toString().isNotEmpty)
      text += '\n📝 ${event['description']}';
    return text;
  }

  Future<void> _shareWhatsApp(Map<String, dynamic> event) async {
    final text = Uri.encodeComponent(_buildEventText(event));
    final url  = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _addToGoogleCalendar(Map<String, dynamic> event) async {
    final start = DateTime.parse(event['start_at']).toLocal();
    final end   = event['end_at'] != null
      ? DateTime.parse(event['end_at']).toLocal()
      : start.add(const Duration(hours: 1));
    final fmt   = DateFormat('yyyyMMddTHHmmss');
    final title = Uri.encodeComponent(event['title'] ?? '');
    final loc   = Uri.encodeComponent(event['location'] ?? '');
    final desc  = Uri.encodeComponent(event['description'] ?? '');
    final url   = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=$title&dates=${fmt.format(start)}/${fmt.format(end)}'
      '&location=$loc&details=$desc'
    );
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink(Map<String, dynamic> event) async {
    await Clipboard.setData(ClipboardData(text: _buildEventText(event)));
    setState(() => _linkCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(children: [
          Icon(Icons.calendar_month, size: 22),
          SizedBox(width: 8),
          Text('Agenda Personnel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_week),
            tooltip: 'Emploi du temps',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EmploiDuTempsScreen())),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (val) async {
              if (val == 'pdf')   await ExportService.exportPDF(_events, context);
              if (val == 'excel') await ExportService.exportExcel(_events);
              if (val == 'csv')   await ExportService.exportCSV(_events);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pdf',   child: Text('📄 Export PDF')),
              const PopupMenuItem(value: 'excel', child: Text('📊 Export Excel')),
              const PopupMenuItem(value: 'csv',   child: Text('📋 Export CSV')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Importer un lien',
            onPressed: () async {
              final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ImportScreen()));
              if (result == true) _loadEvents();
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),

      body: Stack(
        children: [

          // ── Calendrier + liste ──────────────────────────────
          Column(
            children: [
              Container(
                color: Colors.white,
                child: TableCalendar(
                  locale: 'fr_FR',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  firstDay:  DateTime(2020),
                  lastDay:   DateTime(2030),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((e) {
                            final event = e as Map<String, dynamic>;
                            final color = event['color'] != null
                              ? Color(int.parse(event['color'].replaceAll('#', '0xFF')))
                              : const Color(0xFF1A73E8);
                            return Container(
                              width: 6, height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Color(0xFF93B8F5), shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF1A73E8), shape: BoxShape.circle),
                    markerDecoration: BoxDecoration(
                      color: Color(0xFFE8711A), shape: BoxShape.circle),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onDaySelected: (selected, focused) {
                    setState(() { _selectedDay = selected; _focusedDay = focused; });
                  },
                  onPageChanged: (focused) { _focusedDay = focused; _loadEvents(); },
                ),
              ),

              Expanded(
                child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
                  : _getEventsForDay(_selectedDay).isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_available, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun événement le ${DateFormat('d MMMM', 'fr_FR').format(_selectedDay)}',
                            style: const TextStyle(color: Colors.grey)),
                        ],
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _getEventsForDay(_selectedDay).length,
                        itemBuilder: (ctx, i) {
                          final event = _getEventsForDay(_selectedDay)[i];
                          final start = DateTime.parse(event['start_at']).toLocal();
                          final color = event['color'] != null
                            ? Color(int.parse(event['color'].replaceAll('#', '0xFF')))
                            : const Color(0xFF1A73E8);

                          return GestureDetector(
                            onTap: () => _openDetail(Map<String, dynamic>.from(event)),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                              elevation: 1,
                              child: ListTile(
                                leading: Container(
                                  width: 4, height: 48,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4)),
                                ),
                                title: Text(event['title'],
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  DateFormat('HH:mm', 'fr_FR').format(start) +
                                  (event['location'] != null ? ' • ${event['location']}' : ''),
                                  style: const TextStyle(color: Colors.grey)),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // ── Modal Détail ──────────────────────────────────────
          if (_showDetail && _selectedEvent != null)
            _buildDetailModal(),

          // ── Modal Modification ────────────────────────────────
          if (_showEdit && _selectedEvent != null)
            _buildEditModal(),

          // ── Confirmation suppression ──────────────────────────
          if (_showDeleteConfirm)
            _buildDeleteConfirm(),

        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(context,
            MaterialPageRoute(
              builder: (_) => EventFormScreen(selectedDate: _selectedDay)));
          _loadEvents();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── MODAL DÉTAIL ─────────────────────────────────────────────
  Widget _buildDetailModal() {
    final event = _selectedEvent!;
    final color = event['color'] != null
      ? Color(int.parse(event['color'].replaceAll('#', '0xFF')))
      : const Color(0xFF1A73E8);
    final start = DateTime.parse(event['start_at']).toLocal();
    final end   = event['end_at'] != null
      ? DateTime.parse(event['end_at']).toLocal() : null;

    return _modalBackground(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // En-tête coloré
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(start),
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _showDetail = false),
                  ),
                ],
              ),
            ),

            // Infos
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Heure
                    _infoRow(Icons.access_time, 'Horaire',
                      '${DateFormat('HH:mm').format(start)}'
                      '${end != null ? ' → ${DateFormat('HH:mm').format(end)}' : ''}'),

                    // Lieu
                    if (event['location'] != null && event['location'].toString().isNotEmpty)
                      _infoRow(Icons.location_on, 'Lieu', event['location']),

                    // Description
                    if (event['description'] != null && event['description'].toString().isNotEmpty)
                      _infoRow(Icons.notes, 'Description', event['description']),

                    const Divider(height: 24),

                    // Partage
                    const Text('Partager',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _shareBtn('WhatsApp', Colors.green,
                          Icons.chat, () => _shareWhatsApp(event)),
                        _shareBtn('Google Calendar', const Color(0xFF1A73E8),
                          Icons.calendar_today, () => _addToGoogleCalendar(event)),
                        _shareBtn('Copier', Colors.grey.shade700,
                          Icons.copy, () => _copyLink(event)),
                      ],
                    ),

                    if (_linkCopied) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('Copié dans le presse-papier !',
                            style: TextStyle(color: Colors.green)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _openEdit(event),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => setState(() {
                      _showDetail        = false;
                      _showDeleteConfirm = true;
                    }),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── MODAL MODIFICATION ────────────────────────────────────────
  Widget _buildEditModal() {
    return _modalBackground(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Modifier l\'événement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showEdit = false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _editField('Titre *', _editTitleCtrl),
                    const SizedBox(height: 16),

                    // Date
                    _label('📅 Date'),
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _editDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _editDate = d);
                      },
                      child: _dateTimeBox(
                        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_editDate)),
                    ),
                    const SizedBox(height: 16),

                    // Heures
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('🕐 Début'),
                          GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context, initialTime: _editTimeStart);
                              if (t != null) setState(() => _editTimeStart = t);
                            },
                            child: _dateTimeBox(_editTimeStart.format(context)),
                          ),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('🕑 Fin'),
                          GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context, initialTime: _editTimeEnd);
                              if (t != null) setState(() => _editTimeEnd = t);
                            },
                            child: _dateTimeBox(_editTimeEnd.format(context)),
                          ),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 16),

                    _editField('📍 Lieu (optionnel)', _editLocCtrl),
                    const SizedBox(height: 16),
                    _editField('Description (optionnel)', _editDescCtrl, maxLines: 3),
                    const SizedBox(height: 16),

                    // Couleur
                    _label('🎨 Couleur'),
                    const SizedBox(height: 8),
                    Row(
                      children: _colorOptions.map((c) {
                        final col = Color(int.parse(c.replaceAll('#', '0xFF')));
                        return GestureDetector(
                          onTap: () => setState(() => _editColor = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _editColor == c ? Colors.black : Colors.transparent,
                                width: 3),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showEdit = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _editLoading ? null : _saveEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _editLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                      : const Text('✅ Sauvegarder',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── CONFIRMATION SUPPRESSION ──────────────────────────────────
  Widget _buildDeleteConfirm() {
    return _modalBackground(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗑', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Supprimer l\'événement ?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '"${_selectedEvent?['title']}" sera définitivement supprimé.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showDeleteConfirm = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _deleteEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Supprimer'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────
  Widget _modalBackground({required Widget child}) {
    return GestureDetector(
      onTap: () => setState(() {
        _showDetail = false;
        _showEdit   = false;
        _showDeleteConfirm = false;
      }),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1A73E8), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _shareBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 13, color: Colors.grey));

  Widget _dateTimeBox(String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(value, style: const TextStyle(fontSize: 14)),
  );
}