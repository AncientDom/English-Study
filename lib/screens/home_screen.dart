import 'package:flutter/material.dart';
import 'vocab_screen.dart';
import 'grammar_hub.dart';
import 'reading_screen.dart';
import 'exam_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  
  final List<Widget> _screens = [
    const VocabScreen(),
    const GrammarHubScreen(), // Contains the 3 sub-tabs
    const ReadingScreen(),
    const ExamScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Needed for 4 items
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: Colors.indigo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.translate), label: 'Vocab'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Grammar'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Reading'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Exam'),
        ],
      ),
    );
  }
}
