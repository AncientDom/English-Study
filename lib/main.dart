import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MAIN ENTRY POINT ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFCAT English Prep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const HomeScreen(),
    );
  }
}

// --- DATA ENGINE (THE BRAIN) ---
class AppData {
  // 1. GENERATE 100 MOCK QUESTIONS PER TOPIC
  static List<Map<String, dynamic>> getQuestions(String topic) {
    List<Map<String, dynamic>> data = [];
    
    // Add some "Real" examples first
    if (topic == "Vocabulary") {
      data.add({"q": "Antonym of CANDID", "options": ["Frank", "Deceptive", "Honest", "Open"], "ans": 1});
      data.add({"q": "Synonym of ABATE", "options": ["Increase", "Reduce", "Observe", "Create"], "ans": 1});
    } else if (topic == "Grammar") {
      data.add({"q": "Spot Error: She do not / know how / to swim.", "options": ["She do not", "know how", "to swim", "No Error"], "ans": 0});
      data.add({"q": "Preposition: He died ___ malaria.", "options": ["of", "from", "by", "with"], "ans": 0});
    } else {
      data.add({"q": "Reading: The author implies that...", "options": ["A", "B", "C", "D"], "ans": 2});
    }

    // Fill the rest to reach 100 questions (Simulation)
    for (int i = data.length; i < 100; i++) {
      data.add({
        "q": "Mock $topic Question #${i + 1} (generated for testing 100 Qs)",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "ans": Random().nextInt(4) // Random answer
      });
    }
    return data;
  }

  // 2. MOCK STUDY MATERIAL (Text Book Mode)
  static const String vocabStudy = """
  # Chapter 1: Antonyms
  1. Abate - Aggravate
  2. Candid - Deceptive
  3. Banal - Original
  
  # Chapter 2: Idioms
  * A hot potato: Speak of an issue which is mostly disputed.
  * Ball is in your court: It is up to you to make the next decision.
  """;

  static const String grammarStudy = """
  # Chapter 1: Subject Verb Agreement
  * Rule 1: Two or more singular subjects connected by 'and' usually take a verb in the plural.
  
  # Chapter 2: Prepositions
  * Died OF a disease (Died of Malaria).
  * Died FROM a cause (Died from thirst).
  """;
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Strict separation of tabs
  static const List<Widget> _pages = <Widget>[
    SubjectDashboard(title: "Vocabulary", topic: "Vocabulary", color: Colors.indigo),
    SubjectDashboard(title: "Grammar", topic: "Grammar", color: Colors.teal),
    SubjectDashboard(title: "Reading", topic: "Reading", color: Colors.deepOrange),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AFCAT English Prep'), 
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Vocab'),
          BottomNavigationBarItem(icon: Icon(Icons.rule), label: 'Grammar'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Reading'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// --- DASHBOARD (THE 4 BUTTONS) ---
class SubjectDashboard extends StatelessWidget {
  final String title;
  final String topic;
  final Color color;

  const SubjectDashboard({super.key, required this.title, required this.topic, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                const Text("Select an option below to start"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Options
          _buildOption(context, "Study Material", Icons.menu_book, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => StudyReader(topic: topic)));
          }),
          _buildOption(context, "Daily Quiz (100 Qs)", Icons.flash_on, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(topic: topic)));
          }),
          _buildOption(context, "Exam (90 Mins)", Icons.timer, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamScreen()));
          }),
          _buildOption(context, "View Answer Sheet", Icons.assignment, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}

// --- FEATURE 1: STUDY MATERIAL (BOOK READER) ---
class StudyReader extends StatelessWidget {
  final String topic;
  const StudyReader({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    String content = "";
    if (topic == "Vocabulary") content = AppData.vocabStudy;
    else if (topic == "Grammar") content = AppData.grammarStudy;
    else content = "Reading comprehension passages would appear here.\n\n(Generated via internet APIs in full version).";

    return Scaffold(
      appBar: AppBar(title: Text("$topic Material")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
      ),
    );
  }
}

// --- FEATURE 2: QUIZ SCREEN (100 Questions) ---
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
    // Load 100 Questions specifically for this topic
    questions = AppData.getQuestions(widget.topic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daily Quiz (${questions.length})")),
      body: ListView.separated(
        itemCount: questions.length,
        separatorBuilder: (ctx, i) => const Divider(),
        itemBuilder: (ctx, i) {
          final q = questions[i];
          return ExpansionTile(
            title: Text("Q${i+1}: ${q['q']}", style: const TextStyle(fontWeight: FontWeight.w500)),
            children: List.generate(4, (optIndex) {
              final isCorrect = optIndex == q['ans'];
              return ListTile(
                leading: Text(["A","B","C","D"][optIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
                title: Text(q['options'][optIndex]),
                trailing: isCorrect ? const Icon(Icons.check, color: Colors.green) : null,
              );
            }),
          );
        },
      ),
    );
  }
}

// --- FEATURE 3: EXAM SCREEN (With Timer & Saver) ---
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int _timeLeft = 90 * 60; // 90 Minutes
  Timer? _timer;
  int _currentIndex = 0;
  final Map<int, int> _userAnswers = {};
  late List<Map<String, dynamic>> _examQuestions;

  @override
  void initState() {
    super.initState();
    // Mix questions for exam (30 Questions total)
    _examQuestions = [
      ...AppData.getQuestions("Vocabulary").take(10),
      ...AppData.getQuestions("Grammar").take(10),
      ...AppData.getQuestions("Reading").take(10),
    ];
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) setState(() => _timeLeft--);
      else _submitExam();
    });
  }

  Future<void> _submitExam() async {
    _timer?.cancel();
    
    // 1. Calculate Score
    int score = 0;
    _userAnswers.forEach((index, ans) {
      if (ans == _examQuestions[index]['ans']) score += 3;
      else score -= 1;
    });

    // 2. Prepare Detailed Report
    Map<String, dynamic> report = {
      "score": score,
      "date": DateTime.now().toString(),
      "total": _examQuestions.length,
      "history": List.generate(_examQuestions.length, (i) {
        return {
          "q": _examQuestions[i]['q'],
          "userOpt": _userAnswers[i], // Can be null if skipped
          "correctOpt": _examQuestions[i]['ans'],
          "options": _examQuestions[i]['options']
        };
      })
    };

    // 3. Save to Disk (Persistent)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_exam_report', jsonEncode(report));

    if (mounted) {
      Navigator.pop(context); // Close exam
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultScreen())); // Show result
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_examQuestions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final q = _examQuestions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Time: ${(_timeLeft ~/ 60).toString().padLeft(2,'0')}:${(_timeLeft % 60).toString().padLeft(2,'0')}"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [TextButton(onPressed: _submitExam, child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Q${_currentIndex + 1}: ${q['q']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (ctx, i) => RadioListTile(
                value: i,
                groupValue: _userAnswers[_currentIndex],
                title: Text(q['options'][i]),
                onChanged: (val) => setState(() => _userAnswers[_currentIndex] = val as int),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null, child: const Text("Previous")),
                Text("${_currentIndex+1}/${_examQuestions.length}"),
                ElevatedButton(onPressed: _currentIndex < _examQuestions.length - 1 ? () => setState(() => _currentIndex++) : null, child: const Text("Next")),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- FEATURE 4: ANSWER SHEET (DETAILED VIEW) ---
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Future<Map<String, dynamic>?> _loadReport() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('last_exam_report');
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Answer Sheet")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadReport(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: Text("No exam taken yet."));
          
          final data = snapshot.data!;
          final history = data['history'] as List;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.indigo,
                child: Column(
                  children: [
                    const Text("SCORE", style: TextStyle(color: Colors.white70)),
                    Text("${data['score']}", style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (ctx, i) {
                    final item = history[i];
                    final userOpt = item['userOpt'];
                    final correctOpt = item['correctOpt'];
                    final isCorrect = userOpt == correctOpt;
                    final options = item['options'];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      color: isCorrect ? Colors.green[50] : Colors.red[50],
                      child: ListTile(
                        title: Text("Q${i+1}: ${item['q']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Your Answer: ${userOpt != null ? options[userOpt] : 'Skipped'}", 
                                style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                            Text("Correct Answer: ${options[correctOpt]}", 
                                style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                        trailing: Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
