import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ==========================================
// 1. CONFIGURATION & AI ENGINE
// ==========================================

// YOUR API KEY
const String _apiKey = "AIzaSyCvIGSWr1xqh6t7GI5gmEhBnZ_E3XJBSV4"; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Pro AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ==========================================
// 2. DATA SERVICE (THE BRAIN)
// ==========================================
class AppData {
  // --- A. BEDROCK DATA (Offline Backup) ---
  static final List<Map<String, String>> bedrockVocab = [
    {"word": "Abate", "hindi": "रोकथाम करना", "syn": "Lessen", "ant": "Increase", "use": "The storm abated."},
    {"word": "Benevolent", "hindi": "परोपकारी", "syn": "Kind", "ant": "Cruel", "use": "A benevolent leader."},
    {"word": "Candid", "hindi": "स्पष्टवादी", "syn": "Frank", "ant": "Deceptive", "use": "Be candid with me."},
  ];

  static final List<Map<String, String>> idioms = [
    {"phrase": "Break the ice", "hindi": "बातचीत शुरू करना", "meaning": "Start a conversation"},
    {"phrase": "Piece of cake", "hindi": "बहुत आसान", "meaning": "Very easy task"},
    {"phrase": "Miss the boat", "hindi": "मौका गंवाना", "meaning": "Miss an opportunity"},
  ];

  // --- B. AI FETCHER (Gemini) ---
  static Future<String?> askGemini(String prompt) async {
    try {
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
    } catch (e) {
      debugPrint("AI Error: $e");
    }
    return null;
  }

  // --- C. EXAM FETCHER (UPDATED: Uses AI now) ---
  static Future<List<Map<String, dynamic>>> fetchMockTest() async {
    // UPDATED PROMPT: Specific request for Grammar/Verbs/Communication
    final prompt = "Generate 10 multiple-choice questions for an English Exam. Topics: English Grammar, Verbs Usage, Tenses, and Communication Skills. Format: JSON Array with keys: 'q', 'ans' (correct string), 'options' (list of 4 strings). Do not include markdown formatting like ```json.";
    
    final res = await askGemini(prompt);
    
    if (res != null) {
      try {
        String cleanJson = res.replaceAll("```json", "").replaceAll("```", "").trim();
        List<dynamic> data = jsonDecode(cleanJson);
        
        List<Map<String, dynamic>> questions = [];
        for (var item in data) {
          questions.add({
            "q": item['q'],
            "ans": item['ans'],
            "options": List<String>.from(item['options'])
          });
        }
        return questions;
      } catch (e) {
        debugPrint("AI Exam Parse Error: $e");
      }
    }

    // Fallback if AI fails (Basic Grammar)
    return [
      {"q": "Choose the correct verb: She ___ to the market.", "ans": "went", "options": ["gone", "went", "go", "going"]},
      {"q": "Effective communication requires...", "ans": "Listening", "options": ["Listening", "Shouting", "Ignoring", "Sleeping"]},
    ];
  }
}

// ==========================================
// 3. MAIN NAVIGATION
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  final List<Widget> _screens = [
    const VocabStudio(),
    const GrammarStudio(),
    const ReadingStudio(),
    const ExamHall(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: 'Vocab'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Grammar'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Reading'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Exam'),
        ],
      ),
    );
  }
}

// ==========================================
// 4. SCREEN: VOCABULARY STUDIO
// ==========================================
class VocabStudio extends StatefulWidget {
  const VocabStudio({super.key});
  @override
  State<VocabStudio> createState() => _VocabStudioState();
}

class _VocabStudioState extends State<VocabStudio> {
  List<Map<String, String>> _vocabList = [];
  bool _loading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('vocab_history');
    if (saved != null) {
      List<dynamic> decoded = jsonDecode(saved);
      setState(() {
        _vocabList = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    } else {
      setState(() => _vocabList = AppData.bedrockVocab);
    }
  }

  Future<void> _fetchNewWords() async {
    setState(() => _loading = true);
    final prompt = "Generate 5 important advanced English words. Output JSON array with keys: word, hindi, syn, ant, use. No markdown.";
    
    final result = await AppData.askGemini(prompt);
    
    if (result != null) {
      try {
        String cleanJson = result.replaceAll("```json", "").replaceAll("```", "").trim();
        List<dynamic> newWords = jsonDecode(cleanJson);
        setState(() {
          for (var item in newWords) {
            _vocabList.insert(0, Map<String, String>.from(item));
          }
        });
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('vocab_history', jsonEncode(_vocabList));
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _vocabList.where((e) => 
      e['word']!.toLowerCase().contains(_searchCtrl.text.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vocabulary Database"),
        actions: [
          IconButton(
            icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.cloud_sync),
            onPressed: _loading ? null : _fetchNewWords,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState((){}),
              decoration: const InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
                  columns: const [
                    DataColumn(label: Text("WORD")),
                    DataColumn(label: Text("HINDI")),
                    DataColumn(label: Text("SYNONYM")),
                    DataColumn(label: Text("ANTONYM")),
                    DataColumn(label: Text("SENTENCE")),
                  ],
                  rows: displayList.map((d) => DataRow(cells: [
                    DataCell(Text(d['word']!, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(d['hindi']!, style: const TextStyle(color: Colors.deepOrange))),
                    DataCell(Text(d['syn']!)),
                    DataCell(Text(d['ant']!)),
                    DataCell(Text(d['use']!)),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. SCREEN: GRAMMAR STUDIO
// ==========================================
class GrammarStudio extends StatefulWidget {
  const GrammarStudio({super.key});
  @override
  State<GrammarStudio> createState() => _GrammarStudioState();
}

class _GrammarStudioState extends State<GrammarStudio> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _checkCtrl = TextEditingController();
  String _checkResult = "";
  bool _checking = false;

  final Map<String, List<String>> _topics = {
    "Tenses": ["Present Simple", "Present Continuous", "Past Simple"],
    "Parts of Speech": ["Noun", "Pronoun", "Verb", "Adjective"],
    "Voice": ["Active Voice", "Passive Voice"]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _openTopic(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    String? content = prefs.getString('grammar_$topic');

    if (content == null) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      final prompt = "Explain grammar topic: '$topic'. Format: Definition, Rules, Examples.";
      final aiRes = await AppData.askGemini(prompt);
      Navigator.pop(context);
      if (aiRes != null) {
        content = aiRes;
        prefs.setString('grammar_$topic', aiRes);
      } else {
        content = "Error fetching data.";
      }
    }
    
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topic, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(),
            Flexible(child: SingleChildScrollView(child: Text(content!))),
          ],
        ),
      )
    );
  }

  void _checkGrammar() async {
    setState(() { _checking = true; _checkResult = ""; });
    final prompt = "Correct grammar: '${_checkCtrl.text}'. Only show corrected sentence.";
    final res = await AppData.askGemini(prompt);
    setState(() { _checking = false; _checkResult = res ?? "Error"; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grammar Studio"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          tabs: const [Tab(text: "The Book"), Tab(text: "Live Checker")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            children: _topics.entries.map((entry) {
              return ExpansionTile(
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: entry.value.map((subTopic) => ListTile(
                  title: Text(subTopic),
                  onTap: () => _openTopic(subTopic),
                  leading: const Icon(Icons.bookmark, color: Colors.indigo),
                )).toList(),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(controller: _checkCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Type sentence...")),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _checking ? null : _checkGrammar, child: const Text("Check Grammar")),
                if (_checkResult.isNotEmpty) Text("Result: $_checkResult", style: const TextStyle(fontSize: 18, color: Colors.green))
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 6. SCREEN: READING STUDIO
// ==========================================
class ReadingStudio extends StatefulWidget {
  const ReadingStudio({super.key});
  @override
  State<ReadingStudio> createState() => _ReadingStudioState();
}

class _ReadingStudioState extends State<ReadingStudio> {
  String _passageTitle = "Sample Story";
  String _passageBody = "Click Refresh to generate a story.";
  List<Map<String, dynamic>> _passageQA = [];
  bool _loading = false;

  void _generatePassage() async {
    setState(() => _loading = true);
    final prompt = "Write a short story. Provide 2 multiple choice questions. Output JSON keys: title, body, qa: [{q, a}]. No markdown.";
    final res = await AppData.askGemini(prompt);
    if (res != null) {
      try {
        final data = jsonDecode(res.replaceAll("```json", "").replaceAll("```", "").trim());
        setState(() {
          _passageTitle = data['title'];
          _passageBody = data['body'];
          _passageQA = List<Map<String, dynamic>>.from(data['qa']);
        });
      } catch (e) { debugPrint("Parse Error: $e"); }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reading Studio"), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _generatePassage)]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          Text(_passageTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_passageBody, style: const TextStyle(fontSize: 16)),
          const Divider(),
          ..._passageQA.map((qa) => ListTile(
            title: Text("Q: ${qa['q']}"),
            subtitle: Text("Ans: ${qa['a']}", style: const TextStyle(color: Colors.green)),
          )).toList()
        ],
      ),
    );
  }
}

// ==========================================
// 7. SCREEN: EXAM HALL (Fixed: Grammar/Verbs)
// ==========================================
class ExamHall extends StatefulWidget {
  const ExamHall({super.key});
  @override
  State<ExamHall> createState() => _ExamHallState();
}

class _ExamHallState extends State<ExamHall> {
  List<Map<String, dynamic>>? _questions;
  final Map<int, String> _answers = {};
  bool _submitted = false;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startExam();
  }

  void _startExam() async {
    _timer?.cancel();
    setState(() => _questions = null);
    
    // Now fetches AI Generated Grammar Questions
    final q = await AppData.fetchMockTest();
    
    setState(() {
      _questions = q;
      _submitted = false;
      _answers.clear();
      _seconds = q.length * 3 * 60; // 3 mins per Q
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _submit();
      }
    });
  }

  void _submit() {
    _timer?.cancel();
    setState(() => _submitted = true);
  }

  Future<void> _printScore() async {
    final pdf = pw.Document();
    
    pdf.addPage(pw.MultiPage(build: (c) => [
      pw.Header(level: 0, child: pw.Text("Mock Test Result")),
      pw.Paragraph(text: "Date: ${DateTime.now().toString().split('.')[0]}"),
      pw.Table.fromTextArray(data: <List<String>>[
        <String>['Question', 'Your Answer', 'Correct'],
        ...List.generate(_questions!.length, (i) => [
          _questions![i]['q'], 
          _answers[i] ?? "-", 
          _questions![i]['ans']
        ])
      ])
    ]));

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Exam_Result'
    );
  }

  String get _timerText {
    int m = _seconds ~/ 60;
    int s = _seconds % 60;
    return "${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions == null) return const Center(child: CircularProgressIndicator());

    if (_submitted) {
      int score = 0;
      for (int i=0; i<_questions!.length; i++) {
        if (_answers[i] == _questions![i]['ans']) score++;
      }

      return Scaffold(
        appBar: AppBar(title: const Text("Result")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
              Text("Score: $score / ${_questions!.length}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.print), 
                label: const Text("Print Result"), 
                onPressed: _printScore
              ),
              
              const SizedBox(height: 10),
              TextButton(onPressed: _startExam, child: const Text("Take New Test"))
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Time: $_timerText"),
        backgroundColor: _seconds < 60 ? Colors.red : Colors.indigo,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _questions!.length,
              separatorBuilder: (c,i) => const Divider(),
              itemBuilder: (c,i) {
                final q = _questions![i];
                return ListTile(
                  title: Text("Q${i+1}: ${q['q']}"),
                  subtitle: Column(
                    children: q['options'].map<Widget>((o) => RadioListTile(
                      title: Text(o), 
                      value: o.toString(), 
                      groupValue: _answers[i], 
                      onChanged: (v) => setState(() => _answers[i] = v.toString())
                    )).toList(),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
              onPressed: _submit,
              child: const Text("SUBMIT EXAM"),
            ),
          )
        ],
      ),
    );
  }
}
