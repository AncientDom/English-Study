import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = Provider.of<AppState>(context).lastExamResult;

    if (result.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Answer Sheet")),
        body: const Center(child: Text("No exam taken yet.")),
      );
    }

    final questions = result['questions'] as List;
    final answers = result['answers'] as Map;
    final score = result['score'];

    return Scaffold(
      appBar: AppBar(title: const Text("Last Exam Result")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Total Score: $score", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              itemBuilder: (ctx, i) {
                final q = questions[i];
                final userAnswer = answers[i];
                final correctAnswer = q['ans'];
                final isCorrect = userAnswer == correctAnswer;
                
                return Card(
                  color: isCorrect ? Colors.green.shade50 : (userAnswer == null ? Colors.white : Colors.red.shade50),
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text("Q${i+1}: ${q['q']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your Answer: ${userAnswer != null ? q['options'][userAnswer] : 'Skipped'}"),
                        Text("Correct Answer: ${q['options'][correctAnswer]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
