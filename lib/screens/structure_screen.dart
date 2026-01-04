import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StructureScreen extends StatefulWidget {
  const StructureScreen({super.key});
  @override
  State<StructureScreen> createState() => _StructureScreenState();
}

class _StructureScreenState extends State<StructureScreen> {
  final _ctrl = TextEditingController();
  List<String> _results = [];
  String _mode = "adj";

  void _getRelations() async {
    final res = await ApiService.fetchWordRelations(_ctrl.text, _mode);
    setState(() => _results = res);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Word Builder", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(controller: _ctrl, decoration: const InputDecoration(labelText: "Enter a Noun (e.g. Sky)", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.brush),
                label: const Text("Describe it"),
                onPressed: () { _mode="adj"; _getRelations(); },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text("Related"),
                onPressed: () { _mode="rel"; _getRelations(); },
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (ctx, i) => Card(
                child: ListTile(
                  leading: const Icon(Icons.arrow_forward, color: Colors.indigo),
                  title: Text(_results[i]),
                  trailing: Text(_mode == 'adj' ? "Adjective" : "Related"),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
