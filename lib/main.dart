import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- ENTRY POINT ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Pro V6',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// 1. API SERVICE (THE LOGIC ENGINE)
// ==========================================
class ApiService {
  
  // --- A. VOCABULARY API ---
  static Future<Map<String, dynamic>?> fetchWordData(String word) async {
    try {
      final url = Uri.parse("https://api.dictionaryapi.dev/api/v2/entries/en/$word");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];
        List<String> types = [];
        for (var meaning in data['meanings']) {
          types.add(meaning['partOfSpeech']);
        }
        return {
          "word": data['word'],
          "phonetic": data['phonetic'] ?? "",
          "types": types.toSet().toList(),
          "meaning": data['meanings'][0]['definitions'][0]['definition'],
          "synonyms": (data['meanings'][0]['synonyms'] as List?)?.take(3).join(", ") ?? "None"
        };
      }
    } catch (e) {
      print("Vocab Error: $e");
    }
    return null;
  }

  // --- B. SENTENCE STRUCTURE API ---
  static Future<List<String>> fetchWordRelations(String word, String type) async {
    try {
      String query = type == 'adj' ? 'rel_jjb=$word' : 'rel_trg=$word';
      final url = Uri.parse("https://api.datamuse.com/words?$query");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.take(10).map((e) => e['word'].toString()).toList();
      }
    } catch (e) {
      print("Datamuse Error: $e");
    }
    return [];
  }

  // --- C. GRAMMAR CHECKER API ---
  static Future<List<Map<String, dynamic>>> checkErrors(String text) async {
    try {
      final url = Uri.parse("https://api.languagetool.org/v2/check");
      final response = await http.post(
        url,
        body: {'text': text, 'language': 'en-US'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['matches'] as List).map((m) => {
          "message": m['message'],
          "bad": m['context']['text'].substring(m['context']['offset'], m['context']['offset'] + m['context']['length']),
          "better": (m['replacements'] as List).isNotEmpty ? m['replacements'][0]['value'] : "?"
        }).toList().cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Grammar Error: $e");
    }
    return [];
  }

  // --- D. QUIZ API ---
  static Future<List<Map<String, dynamic>>> fetchQuiz() async {
    try {
      final url = Uri.parse("https://opentdb.com/api.php?amount=10&category=10&type=multiple");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> questions = [];
        for (var item in data['results']) {
          List<String> opts = List<String>.from(item['incorrect_answers']);
          opts.add(item['correct_answer']);
          opts.shuffle();
          questions.add({"q": item['question'], "ans": item['correct_answer'], "options": opts});
        }
        return questions;
      }
    } catch (e) {
      print("Quiz Error: $e");
    }
    return [{"q": "Synonym of Happy", "ans": "Joyful", "options": ["Sad", "Joyful", "Mad"]}];
  }
}

// ==========================================
// 2. TENSE LOGIC (LOCAL)
// ==========================================
class TenseEngine {
  static String identifyTense(String sentence) {
    String s = sentence.toLowerCase();
    if (s.contains("will") || s.contains("shall")) return "Future Tense";
    if (s.contains("was") || s.contains("were") || s.endsWith("ed ")) return "Past Tense";
    if (s.contains("is") || s.contains("are")) return "Present Tense";
    return "Simple Present (Likely)";
  }
}

// ==========================================
// 3. SCREENS
// ==========================================

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final List<Widget> _screens = [
    const VocabScreen(),
    const GrammarHubScreen(),
    const ReadingScreen(),
    const ExamScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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

// --- A. VOCAB SCREEN ---
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
    setState(() { _loading = true; _data = null; });
    final res = await ApiService.fetchWordData(_ctrl.text);
    setState(() { _loading = false; _data = res; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vocabulary Dictionary")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _ctrl, decoration: InputDecoration(labelText: "Search Word", suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search), border: const OutlineInputBorder())),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_data != null)
              Card(
                child: ListTile(
                  title: Text(_data!['word'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  subtitle: Text("Meaning: ${_data!['meaning']}\n\nSynonyms: ${_data!['synonyms']}"),
                  isThreeLine: true,
                ),
              )
          ],
        ),
      ),
    );
  }
}

// --- B. GRAMMAR HUB (3 TABS) ---
class GrammarHubScreen extends StatelessWidget {
  const GrammarHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Grammar Studio"),
          bottom: const TabBar(
            labelColor: Colors.white,
            tabs: [Tab(text: "POS"), Tab(text: "Structure"), Tab(text: "Tenses")],
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const TabBarView(
          children: [PartsOfSpeechTab(), StructureTab(), TenseTab()],
        ),
      ),
    );
  }
}

class PartsOfSpeechTab extends StatefulWidget {
  const PartsOfSpeechTab({super.key});
  @override
  State<PartsOfSpeechTab> createState() => _PartsOfSpeechTabState();
}
class _PartsOfSpeechTabState extends State<PartsOfSpeechTab> {
  final _ctrl = TextEditingController();
  Map<String, dynamic>? _data;
  void _check() async { final res = await ApiService.fetchWordData(_ctrl.text); setState(() => _data = res); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: _ctrl, decoration: InputDecoration(labelText: "Enter word to find POS", suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _check))),
        const SizedBox(height: 20),
        if (_data != null) Text("Types: ${_data!['types'].join(', ')}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
      ]),
    );
  }
}

class StructureTab extends StatefulWidget {
  const StructureTab({super.key});
  @override
  State<StructureTab> createState() => _StructureTabState();
}
class _StructureTabState extends State<StructureTab> {
  final _ctrl = TextEditingController();
  List<String> _res = [];
  void _get(String t) async { final r = await ApiService.fetchWordRelations(_ctrl.text, t); setState(() => _res = r); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: _ctrl, decoration: const InputDecoration(labelText: "Enter Noun (e.g. Sky)")),
        Row(children: [TextButton(onPressed: () => _get('adj'), child: const Text("Get Adjectives")), TextButton(onPressed: () => _get('rel'), child: const Text("Get Related"))]),
        Expanded(child: ListView(children: _res.map((e) => ListTile(title: Text(e))).toList()))
      ]),
    );
  }
}

class TenseTab extends StatefulWidget {
  const TenseTab({super.key});
  @override
  State<TenseTab> createState() => _TenseTabState();
}
class _TenseTabState extends State<TenseTab> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _errs = [];
  String _tense = "";
  void _analyze() async { 
    final t = TenseEngine.identifyTense(_ctrl.text);
    final e = await ApiService.checkErrors(_ctrl.text);
    setState(() { _tense = t; _errs = e; });
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: _ctrl, decoration: const InputDecoration(labelText: "Enter Sentence")),
        ElevatedButton(onPressed: _analyze, child: const Text("Check Tense & Grammar")),
        const SizedBox(height: 10),
        Text("Tense: $_tense", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
        Expanded(child: ListView(children: _errs.map((e) => ListTile(title: Text(e['bad'], style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)), subtitle: Text(e['better']))).toList()))
      ]),
    );
  }
}

// --- C. READING SCREEN ---
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text("Reading"), bottom: const TabBar(tabs: [Tab(text: "Passage"), Tab(text: "Cloze Test")])),
        body: const TabBarView(children: [
          Padding(padding: EdgeInsets.all(16), child: Text("Success requires persistence. Many people give up just when they are about to achieve their goal.", style: TextStyle(fontSize: 18))),
          Padding(padding: EdgeInsets.all(16), child: Text("India is a land of _____ culture. (Options: Poor, Rich, Empty)", style: TextStyle(fontSize: 18))),
        ]),
      ),
    );
  }
}

// --- D. EXAM SCREEN ---
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}
class _ExamScreenState extends State<ExamScreen> {
  List<Map<String, dynamic>>? _q;
  final Map<int, String> _a = {};
  bool _sub = false;
  void _start() async { final q = await ApiService.fetchQuiz(); setState(() { _q = q; _sub = false; _a.clear(); }); }
  Future<void> _pdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(build: (c) => [pw.Header(level: 0, child: pw.Text("Result")), pw.Table.fromTextArray(data: <List<String>>[<String>['Q','Ans','Correct'], ...List.generate(_q!.length, (i) => [_q![i]['q'], _a[i]??"-", _q![i]['ans']])])]));
    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }
  @override
  void initState() { super.initState(); _start(); }
  @override
  Widget build(BuildContext context) {
    if (_q == null) return const Center(child: CircularProgressIndicator());
    if (_sub) return Center(child: ElevatedButton(onPressed: _pdf, child: const Text("Download PDF")));
    return Column(children: [
      Expanded(child: ListView.separated(itemCount: _q!.length, separatorBuilder: (c,i)=>const Divider(), itemBuilder: (c,i) {
        return ListTile(title: Text("Q: ${_q![i]['q']}"), subtitle: Column(children: _q![i]['options'].map<Widget>((o) => RadioListTile(title: Text(o), value: o.toString(), groupValue: _a[i], onChanged: (v)=>setState(()=>_a[i]=v.toString()))).toList()));
      })),
      ElevatedButton(onPressed: () => setState(() => _sub = true), child: const Text("Submit"))
    ]);
  }
}
