import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class QuizScreen extends StatelessWidget {
  final String topic;
  const QuizScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final questions = Provider.of<AppState>(context).currentQuiz;

    return Scaffold(
      appBar: AppBar(title: Text("$topic Daily Quiz")),
      body: questions.isEmpty 
      ? const Center(child: Text("Press Refresh to load questions."))
      : ListView.builder(
          itemCount: questions.length,
          itemBuilder: (ctx, i) {
            final q = questions[i];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ExpansionTile(
                title: Text(q['q']),
                children: [
                  ...List.generate(4, (optIndex) => ListTile(
                    title: Text(q['options'][optIndex]),
                    leading: Icon(
                      optIndex == q['ans'] ? Icons.check : Icons.circle_outlined,
                      color: optIndex == q['ans'] ? Colors.green : Colors.grey,
                    ),
                  ))
                ],
              ),
            );
          },
        ),
    );
  }
}
