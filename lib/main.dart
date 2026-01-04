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

// TODO: GET YOUR KEY HERE: https://aistudio.google.com/app/apikey
const String _apiKey = "AIzaSyBfyXr67_f6C_WTDrPIoMYEbCBrJB08mLg"; 

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
    {"word": "Diligent", "hindi": "मेहनती", "syn": "Hardworking", "ant": "Lazy", "use": "A diligent student."},
    {"word": "Eloquent", "hindi": "सुवक्ता", "syn": "Fluent", "ant": "Inarticulate", "use": "Eloquent speech."},
    // ... (You can add your 20 offline words here)
  ];

  static final List<Map<String, String>> idioms = [
    {"phrase": "Break the ice", "hindi": "बातचीत शुरू करना", "meaning": "Start a conversation"},
    {"phrase": "Piece of cake", "hindi": "बहुत आसान", "meaning": "Very easy task"},
    {"phrase": "Miss the boat", "hindi": "मौका गंवाना", "meaning": "Miss an opportunity"},
  ];

  // --- B. AI FETCHER (Gemini) ---
  static Future<String?> askGemini(String prompt) async {
    if (_apiKey == "PASTE_YOUR_GEMINI_KEY_HERE") return null; // Key safety check

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
        // Extracting text from deep JSON structure
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
    } catch (e) {
      debugPrint("AI Error: $e");
    }
    return null;
  }

  // --- C. EXAM FETCHER (OpenTrivia) ---
  static Future<List<Map<String, dynamic>>> fetchMockTest() async {
    try {
      final url = Uri.parse("https://opentdb.com/api.php?amount=10&category=10&type=multiple");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> qs = [];
        for (var item in data['results']) {
          List<String> opts = List<String>.from(item['incorrect_answers']);
          opts.add(item['correct_answer']);
          opts.shuffle();
          qs.add({
            "q": _clean(item['question']),
            "ans": _clean(item['correct_answer']),
            "options": opts.map((e) => _clean(e)).toList()
          });
        }
        return qs;
      }
    } catch (e) {
      debugPrint("Quiz API Error: $e");
    }
    return [];
  }

  static String _clean(String txt) {
    return txt.replaceAll("&quot;", '"').replaceAll("&#039;", "'").replaceAll("&amp;", "&");
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
      body: IndexedStack(index: _idx, children: _screens), // Keeps state alive
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

  // 1. Load from Phone Memory or Bedrock
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

  // 2. Fetch New Words from AI
  Future<void> _fetchNewWords() async {
    setState(() => _loading = true);
    final prompt = "Generate 5 important advanced English words for competitive exams. Output ONLY a JSON array with keys: word, hindi, syn, ant, use. Do not include markdown formatting.";
    
    final result = await AppData.askGemini(prompt);
    
    if (result != null) {
      try {
        // Clean markdown if AI adds it
        String cleanJson = result.replaceAll("```json", "").replaceAll("```", "").trim();
        List<dynamic> newWords = jsonDecode(cleanJson);
        
        setState(() {
          for (var item in newWords) {
            _vocabList.insert(0, Map<String, String>.from(item)); // Add to top
          }
        });
        
        // Save to History
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('vocab_history', jsonEncode(_vocabList));
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Parsing Error: $e")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Connection Failed (Check Key/Internet)")));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Search Logic
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
            tooltip: "Fetch New Words",
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
                hintText: "Search Database...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white
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
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 100, // Allow wrapping
                  columnSpacing: 25,
                  columns: const [
                    DataColumn(label: Text("WORD", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("HINDI", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("SYNONYM", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("ANTONYM", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("SENTENCE", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: displayList.map((d) => DataRow(cells: [
                    DataCell(Text(d['word']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    DataCell(Text(d['hindi']!, style: const TextStyle(color: Colors.deepOrange))),
                    DataCell(SizedBox(width: 100, child: Text(d['syn']!, overflow: TextOverflow.visible))),
                    DataCell(SizedBox(width: 100, child: Text(d['ant']!, overflow: TextOverflow.visible))),
                    DataCell(SizedBox(width: 200, child: Text(d['use']!, style: const TextStyle(fontStyle: FontStyle.italic), overflow: TextOverflow.visible))),
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

  // The Skeleton Menu
  final Map<String, List<String>> _topics = {
    "Tenses": ["Present Simple", "Present Continuous", "Past Simple", "Future Simple"],
    "Parts of Speech": ["Noun", "Pronoun", "Verb", "Adjective", "Adverb"],
    "Voice": ["Active Voice", "Passive Voice"]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // AI Content Fetcher
  void _openTopic(String topic) async {
    // Check Cache logic (Simplified for demo)
    final prefs = await SharedPreferences.getInstance();
    String? content = prefs.getString('grammar_$topic');

    if (content == null) {
      // Fetch from AI
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      
      final prompt = "Explain English Grammar topic: '$topic'. Provide output in this format: Definition: [Def], Rules: [Rules], Examples: [Ex1, Ex2]. Keep it concise.";
      final aiRes = await AppData.askGemini(prompt);
      
      Navigator.pop(context); // Close loader

      if (aiRes != null) {
        content = aiRes;
        prefs.setString('grammar_$topic', aiRes); // Save
      } else {
        content = "Could not fetch data. Check internet connection.";
      }
    }
    
    // Show Content
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topic, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            Flexible(child: SingleChildScrollView(child: Text(content!, style: const TextStyle(fontSize: 16, height: 1.5)))),
            const SizedBox(height: 20),
          ],
        ),
      )
    );
  }

  void _checkGrammar() async {
    if (_checkCtrl.text.isEmpty) return;
    setState(() { _checking = true; _checkResult = ""; });
    
    final prompt = "Correct the grammar of this sentence: '${_checkCtrl.text}'. Provide only the corrected sentence. If correct, say 'Correct'.";
    final res = await AppData.askGemini(prompt);
    
    setState(() { _checking = false; _checkResult = res ?? "Error connecting to AI"; });
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
          // Tab 1: The Book (Skeleton)
          ListView(
            padding: const EdgeInsets.all(16),
            children: _topics.entries.map((entry) {
              return ExpansionTile(
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: entry.value.map((subTopic) => ListTile(
                  title: Text(subTopic),
                  leading: const Icon(Icons.bookmark_border, color: Colors.indigo),
                  onTap: () => _openTopic(subTopic),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                )).toList(),
              );
            }).toList(),
          ),
          
          // Tab 2: Live Checker
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _checkCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Type a sentence to check...",
                    border: OutlineInputBorder(),
                    hintText: "e.g., He go to school everyday."
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _checking ? null : _checkGrammar,
                  icon: const Icon(Icons.spellcheck),
                  label: _checking ? const Text("Checking...") : const Text("Check Grammar"),
                ),
                const SizedBox(height: 20),
                if (_checkResult.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Result:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        Text(_checkResult, style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  )
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
  // Passage Data
  String _passageTitle = "The Sample Story";
  String _passageBody = "This is a sample story to ensure the app is never empty. Click 'Refresh' to generate a new unique story from AI.";
  List<Map<String, dynamic>> _passageQA = [
    {"q": "What is this?", "a": "A sample story"}
  ];
  bool _loadingPassage = false;

  // Idioms Data
  final List<Map<String, String>> _idioms = AppData.idioms;

  // Cloze Data (Simple static for demo, dynamic is complex)
  final String _clozeText = "India is a (1) _____ country with (2) _____ cultures.";
  final Map<int, List<String>> _clozeOptions = {1: ["small", "vast", "tiny"], 2: ["diverse", "single", "no"]};
  final Map<int, String> _clozeAnswers = {1: "vast", 2: "diverse"};
  final Map<int, String> _userClozeSel = {};
  bool _clozeVerified = false;

  // AI Passage Generator
  void _generatePassage() async {
    setState(() => _loadingPassage = true);
    final prompt = "Write a short 100-word interesting non-fiction story. Then provide 2 multiple choice questions based on it. Output JSON keys: title, body, qa: [{q, a}]. No markdown.";
    
    final res = await AppData.askGemini(prompt);
    if (res != null) {
      try {
        final data = jsonDecode(res.replaceAll("```json", "").replaceAll("```", "").trim());
        setState(() {
          _passageTitle = data['title'];
          _passageBody = data['body'];
          _passageQA = List<Map<String, dynamic>>.from(data['qa']);
        });
      } catch (e) {
        debugPrint("Passage Parse Error: $e");
      }
    }
    setState(() => _loadingPassage = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reading Library"),
          bottom: const TabBar(labelColor: Colors.white, tabs: [Tab(text: "Passage"), Tab(text: "Cloze"), Tab(text: "Idioms")]),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _generatePassage, tooltip: "New Story")
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Passage
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loadingPassage) const LinearProgressIndicator(),
                Text(_passageTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 10),
                Text(_passageBody, style: const TextStyle(fontSize: 16, height: 1.6)),
                const Divider(height: 40),
                const Text("Comprehension Check:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ..._passageQA.map((qa) => ListTile(
                  title: Text("Q: ${qa['q']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Ans: ${qa['a']}", style: const TextStyle(color: Colors.green)),
                )).toList()
              ],
            ),
            
            // Tab 2: Cloze
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("Fill in the blanks:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
