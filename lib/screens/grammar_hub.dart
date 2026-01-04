import 'package:flutter/material.dart';
import 'pos_screen.dart';
import 'structure_screen.dart';
import 'tense_screen.dart';

class GrammarHubScreen extends StatelessWidget {
  const GrammarHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Grammar Studio"),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.category), text: "POS"),
              Tab(icon: Icon(Icons.construction), text: "Structure"),
              Tab(icon: Icon(Icons.spellcheck), text: "Tenses"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PartsOfSpeechScreen(),
            StructureScreen(),
            TenseCheckScreen(),
          ],
        ),
      ),
    );
  }
}
