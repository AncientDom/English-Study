import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFCAT Prep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- 1. THE DATA ENGINE ---
class AppData {
  // Study Material Data
  static final List<String> antonyms = [
    "Abate - Aggravate", "Absolve - Blame", "Acrimony - Courtesy", 
    "Adversity - Prosperity", "Alien - Native", "Amplify - Lessen"
  ];
  
  static final List<String> synonyms = [
    "Abstain - Refrain", "Acknowledge - Admit", "Aid - Help", 
    "Adept - Skilled", "Adorn - Decorate", "Agile - Quick"
  ];

  static final List<String> idioms = [
    "A hot potato - A controversial issue",
    "Ball is in your court - It is your decision now",
    "Beat around the bush - Avoiding the main topic"
  ];

  static final List<String> grammarRules = [
    "Rule 1: Two singular subjects connected by 'and' require a PLURAL verb.",
    "Rule 2: 'One of' is always followed by a PLURAL noun and SINGULAR verb."
  ];

  static final List<String> readingTips = [
    "Tip 1: Read the questions first before the passage.",
    "Tip 2: Eliminate options that are clearly wrong."
  ];

  // Quiz Generator
  static List<Map<String, dynamic>> getQuestions(String topic) {
    List<Map<String, dynamic>> data = [];
    // Add Real Questions
    if (topic == "Vocabulary") {
      data.add({"q": "Antonym of CANDID", "options": ["Frank", "Deceptive", "Honest", "Open"], "ans": 1});
      data.add({"q": "Synonym of ABATE", "options": ["Increase", "Reduce", "Observe", "Create"], "ans": 1});
    }
    // Fill up to 100
    for (int i = data.length; i < 100; i++) {
      data.add({
        "q": "Mock $topic Question #${i + 1}",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "ans": Random().nextInt(4)
      });
    }
    return data;
  }
}

// --- 2. HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  static const List<Widget> _pages = [
    SubjectDashboard(title: "Vocabulary", topic: "Vocabulary", color: Colors.indigo),
    SubjectDashboard(title: "Grammar", topic: "Grammar", color: Colors.teal),
    SubjectDashboard(title: "Reading", topic: "Reading", color: Colors.deepOrange),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AFCAT Prep'), elevation: 1),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Vocab'),
          BottomNavigationBarItem(icon: Icon(Icons.rule), label: 'Grammar'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Reading'),
        ],
      ),
    );
  }
}

// --- 3. DASHBOARD ---
class SubjectDashboard extends StatelessWidget {
  final String title;
  final String topic;
  final Color color;

  const SubjectDashboard({super.key, required this.title, required this.topic, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 20),
        _btn(context, "Study Material", Icons.menu_book, () => 
          Navigator.push(context, MaterialPageRoute(builder: (_) => StudyReader(topic: topic)))),
        _btn(context, "Daily Quiz (100 Qs)", Icons.flash_on, () => 
          Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(topic: topic)))),
        _btn(context, "Exam (90 Mins)", Icons.timer, () => 
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamScreen()))),
        _btn(context, "Answer Sheet", Icons.assignment, () => 
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultScreen()))),
      ],
    );
  }

  Widget _btn(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// --- 4. STUDY MATERIAL (TABBED BOOK) ---
class StudyReader extends StatelessWidget {
  final String topic;
  const StudyReader({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    List<String> tabs = [];
    List<List<String>> data = [];

    if (topic == "Vocabulary") {
      tabs = ["Antonyms", "Synonyms", "Idioms"];
      data = [AppData.antonyms, AppData.synonyms, AppData.idioms];
    } else if (topic == "Grammar") {
      tabs = ["Rules"];
      data = [AppData.grammarRules];
    } else {
      tabs = ["Tips"];
      data = [AppData.readingTips];
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("$topic Study"),
          bottom: TabBar(tabs: tabs.map((t) => Tab(text: t)).toList()),
        ),
        body: TabBarView(
          children: data.map((list) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) => Text(list[i], style: const TextStyle(fontSize: 16)),
          )).toList(),
        ),
      ),
    );
  }
}

// --- 5. QUIZ SCREEN ---
class QuizScreen extends StatefulWidget {
  final String topic;
  const QuizScreen({super.key, required this.topic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();
    questions = AppData.getQuestions(widget.topic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.topic} Quiz")),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (ctx, i) {
          final q = questions[i];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text("Q${i+1}: ${q['q']}"),
              children: List.generate(4, (idx) => ListTile(
                title: Text(q['options'][idx]),
                leading: Icon(
                  idx == q['ans'] ? Icons.check : Icons.circle_outlined,
                  color: idx == q['ans'] ? Colors.green : Colors.grey,
                ),
              )),
            ),
          );
        },
      ),
    );
  }
}

// --- 6. EXAM SCREEN ---
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int _seconds = 90 * 60;
  Timer? _timer;
  final Map<int, int> _answers = {};
  final List<Map<String, dynamic>> _questions = [
    ...AppData.getQuestions("Vocabulary").take(10),
    ...AppData.getQuestions("Grammar").take(10),
    ...AppData.getQuestions("Reading").take(10),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 0) setState(() => _seconds--);
      else _submit();
    });
  }

  Future<void> _submit() async {
    _timer?.cancel();
    int score = 0;
    _answers.forEach((i, ans) {
      if (ans == _questions[i]['ans']) score += 3;
      else score -= 1;
    });

    final prefs = await SharedPreferences.getInstance();
    final report = {
      "score": score,
      "total": _questions.length * 3,
      "history": List.generate(_questions.length, (i) => {
        "q": _questions[i]['q'],
        "user": _answers[i],
        "correct": _questions[i]['ans'],
        "options": _questions[i]['options']
      })
    };
    await prefs.setString('last_exam', jsonEncode(report));
    
    if (mounted) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Time: ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}"),
        actions: [TextButton(onPressed: _submit, child: const Text("SUBMIT"))],
      ),
      body: ListView.builder(
        itemCount: _questions.length,
        itemBuilder: (ctx, i) {
          final q = _questions[i];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(title: Text("Q${i+1}: ${q['q']}")),
                ...List.generate(4, (optIdx) => RadioListTile(
                  value: optIdx,
                  groupValue: _answers[i],
                  onChanged: (v) => setState(() => _answers[i] = v as int),
                  title: Text(q['options'][optIdx]),
                ))
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- 7. RESULT SCREEN ---
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Future<Map<String, dynamic>?> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('last_exam');
    return raw != null ? jsonDecode(raw) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Result")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _load(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: Text("No Exam Taken"));
          final data = snap.data!;
          final history = data['history'] as List;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.indigo,
                width: double.infinity,
                child: Text("Score: ${data['score']}", 
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (ctx, i) {
                    final h = history[i];
                    final isCorrect = h['user'] == h['correct'];
                    return ListTile(
                      title: Text(h['q']),
                      subtitle: Text("Your Answer: ${h['user'] == null ? 'Skipped' : h['options'][h['user']]}"),
                      trailing: Icon(isCorrect ? Icons.check : Icons.close, color: isCorrect ? Colors.green : Colors.red),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
