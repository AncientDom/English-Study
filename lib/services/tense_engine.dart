class TenseEngine {
  static String identifyTense(String sentence) {
    String s = sentence.toLowerCase();
    
    // Future
    if (s.contains("will") || s.contains("shall") || s.contains("going to")) {
      return "Future Tense";
    }
    // Past
    else if (s.contains("was") || s.contains("were") || s.contains("had") || s.contains("did") || s.endsWith("ed ")) {
      return "Past Tense";
    }
    // Present
    else if (s.contains("is") || s.contains("are") || s.contains("am") || s.contains("has") || s.contains("have")) {
      return "Present Tense";
    }
    return "Simple Present (Likely)";
  }
}
