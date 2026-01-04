import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/tense_engine.dart';

class TenseCheckScreen extends StatefulWidget {
  const TenseCheckScreen({super.key});
  @override
  State<TenseCheckScreen> createState() => _TenseCheckScreenState();
}

class _TenseCheckScreenState extends State<TenseCheckScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _errors = [];
  String _tense = "Unknown";
  bool _loading = false;

  void _analyze() async {
    setState(() { _loading = true; _errors = []; _tense = "Analyzing..."; });
    
    String detectedTense = TenseEngine.identifyTense(_ctrl.text);
    final apiErrors = await ApiService.checkErrors(_ctrl.text);

    setState(() {
      _loading = false;
      _tense = detectedTense;
      _errors = apiErrors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _ctrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: "Enter a full sentence...", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: _analyze, icon: const Icon(Icons.analytics), label: const Text("Analyze")),
          const SizedBox(height: 20),
          if (_loading) const CircularProgressIndicator(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                const Text("DETECTED TENSE", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                Text(_tense, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _errors.length,
              itemBuilder: (ctx, i) => Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(_errors[i]['bad'], style: const TextStyle(decoration: TextDecoration.lineThrough)),
                  subtitle: Text("Suggestion: ${_errors[i]['better']}"),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
