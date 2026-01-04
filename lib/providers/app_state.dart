import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppState with ChangeNotifier {
  // Mock Data (Simulating "Gathered from Internet")
  final List<Map<String, dynamic>> _vocabData = [
    {"q": "Antonym of CANDID", "options": ["Frank", "Deceptive", "Honest", "Open"], "ans": 1},
    {"q": "Synonym of ABATE", "options": ["Increase", "Reduce", "Observe", "Create"], "ans": 1},
    // Add 100+ items here in a real app
  ];

  final List<Map<String, dynamic>> _grammarData = [
    {"q": "Spot Error: She do not / know how / to swim.", "options": ["She do not", "know how", "to swim", "No Error"], "ans": 0},
    {"q": "Preposition: He died ___ malaria.", "options": ["of", "from", "by", "with"], "ans": 0},
  ];

  DateTime? _lastQuizUpdate;
  List<Map<String, dynamic>> _currentQuiz = [];
  Map<String, dynamic> _lastExamResult = {};

  AppState() {
    _loadPreferences();
  }

  // 1. 12-Hour Refresh Logic
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_quiz_update');
    if (timestamp != null) {
      _lastQuizUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    notifyListeners();
  }

  Future<void> refreshQuiz(String type, {bool force = false}) async {
    final now = DateTime.now();
    
    // Check if 12 hours passed or force refresh is clicked
    if (force || _lastQuizUpdate == null || now.difference(_lastQuizUpdate!).inHours >= 12) {
      // Simulate fetching new questions
      _currentQuiz = (type == 'Vocab') ? List.from(_vocabData) : List.from(_grammarData);
      _currentQuiz.shuffle(); // Randomize
      
      _lastQuizUpdate = now;
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('last_quiz_update', now.millisecondsSinceEpoch);
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get currentQuiz => _currentQuiz;

  // 2. Exam Submission Logic
  void submitExam(Map<String, dynamic> result) {
    _lastExamResult = result;
    notifyListeners();
  }

  Map<String, dynamic> get lastExamResult => _lastExamResult;
}
