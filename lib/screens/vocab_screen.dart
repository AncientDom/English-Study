import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});
  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  final _ctrl = TextEditingController();
  Map<String, dynamic>? _data;
  bool _loading = false;

  void _search() async {
    if (_ctrl.text.isEmpty) return;
    setState(() { _loading = true; _data = null; });
    final res = await ApiService.fetchWordData(_ctrl.text);
    setState(() { _loading = false; _data = res; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vocabulary"), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                labelText: "Search Word",
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                border: const OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_data != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_data!['word'], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      if (_data!['phonetic'].isNotEmpty)
                        Text(_data!['phonetic'], style: const TextStyle(fontStyle: FontStyle.italic)),
                      const Divider(),
                      const Text("Definition:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_data!['meaning'], style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      const Text("Synonyms:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_data!['synonyms'], style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
