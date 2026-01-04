import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'quiz_screen.dart';
import 'exam_screen.dart';
import 'result_screen.dart';

class SubjectScreen extends StatelessWidget {
  final String title;
  final String topic;

  const SubjectScreen({super.key, required this.title, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          _buildOption(context, "Study Material", Icons.library_books, () {
             // Navigate to Study Material (PDF/Text view)
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Loading Study Material from Cloud...")));
          }),
          _buildOption(context, "Daily Quiz (Refresh)", Icons.refresh, () {
             Provider.of<AppState>(context, listen: false).refreshQuiz(topic, force: true);
             Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(topic: topic)));
          }),
          _buildOption(context, "Exam (AFCAT Pattern)", Icons.timer, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamScreen()));
          }),
          _buildOption(context, "Answer Sheet", Icons.assignment_turned_in, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo, size: 30),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}
