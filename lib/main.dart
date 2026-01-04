import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFCAT Ultimate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// =======================
// 1. DATA ENGINE
// =======================
class AppData {
  // --- VOCABULARY ---
  static final List<Map<String, String>> vocabList = [
    {"word": "Abate", "hindi": "रोकथाम करना", "syn": "Lessen, Decrease", "ant": "Increase, Aggravate", "use": "The storm began to abate."},
    {"word": "Benevolent", "hindi": "परोपकारी", "syn": "Kind, Generous", "ant": "Cruel, Malevolent", "use": "He is a benevolent leader."},
    {"word": "Candid", "hindi": "स्पष्टवादी", "syn": "Frank, Honest", "ant": "Deceptive, Tricky", "use": "Please be candid with me."},
    {"word": "Diligent", "hindi": "मेहनती", "syn": "Hardworking", "ant": "Lazy", "use": "She is diligent in her work."},
  ];

  // --- READING: COMPREHENSION ---
  static const String passageTitle = "The Power of Persistence";
  static const String comprehensionPassage = 
      "Success requires not only talent but also persistence. Many people give up just when they are about to achieve their goal. "
      "Persistence is the quality that allows someone to continue doing something or trying to do something even though it is difficult or opposed by other people. "
      "Without persistence, talent is often wasted. History is full of examples of successful people who failed many times before finally succeeding.";

  static final List<Map<String, dynamic>> comprehensionQ = [
    {
      "q": "What is required for success besides talent?",
      "options": ["Money", "Persistence", "Luck", "Friends"],
      "ans": "Persistence"
    },
    {
      "q": "What happens to talent without persistence?",
      "options": ["It grows", "It is wasted", "It succeeds", "It is hidden"],
      "ans": "It is wasted"
    }
  ];

  // --- READING: CLOZE TEST ---
  static const String clozePassage = "India is a land of (1) _____ culture and heritage. People from (2) _____ religions live here together.";
  static final List<Map<String, dynamic>> clozeOptions = [
    {"blank": "1", "options": ["Poor", "Rich", "Empty", "Dull"], "ans": "Rich"},
    {"blank": "2", "options": ["One", "Diverse", "Single", "No"], "ans": "Diverse"}
  ];

  // --- QUIZ GENERATOR ---
  static List<Map<String, dynamic>> generateQuiz() {
    return List.generate(100, (index) {
      var wordData = vocabList[index % vocabList.length];
      return {
        "id": index + 1,
        "q": "Identify the SYNONYM of '${wordData['word']}'",
        "options": [wordData['syn']!.split(',')[0], "Wrong A", "Wrong B", "Wrong C"]..shuffle(),
        "ans": wordData['syn']!.split(',')[0]
      };
    });
  }
}

// =======================
// 2. MAIN NAVIGATION
// =======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final List<Widget> _screens = [
    const VocabScreen(), 
    const GrammarScreen(),
    const ReadingScreen(), // <--- NEW SCREEN ADDED HERE
    const QuizScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AFCAT Ultimate'), elevation: 2),
      body: _screens[_idx],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Required for 4+ items
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.table_view), label: 'Vocab'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Grammar'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Reading'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Exam'),
        ],
      ),
    );
  }
}

// =======================
// 3. READING SCREEN (THE MISSING PART)
// =======================
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.deepOrange, 
            tabs: [Tab(text: "COMPREHENSION"), Tab(text: "CLOZE TEST")]
          ),
          Expanded(
            child: TabBarView(children: [
              // 3.1 COMPREHENSION TAB
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppData.passageTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(AppData.comprehensionPassage, style: const TextStyle(fontSize: 16, height: 1.5)),
                    ),
                    const Divider(height: 30),
                    const Text("Questions:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ...AppData.comprehensionQ.map((q) => Card(
                      margin: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          ListTile(title: Text(q['q'], style: const TextStyle(fontWeight: FontWeight.bold))),
                          ...q['options'].map<Widget>((opt) => RadioListTile(
                            value: opt, 
                            groupValue: null, // Just for display
                            onChanged: (v){}, 
                            title: Text(opt)
                          )).toList()
                        ],
                      ),
                    )).toList()
                  ],
                ),
              ),

              // 3.2 CLOZE TEST TAB
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Instructions: Fill in the blanks.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(AppData.clozePassage, style: const TextStyle(fontSize: 18, height: 2.0, fontWeight: FontWeight.w500)),
                    const Divider(height: 30),
                    ...AppData.clozeOptions.map((blank) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Blank (${blank['blank']}):", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              children: blank['options'].map<Widget>((opt) => ActionChip(
                                label: Text(opt),
                                onPressed: () {}, // Interactive dummy buttons
                              )).toList(),
                            )
                          ],
                        ),
                      ),
                    )).toList()
                  ],
                ),
              ),
            ]),
          )
        ],
      ),
    );
  }
}

// =======================
// 4. VOCAB SCREEN
// =======================
class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});
  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  String _search = "";
  @override
  Widget build(BuildContext context) {
    final data = AppData.vocabList.where((e) => e['word']!.toLowerCase().contains(_search.toLowerCase())).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(labelText: "Search Directory", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _search = v),
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
                  DataColumn(label: Text("WORD", style: TextStyle(fontWeight: FontWeight.bold))), 
                  DataColumn(label: Text("HINDI", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("SYNONYM", style: TextStyle(fontWeight: FontWeight.bold))), 
                  DataColumn(label: Text("USE", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: data.map((d) => DataRow(cells: [
                  DataCell(Text(d['word']!)), 
                  DataCell(Text(d['hindi']!, style: const TextStyle(color: Colors.deepOrange))),
                  DataCell(Text(d['syn']!)), 
                  DataCell(Text(d['use']!, style: const TextStyle(fontStyle: FontStyle.italic))),
                ])).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =======================
// 5. GRAMMAR SCREEN
// =======================
class GrammarScreen extends StatelessWidget {
  const GrammarScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(labelColor: Colors.indigo, tabs: [Tab(text: "TENSES"), Tab(text: "PREPOSITIONS")]),
          Expanded(
            child: TabBarView(children: [
              ListView(padding: const EdgeInsets.all(16), children: const [
                Card(child: ListTile(title: Text("Present Simple"), subtitle: Text("Sub + V1 + s/es\nUse: Habitual Action"), isThreeLine: true)),
                Card(child: ListTile(title: Text("Past Simple"), subtitle: Text("Sub + V2\nUse: Completed Action"), isThreeLine: true)),
              ]),
              ListView(padding: const EdgeInsets.all(16), children: const [
                Card(child: ListTile(title: Text("AT"), subtitle: Text("Use: Specific Time (At 5 PM)"))),
                Card(child: ListTile(title: Text("IN"), subtitle: Text("Use: Enclosed Space (In the room)"))),
              ]),
            ]),
          )
        ],
      ),
    );
  }
}

// =======================
// 6. EXAM & PDF SCREEN
// =======================
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>>? questions;
  final Map<int, String> _answers = {};
  bool _submitted = false;

  void _start() {
    setState(() {
      questions = AppData.generateQuiz();
      _submitted = false;
      _answers.clear();
    });
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text("AFCAT Exam Results")),
        pw.Table.fromTextArray(
          data: <List<String>>[
            <String>['Q No', 'Question', 'Your Answer', 'Correct'],
            ...List.generate(questions!.length, (i) => [
              "${i+1}", questions![i]['q'], _answers[i] ?? "Skipped", questions![i]['ans']
            ])
          ]
        )
      ]
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    if (questions == null) {
      return Center(child: ElevatedButton.icon(icon: const Icon(Icons.play_arrow), label: const Text("Start 100 Qs Mock Exam"), onPressed: _start));
    }
    if (_submitted) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const Text("Exam Completed!", style: TextStyle(fontSize: 24)),
        const SizedBox(height: 20),
        ElevatedButton.icon(icon: const Icon(Icons.picture_as_pdf), label: const Text("Download PDF Answer Sheet"), onPressed: _downloadPDF),
        TextButton(onPressed: _start, child: const Text("Take New Exam"))
      ]));
    }
    return Column(children: [
      Expanded(child: ListView.separated(
        itemCount: questions!.length,
        separatorBuilder: (ctx, i) => const Divider(),
        itemBuilder: (ctx, i) {
          final q = questions![i];
          return ListTile(title: Text("Q${i+1}: ${q['q']}"), subtitle: Column(children: q['options'].map<Widget>((opt) => RadioListTile(
            title: Text(opt), value: opt.toString(), groupValue: _answers[i], onChanged: (v) => setState(() => _answers[i] = v.toString())
          )).toList()));
        },
      )),
      Container(width: double.infinity, padding: const EdgeInsets.all(10), child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        onPressed: () => setState(() => _submitted = true),
        child: const Text("SUBMIT EXAM")
      ))
    ]);
  }
}
