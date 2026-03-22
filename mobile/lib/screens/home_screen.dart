import 'package:flutter/foundation.dart';   
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../services/api_service.dart';
import 'event_form_screen.dart';

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

  @override
  void initState() {
    super.initState();
    ApiService.init();
    _loadEvents();
    _registerOneSignal();
  }

 Future<void> _registerOneSignal() async {
  if (kIsWeb) return; // Ignorer sur web
  final playerId = OneSignal.User.pushSubscription.id;
  if (playerId != null) {
    try { await ApiService.registerPlayerId(playerId); } catch (_) {}
  }
}

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getEvents(
        _focusedDay.year, _focusedDay.month);
      setState(() => _events = data);
    } catch (e) {
      debugPrint('Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events.where((e) {
      final d = DateTime.parse(e['start_at']).toLocal();
      return d.year == day.year &&
             d.month == day.month &&
             d.day == day.day;
    }).toList();
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'token');
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final eventsToday = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Icon(Icons.calendar_month, size: 22),
          SizedBox(width: 8),
          Text('Agenda Personnel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      body: Column(
        children: [
          // Calendrier
          Container(
            color: Colors.white,
            child: TableCalendar(
              locale: 'fr_FR',
              firstDay:  DateTime(2020),
              lastDay:   DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFF93B8F5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF1A73E8),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Color(0xFFE8711A),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay  = focused;
                });
              },
              onPageChanged: (focused) {
                _focusedDay = focused;
                _loadEvents();
              },
            ),
          ),

          // Liste événements du jour sélectionné
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : eventsToday.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available,
                          size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun événement le '
                          '${DateFormat('d MMMM', 'fr_FR').format(_selectedDay)}',
                          style: const TextStyle(color: Colors.grey)),
                      ],
                    ))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: eventsToday.length,
                    itemBuilder: (ctx, i) {
                      final event = eventsToday[i];
                      final start =
                        DateTime.parse(event['start_at']).toLocal();
                      final color = event['color'] != null
                        ? Color(int.parse(
                            event['color'].replaceAll('#', '0xFF')))
                        : const Color(0xFF1A73E8);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            width: 4, height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2)),
                          ),
                          title: Text(event['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            DateFormat('HH:mm', 'fr_FR').format(start) +
                            (event['location'] != null
                              ? ' • ${event['location']}' : ''),
                            style: const TextStyle(color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                            onPressed: () async {
                              await ApiService.deleteEvent(event['id']);
                              _loadEvents();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(context,
            MaterialPageRoute(
              builder: (_) =>
                EventFormScreen(selectedDate: _selectedDay)));
          _loadEvents();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}