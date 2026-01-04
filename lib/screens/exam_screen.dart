import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  List<Map<String, dynamic>>? _questions;
  final Map<int, String> _answers = {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  void _loadQuiz() async {
    setState(() => _questions = null);
    final res = await ApiService.fetchQuiz();
    setState(() { _questions = res; _submitted = false; _answers.clear(); });
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text("English Exam Results")),
        pw.Table.fromTextArray(
          data: <List<String>>[
            <String>['Question', 'Your Answer', 'Correct'],
            ...List.generate(_questions!.length, (i) => [
              _questions![i]['q'], 
              _answers[i] ?? "Skipped", 
              _questions![i]['ans']
            ])
          ]
        )
      ]
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    if (_questions == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text("Results")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const Text("Exam Completed!", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              ElevatedButton.icon(icon: const Icon(Icons.picture_as_pdf), label: const Text("Download PDF"), onPressed: _downloadPDF),
              TextButton(onPressed: _loadQuiz, child: const Text("Take New Exam"))
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Live Exam")),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _questions!.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final q = _questions![i];
                return ListTile(
                  title: Text("Q${i+1}: ${q['q']}"),
                  subtitle: Column(
                    children: q['options'].map<Widget>((o) => RadioListTile(
                      title: Text(o), value: o.toString(), groupValue: _answers[i], onChanged: (v) => setState(() => _answers[i] = v.toString())
                    )).toList(),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => setState(() => _submitted = true),
              child: const Text("SUBMIT EXAM"),
            ),
          )
        ],
      ),
    );
  }
}
