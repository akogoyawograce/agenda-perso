import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _urlCtrl      = TextEditingController();
  List<dynamic> _preview = [];
  bool  _loading      = false;
  String _error       = '';

  Future<void> _preview_events() async {
    if (_urlCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = ''; _preview = []; });
    try {
      final data = await ApiService.importPreview(_urlCtrl.text);
      setState(() => _preview = data);
    } catch (e) {
      setState(() => _error = "Impossible de lire ce lien. Vérifie qu'il s'agit d'un lien iCal valide.");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _importAll() async {
    setState(() => _loading = true);
    try {
      for (final event in _preview) {
        await ApiService.createEvent(event);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_preview.length} événement(s) importé(s) !')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = "Erreur lors de l'import");
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
        title: const Text('Importer depuis un lien'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFC078)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comment obtenir un lien iCal ?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('• Google Calendar → Paramètres → Exporter → Copier le lien',
                    style: TextStyle(fontSize: 13)),
                  Text('• Outlook → Partager → Publier → Copier le lien .ics',
                    style: TextStyle(fontSize: 13)),
                  Text('• Tout lien se terminant par .ics fonctionne',
                    style: TextStyle(fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: 'Colle le lien iCal ici',
                hintText: 'https://... ou webcal://...',
                prefixIcon: const Icon(Icons.link),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
              ),

            const SizedBox(height: 12),

            if (_preview.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: Text(_loading ? 'Chargement...' : 'Prévisualiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8711A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _preview_events,
                ),
              ),

            if (_preview.isNotEmpty) ...[
              Text(
                '${_preview.length} événement(s) trouvé(s) :',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ..._preview.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1A73E8),
                    child: Icon(Icons.event, color: Colors.white, size: 18),
                  ),
                  title: Text(e['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${e['date'] ?? ''} à ${e['time'] ?? ''}'
                    '${e['location'] != null && e['location'].isNotEmpty ? ' • ${e['location']}' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_done),
                  label: Text(_loading
                    ? 'Import en cours...'
                    : 'Importer les ${_preview.length} événements'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _importAll,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}