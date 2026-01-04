import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PartsOfSpeechScreen extends StatefulWidget {
  const PartsOfSpeechScreen({super.key});
  @override
  State<PartsOfSpeechScreen> createState() => _PartsOfSpeechScreenState();
}

class _PartsOfSpeechScreenState extends State<PartsOfSpeechScreen> {
  final _ctrl = TextEditingController();
  Map<String, dynamic>? _data;
  bool _loading = false;
  
  void _checkPOS() async {
    setState(() => _loading = true);
    final res = await ApiService.fetchPartOfSpeech(_ctrl.text);
    setState(() { _data = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: _ctrl, decoration: const InputDecoration(labelText: "Enter a word (e.g. Run)", suffixIcon: Icon(Icons.search), border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _checkPOS, child: const Text("Identify Part of Speech")),
          const SizedBox(height: 20),
          if (_loading) const CircularProgressIndicator(),
          if (_data != null)
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                title: Text(_data!['word'].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: (_data!['types'] as List).map((t) => Chip(
                        label: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.indigo,
                      )).toList(),
                    ),
                    const Divider(),
                    Text("Definition: ${_data!['definition']}")
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
