import 'package:flutter/material.dart';

class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reading Skills"),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.white,
            tabs: [Tab(text: "Comprehension"), Tab(text: "Cloze Test")]
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const TabBarView(
          children: [
            _ComprehensionTab(),
            _ClozeTestTab(),
          ],
        ),
      ),
    );
  }
}

class _ComprehensionTab extends StatelessWidget {
  const _ComprehensionTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Passage: The Power of Persistence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.teal.shade50,
          child: const Text(
            "Success requires not only talent but also persistence. Many people give up just when they are about to achieve their goal. Persistence allows someone to continue doing something even though it is difficult.",
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        const Divider(height: 30),
        const Text("Q1: What is required besides talent?", style: TextStyle(fontWeight: FontWeight.bold)),
        const ListTile(title: Text("Persistence"), leading: Icon(Icons.check_circle, color: Colors.green)),
        const ListTile(title: Text("Money"), leading: Icon(Icons.radio_button_unchecked)),
      ],
    );
  }
}

class _ClozeTestTab extends StatelessWidget {
  const _ClozeTestTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Fill in the blanks:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        const Text("India is a land of (1) _____ culture and heritage.", style: TextStyle(fontSize: 18, height: 2.0)),
        const SizedBox(height: 20),
        const Text("Options for (1):", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10,
          children: ["Poor", "Rich", "Empty", "Dull"].map((e) => Chip(label: Text(e))).toList(),
        )
      ],
    );
  }
}
