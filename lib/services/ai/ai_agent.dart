import 'agent_memory.dart';
import 'agent_tool.dart';
import 'campus_tools.dart';
import 'chat_model.dart';

/// What the agent produced for one message.
class AgentReply {
  const AgentReply({required this.text, this.toolUsed, this.usedModel = false});

  final String text;

  /// Tool that answered, or null when the chat model did.
  final String? toolUsed;

  /// True when the chat model answered rather than a tool.
  final bool usedModel;
}

/// The assistant: a chat model, a memory and a set of tools.
///
/// A message is answered by the best-scoring tool that can handle it, and by
/// the chat model when no tool applies. Every turn goes into memory, so a
/// follow-up like "and the 6 sharing one?" still has the earlier subject to
/// attach to.
///
/// Tools come first deliberately: they answer from the app's own data, so the
/// numbers are real rather than something a model produced.
class AiAgent {
  AiAgent({ChatModel? model, List<AgentTool>? tools, AgentMemory? memory})
    : memory = memory ?? AgentMemory(),
      model = model ?? const LocalChatModel(),
      tools = tools ?? defaultTools();

  final AgentMemory memory;
  final ChatModel model;
  final List<AgentTool> tools;

  /// Score below which a tool is not considered a match.
  static const matchThreshold = 0.1;

  /// The campus tools, with help last so it never outranks a real answer.
  static List<AgentTool> defaultTools() {
    final capabilities = <AgentTool>[
      const FormulaTool(),
      const HostelTool(),
      const CanteenTool(),
      const NoticeTool(),
    ];
    return [...capabilities, HelpTool(capabilities)];
  }

  /// Tools that could handle [message], best first.
  List<AgentTool> rank(String message) {
    final scored = <({AgentTool tool, double score})>[];
    for (final tool in tools) {
      final score = tool.score(message, memory);
      if (score > matchThreshold) scored.add((tool: tool, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((entry) => entry.tool).toList();
  }

  /// Answers [message], remembering both sides of the exchange.
  Future<AgentReply> send(String message) async {
    final trimmed = message.trim();
    memory.addUser(trimmed);

    for (final tool in rank(trimmed)) {
      try {
        final result = await tool.run(trimmed, memory);
        if (!result.handled) continue;
        result.facts.forEach(memory.remember);
        memory.addAssistant(result.text, toolUsed: tool.name);
        return AgentReply(text: result.text, toolUsed: tool.name);
      } catch (_) {
        // A failing tool must not take the whole reply down; try the next.
        continue;
      }
    }

    String reply;
    try {
      reply = await model.respond(trimmed, memory);
    } catch (_) {
      reply =
          'I could not reach the assistant just now. Try again, or ask me '
          'about notes, hostels, food, notices or jobs.';
    }
    memory.addAssistant(reply);
    return AgentReply(text: reply, usedModel: true);
  }

  void reset() => memory.clear();
}
