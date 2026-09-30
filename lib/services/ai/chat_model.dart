import 'package:cloud_functions/cloud_functions.dart';

import 'agent_memory.dart';

/// The language side of the agent: it answers when no tool applies.
abstract class ChatModel {
  const ChatModel();

  /// Short label, shown so a student knows whether they are talking to the
  /// on-device assistant or a hosted model.
  String get label;

  Future<String> respond(String message, AgentMemory memory);
}

/// Answers on-device, with no API key and no network.
///
/// This is the default. It recognises what a student is asking for and gives
/// a useful, specific answer rather than a canned line. It is deliberately
/// not pretending to be a large language model: when it does not know
/// something it says so and points at what the app can actually do.
class LocalChatModel extends ChatModel {
  const LocalChatModel();

  @override
  String get label => 'On-device assistant';

  /// Topic keywords mapped to the guidance to give.
  static const _guidance = <String, String>{
    'cv':
        'Keep your CV to one page. Lead every bullet with a verb and a number '
        'you can defend, and put your most relevant project first.',
    'interview':
        'Prepare three stories in STAR form (Situation, Task, Action, Result). '
        'Interviewers ask for examples far more often than definitions.',
    'internship':
        'Apply three to four months ahead, and ask a lecturer for a reference '
        'before you need it.',
    'exam':
        'Work from past papers rather than re-reading notes. You remember what '
        'you retrieve, not what you review.',
    'study':
        'Study in focused blocks with the phone in another room, and finish '
        'each block by writing down what you could not recall.',
    'budget':
        'Track what you actually spend for two weeks before setting a budget. '
        'Most student budgets fail because they are guesses.',
  };

  @override
  Future<String> respond(String message, AgentMemory memory) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return 'Ask me something, or tell me what you are trying to do.';
    }

    final lower = trimmed.toLowerCase();
    for (final entry in _guidance.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    if (RegExp(r'\b(hi|hello|hey|ayubowan)\b').hasMatch(lower)) {
      // The agent records the incoming message before asking the model, so
      // the opening greeting is the one where this is the only turn so far.
      final isOpening = memory.turns.length <= 1;
      return isOpening
          ? 'Hello. I can look things up across the app: notes, formulas, '
                'hostel rooms, canteen menus, marketplace prices, notices and '
                'jobs. What do you need?'
          : 'Still here. What else do you need?';
    }

    if (lower.contains('thank')) return 'Any time. Ask whenever you need.';

    // No tool matched and no topic recognised. Say so plainly rather than
    // inventing an answer.
    return 'I do not have an answer for that one. I can look up notes and '
        'formula sheets, hostel rooms and prices, canteen menus, marketplace '
        'listings, notices and events, or jobs. Try naming one of those.';
  }
}

/// Sends the conversation to a hosted model through Cloud Functions.
///
/// Only used when the build sets CAREER_AI_ENABLED and the function is
/// deployed. Everything is server side, so no API key is shipped in the app.
class HostedChatModel extends ChatModel {
  const HostedChatModel({this.callableName = 'assistantReply'});

  final String callableName;

  /// Whether this build was compiled with the hosted model switched on.
  static const isConfigured = bool.fromEnvironment('CAREER_AI_ENABLED');

  @override
  String get label => 'Hosted assistant';

  @override
  Future<String> respond(String message, AgentMemory memory) async {
    final response = await FirebaseFunctions.instance
        .httpsCallable(callableName)
        .call({'message': message, 'transcript': memory.transcript()});
    final data = response.data;
    if (data is! Map ||
        data['reply'] is! String ||
        (data['reply'] as String).trim().isEmpty) {
      throw StateError('The assistant returned no usable reply.');
    }
    return (data['reply'] as String).trim();
  }
}
