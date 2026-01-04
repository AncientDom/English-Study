import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  // 90 Minutes in seconds
  int _timeLeft = 90 * 60;
  Timer? _timer;
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // Index -> Option Index
  
  // Mock Exam Questions (30 items)
  final List<Map<String, dynamic>> _questions = List.generate(30, (index) => {
    "q": "Question ${index + 1}: Identify the synonym of 'ABANDON'.",
    "options": ["Keep", "Forsake", "Cherish", "Hold"],
    "ans": 1
  });

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _submitExam();
      }
    });
  }

  void _submitExam() {
    _timer?.cancel();
    // Calculate Score (+3 Correct, -1 Wrong)
    int score = 0;
    _answers.forEach((qIndex, selectedOpt) {
      if (selectedOpt == _questions[qIndex]['ans']) {
        score += 3;
      } else {
        score -= 1;
      }
    });

    final resultData = {
      "score": score,
      "total": _questions.length * 3,
      "answers": _answers,
      "questions": _questions
    };

    Provider.of<AppState>(context, listen: false).submitExam(resultData);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exam Submitted! Score: $score")));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerString {
    final minutes = (_timeLeft / 60).floor();
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Time: $_timerString"),
        actions: [
          TextButton(
            onPressed: _submitExam,
            child: const Text("SUBMIT", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Q${_currentIndex + 1}: ${q['q']}", style: const TextStyle(fontSize: 18)),
          ),
          ...List.generate(4, (optIndex) {
            return RadioListTile(
              title: Text(q['options'][optIndex]),
              value: optIndex,
              groupValue: _answers[_currentIndex],
              onChanged: (val) {
                setState(() => _answers[_currentIndex] = val as int);
              },
            );
          }),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                child: const Text("Previous"),
              ),
              ElevatedButton(
                onPressed: _currentIndex < _questions.length - 1 ? () => setState(() => _currentIndex++) : null,
                child: const Text("Next"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
