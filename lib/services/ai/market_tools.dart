import '../career_ai_service.dart';
import '../market_ai_service.dart';
import 'agent_memory.dart';
import 'agent_tool.dart';

/// Helps a student sell something: pricing, description, finding similar.
///
/// Wraps the marketplace guidance so the agent can use it alongside the
/// campus tools, and records the item so a follow-up like "and the
/// description?" still knows what is being sold.
class SellingTool extends AgentTool {
  const SellingTool();

  @override
  String get name => 'Selling help';

  @override
  String get description =>
      'Suggest a price, write a listing description, find similar items.';

  @override
  List<String> get triggers => const [
    'price',
    'sell',
    'selling',
    'worth',
    'description',
    'describe',
    'listing',
    'similar',
    'how much',
    'value',
  ];

  @override
  double score(String message, AgentMemory memory) {
    final base = super.score(message, memory);
    // A bare "how much" right after a selling turn is still about selling.
    if (base == 0 && memory.recall('topic') == 'selling') {
      final lower = message.toLowerCase();
      if (lower.contains('how much') || lower.contains('what about')) {
        return 0.3;
      }
    }
    return base;
  }

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async {
    final intent = MarketAiService.intentOf(message);
    // "help" means the message was not really about selling, so let another
    // tool or the chat model take it.
    if (intent == 'help' || intent == 'greeting') return ToolResult.notHandled;

    return ToolResult(
      text: MarketAiService.reply(message),
      facts: {'topic': 'selling', 'sellingIntent': intent},
    );
  }
}

/// Career guidance: CVs, interviews, internships, skills.
class CareerTool extends AgentTool {
  const CareerTool();

  @override
  String get name => 'Career advice';

  @override
  String get description => 'CV, interview, internship and skills guidance.';

  @override
  List<String> get triggers => const [
    'cv',
    'resume',
    'interview',
    'internship',
    'career',
    'job',
    'vacancy',
    'apply',
    'skill',
    'linkedin',
    'portfolio',
    'salary',
  ];

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async {
    if (message.trim().isEmpty) return ToolResult.notHandled;
    return ToolResult(
      text: await CareerAiService.analyze(message),
      facts: const {'topic': 'career'},
    );
  }
}
