import 'dart:async';
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
      ),
      home: const HomeScreen(),
    );
  }
}

// --- DATA & STATE MANAGEMENT (THE BRAIN) ---
class AppData {
  // MOCK DATA - In real app, this would come from internet/JSON
  static final List<Map<String, dynamic>> vocabQuestions = [
    {"q": "Antonym of CANDID", "options": ["Frank", "Deceptive", "Honest", "Open"], "ans": 1},
    {"q": "Synonym of ABATE", "options": ["Increase", "Reduce", "Observe", "Create"], "ans": 1},
    {"q": "Idiom: 'Piece of cake'", "options": ["Tasty", "Difficult", "Very Easy", "Soft"], "ans": 2},
  ];

  static final List<Map<String, dynamic>> grammarQuestions = [
    {"q": "Error Spotting: She do not / know how / to swim.", "options": ["She do not", "know how", "to swim", "No Error"], "ans": 0},
    {"q": "Preposition: He died ___ malaria.", "options": ["of", "from", "by", "with"], "ans": 0},
  ];

  static final List<Map<String, dynamic>> readingQuestions = [
    {"q": "Cloze Test: The quick brown fox ___ over the dog.", "options": ["jumps", "sit", "lazy", "run"], "ans": 0},
  ];
}

// --- HOME SCREEN (3 TABS) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    SubjectDashboard(title: "Vocabulary", topic: "Vocab"),
    SubjectDashboard(title: "Grammar", topic: "Grammar"),
    SubjectDashboard(title: "Reading", topic: "Reading"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AFCAT English Prep'), backgroundColor: Colors.indigo.shade50),
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

// --- SUBJECT DASHBOARD (4 OPTIONS) ---
class SubjectDashboard extends StatelessWidget {
  final String title;
  final String topic;

  const SubjectDashboard({super.key, required this.title, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildCard(context, "Study Material", Icons.library_books, Colors.blue, 
            () => _showMsg(context, "Opening Study PDF/Web View...")),
          _buildCard(context, "Daily Quiz (Refresh)", Icons.refresh, Colors.orange, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(topic: topic)))),
          _buildCard(context, "Mock Exam (AFCAT)", Icons.timer, Colors.red, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamScreen()))),
          _buildCard(context, "Answer Sheet", Icons.assignment_turned_in, Colors.green, 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultScreen()))),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// --- QUIZ SCREEN (DAILY UPDATE LOGIC) ---
class QuizScreen extends StatefulWidget {
  final String topic;
  const QuizScreen({super.key, required this.topic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    // Simulate 12-hour check logic here
    await Future.delayed(const Duration(seconds: 1)); // Fake network delay
    setState(() {
      if (widget.topic == "Vocab") questions = AppData.vocabQuestions;
      else if (widget.topic == "Grammar") questions = AppData.grammarQuestions;
      else questions = AppData.readingQuestions;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.topic} Quiz")),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: questions.length,
            itemBuilder: (ctx, i) {
              final q = questions[i];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text("Q${i+1}: ${q['q']}"),
                  children: List.generate(4, (optIndex) => ListTile(
                    title: Text(q['options'][optIndex]),
                    leading: Icon(optIndex == q['ans'] ? Icons.check_circle : Icons.circle_outlined, 
                      color: optIndex == q['ans'] ? Colors.green : null),
                  )),
                ),
              );
            },
          ),
    );
  }
}

// --- EXAM SCREEN (TIMER & LOGIC) ---
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  int _timeLeft = 90 * 60; // 90 Minutes
  Timer? _timer;
  int _currentIndex = 0;
  final Map<int, int> _answers = {};
  
  // Combine all questions for exam
  final List<Map<String, dynamic>> _examQuestions = [...AppData.vocabQuestions, ...AppData.grammarQuestions];

  @override
  void initState() {
    super.initState();
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
    int score = 0;
    _answers.forEach((k, v) {
      if (v == _examQuestions[k]['ans']) score += 3;
      else score -= 1;
    });

    // Save Result
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_score', score);
    
    if (mounted) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultScreen()));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_examQuestions.isEmpty) return const Scaffold(body: Center(child: Text("No Questions Available")));
    final q = _examQuestions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Time: ${(_timeLeft ~/ 60).toString().padLeft(2,'0')}:${(_timeLeft % 60).toString().padLeft(2,'0')}"),
        actions: [TextButton(onPressed: _submitExam, child: const Text("SUBMIT", style: TextStyle(color: Colors.white)))],
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Q${_currentIndex + 1}: ${q['q']}", style: const TextStyle(fontSize: 18)),
          ),
          ...List.generate(4, (i) => RadioListTile(
            value: i, 
            groupValue: _answers[_currentIndex], 
            title: Text(q['options'][i]),
            onChanged: (v) => setState(() => _answers[_currentIndex] = v as int),
          )),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null, 
                child: const Text("Prev")
              ),
              ElevatedButton(
                onPressed: _currentIndex < _examQuestions.length - 1 ? () => setState(() => _currentIndex++) : null, 
                child: const Text("Next")
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- RESULT SCREEN ---
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int? score;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => score = prefs.getInt('last_score'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Answer Sheet")),
      body: Center(
        child: score == null 
        ? const Text("No exam taken yet.") 
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              Text("Your Score: $score", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Detailed analysis would appear here."),
            ],
          ),
      ),
    );
  }
}
