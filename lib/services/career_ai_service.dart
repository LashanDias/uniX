class CareerAiService {
  static Future<String> analyze(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return 'Career AI returned no analysis.';
    }

    final keywords = trimmed.toLowerCase().split(RegExp(r'\s+'));
    final interest = keywords.where((word) => word.length >= 4).take(4).join(', ');
    return 'Local career assistant analyzed "$trimmed". Priority focus: $interest. Connect a hosted AI endpoint to enable full Gemini-style advice.';
  }
}
