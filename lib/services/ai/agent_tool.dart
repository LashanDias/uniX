import 'agent_memory.dart';

/// What a tool produced.
class ToolResult {
  const ToolResult({
    required this.text,
    this.handled = true,
    this.facts = const {},
  });

  /// Reply to show the student.
  final String text;

  /// False when the tool decided it was not the right one after all, so the
  /// agent should keep looking.
  final bool handled;

  /// Anything worth remembering for later turns, e.g. {'item': 'calculator'}.
  final Map<String, String> facts;

  static const notHandled = ToolResult(text: '', handled: false);
}

/// Something the agent can do, beyond talking.
///
/// A tool owns one capability and decides for itself whether a message is
/// meant for it. Keeping that decision inside the tool means adding a new
/// capability is one new class rather than another branch in a growing
/// if-chain.
abstract class AgentTool {
  const AgentTool();

  /// Short name, shown when explaining what the assistant can do.
  String get name;

  /// One line describing the capability, used in the help reply.
  String get description;

  /// Words that suggest this tool. Used for a quick first pass.
  List<String> get triggers;

  /// How well this tool fits [message], from 0 to 1.
  ///
  /// The default counts trigger words. Override for something sharper.
  double score(String message, AgentMemory memory) {
    final text = message.toLowerCase();
    final hits = triggers.where(text.contains).length;
    if (hits == 0) return 0;
    return (hits / triggers.length).clamp(0.15, 1);
  }

  /// Runs the tool. Return [ToolResult.notHandled] to defer to another.
  Future<ToolResult> run(String message, AgentMemory memory);
}
