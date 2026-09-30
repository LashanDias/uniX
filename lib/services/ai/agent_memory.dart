/// Who said a turn in the conversation.
enum ChatRole { user, assistant }

/// One turn of a conversation.
class ChatTurn {
  const ChatTurn({
    required this.role,
    required this.text,
    required this.at,
    this.toolUsed,
  });

  final ChatRole role;
  final String text;
  final DateTime at;

  /// Name of the tool that produced this reply, when one did.
  final String? toolUsed;

  bool get isUser => role == ChatRole.user;
}

/// What the agent remembers about a conversation.
///
/// Without this every message is answered in isolation, so "how much is it?"
/// right after "I'm selling a calculator" has nothing to attach to. The memory
/// keeps recent turns and the subjects mentioned so a follow-up can be
/// resolved against what came before.
class AgentMemory {
  AgentMemory({this.maxTurns = 20});

  /// How many turns to keep. Older ones fall off the end.
  final int maxTurns;

  final List<ChatTurn> _turns = [];

  /// Facts the conversation has established, e.g. {'item': 'calculator'}.
  final Map<String, String> _facts = {};

  List<ChatTurn> get turns => List.unmodifiable(_turns);

  Map<String, String> get facts => Map.unmodifiable(_facts);

  bool get isEmpty => _turns.isEmpty;

  void add(ChatTurn turn) {
    _turns.add(turn);
    if (_turns.length > maxTurns) {
      _turns.removeRange(0, _turns.length - maxTurns);
    }
  }

  void addUser(String text, {DateTime? at}) =>
      add(ChatTurn(role: ChatRole.user, text: text, at: at ?? DateTime.now()));

  void addAssistant(String text, {String? toolUsed, DateTime? at}) => add(
    ChatTurn(
      role: ChatRole.assistant,
      text: text,
      at: at ?? DateTime.now(),
      toolUsed: toolUsed,
    ),
  );

  /// Records something the conversation established.
  void remember(String key, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _facts[key] = trimmed;
  }

  String? recall(String key) => _facts[key];

  /// The last thing the user said, or null if they have not spoken.
  String? get lastUserMessage {
    for (final turn in _turns.reversed) {
      if (turn.isUser) return turn.text;
    }
    return null;
  }

  /// Recent turns rendered for a model prompt, oldest first.
  String transcript({int limit = 8}) {
    final recent = _turns.length <= limit
        ? _turns
        : _turns.sublist(_turns.length - limit);
    return recent
        .map((t) => '${t.isUser ? 'Student' : 'Assistant'}: ${t.text}')
        .join('\n');
  }

  void clear() {
    _turns.clear();
    _facts.clear();
  }
}
