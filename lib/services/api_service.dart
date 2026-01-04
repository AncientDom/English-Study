import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  
  // --- 1. VOCABULARY & POS ---
  static Future<Map<String, dynamic>?> fetchWordData(String word) async {
    try {
      final url = Uri.parse("https://api.dictionaryapi.dev/api/v2/entries/en/$word");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];
        
        // Get all parts of speech
        List<String> types = [];
        for (var meaning in data['meanings']) {
          types.add(meaning['partOfSpeech']);
        }

        return {
          "word": data['word'],
          "phonetic": data['phonetic'] ?? "",
          "types": types.toSet().toList(),
          "meaning": data['meanings'][0]['definitions'][0]['definition'],
          "example": data['meanings'][0]['definitions'][0]['example'] ?? "No example available",
          "synonyms": (data['meanings'][0]['synonyms'] as List?)?.take(3).join(", ") ?? "None"
        };
      }
    } catch (e) {
      print("Vocab Error: $e");
    }
    return null;
  }

  // --- 2. SENTENCE STRUCTURE (Datamuse) ---
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

  // --- 3. GRAMMAR CHECKER (LanguageTool) ---
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

  // --- 4. EXAM QUIZ (Open Trivia DB) ---
  static Future<List<Map<String, dynamic>>> fetchQuiz() async {
    try {
      // Category 10 = Books, Type = Multiple Choice
      final url = Uri.parse("https://opentdb.com/api.php?amount=10&category=10&type=multiple");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> questions = [];
        for (var item in data['results']) {
          List<String> opts = List<String>.from(item['incorrect_answers']);
          opts.add(item['correct_answer']);
          opts.shuffle();
          questions.add({
            "q": item['question'], 
            "ans": item['correct_answer'], 
            "options": opts
          });
        }
        return questions;
      }
    } catch (e) {
      print("Quiz Error: $e");
    }
    // Fallback offline question
    return [{"q": "Select the synonym of 'Happy'", "ans": "Joyful", "options": ["Sad", "Joyful", "Mad", "Angry"]}];
  }
}
