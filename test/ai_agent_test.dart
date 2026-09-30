import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/ai/agent_memory.dart';
import 'package:unix_app/services/ai/agent_tool.dart';
import 'package:unix_app/services/ai/ai_agent.dart';
import 'package:unix_app/services/ai/campus_tools.dart';
import 'package:unix_app/services/ai/chat_model.dart';

/// A tool that always claims the message, for wiring tests.
class _AlwaysTool extends AgentTool {
  const _AlwaysTool(this.reply);

  final String reply;

  @override
  String get name => 'Always';

  @override
  String get description => 'Answers everything.';

  @override
  List<String> get triggers => const ['anything'];

  @override
  double score(String message, AgentMemory memory) => 1;

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async =>
      ToolResult(text: reply, facts: const {'topic': 'always'});
}

/// A tool that scores highly but then defers.
class _DeferringTool extends AgentTool {
  const _DeferringTool();

  @override
  String get name => 'Deferring';

  @override
  String get description => 'Never actually answers.';

  @override
  List<String> get triggers => const ['anything'];

  @override
  double score(String message, AgentMemory memory) => 1;

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async =>
      ToolResult.notHandled;
}

/// A tool that throws.
class _BrokenTool extends AgentTool {
  const _BrokenTool();

  @override
  String get name => 'Broken';

  @override
  String get description => 'Throws every time.';

  @override
  List<String> get triggers => const ['anything'];

  @override
  double score(String message, AgentMemory memory) => 1;

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async =>
      throw StateError('boom');
}

class _FailingModel extends ChatModel {
  const _FailingModel();

  @override
  String get label => 'Failing';

  @override
  Future<String> respond(String message, AgentMemory memory) async =>
      throw StateError('model down');
}

void main() {
  group('AgentMemory', () {
    test('keeps both sides of the conversation', () {
      final memory = AgentMemory();
      memory.addUser('hello');
      memory.addAssistant('hi');
      expect(memory.turns, hasLength(2));
      expect(memory.turns.first.isUser, isTrue);
      expect(memory.lastUserMessage, 'hello');
    });

    test('drops the oldest turns past its limit', () {
      final memory = AgentMemory(maxTurns: 3);
      for (var i = 0; i < 6; i++) {
        memory.addUser('message $i');
      }
      expect(memory.turns, hasLength(3));
      expect(memory.turns.first.text, 'message 3');
    });

    test('remembers facts the conversation established', () {
      final memory = AgentMemory()..remember('item', 'calculator');
      expect(memory.recall('item'), 'calculator');
    });

    test('ignores an empty fact', () {
      final memory = AgentMemory()..remember('item', '   ');
      expect(memory.recall('item'), isNull);
    });

    test('renders a transcript for a model prompt', () {
      final memory = AgentMemory()
        ..addUser('what is variance')
        ..addAssistant('It measures spread.');
      final transcript = memory.transcript();
      expect(transcript, contains('Student: what is variance'));
      expect(transcript, contains('Assistant: It measures spread.'));
    });

    test('clears everything on reset', () {
      final memory = AgentMemory()
        ..addUser('hi')
        ..remember('topic', 'food')
        ..clear();
      expect(memory.isEmpty, isTrue);
      expect(memory.facts, isEmpty);
    });
  });

  group('agent wiring', () {
    test('prefers a tool over the chat model', () async {
      final agent = AiAgent(tools: const [_AlwaysTool('from the tool')]);
      final reply = await agent.send('anything at all');
      expect(reply.text, 'from the tool');
      expect(reply.toolUsed, 'Always');
      expect(reply.usedModel, isFalse);
    });

    test('falls through to the next tool when one defers', () async {
      final agent = AiAgent(
        tools: const [_DeferringTool(), _AlwaysTool('second tool')],
      );
      final reply = await agent.send('anything');
      expect(reply.text, 'second tool');
      expect(reply.toolUsed, 'Always');
    });

    test('a throwing tool does not take the reply down', () async {
      final agent = AiAgent(
        tools: const [_BrokenTool(), _AlwaysTool('still answered')],
      );
      final reply = await agent.send('anything');
      expect(reply.text, 'still answered');
    });

    test('uses the chat model when no tool matches', () async {
      final agent = AiAgent(tools: const []);
      final reply = await agent.send('tell me about interviews');
      expect(reply.usedModel, isTrue);
      expect(reply.text.toLowerCase(), contains('star'));
    });

    test('a failing model still returns something useful', () async {
      final agent = AiAgent(tools: const [], model: const _FailingModel());
      final reply = await agent.send('anything');
      expect(reply.text, contains('could not reach'));
      expect(reply.text, isNotEmpty);
    });

    test('records every exchange in memory', () async {
      final agent = AiAgent(tools: const [_AlwaysTool('ok')]);
      await agent.send('first');
      await agent.send('second');
      expect(agent.memory.turns, hasLength(4));
      expect(agent.memory.lastUserMessage, 'second');
    });

    test('stores facts a tool reported', () async {
      final agent = AiAgent(tools: const [_AlwaysTool('ok')]);
      await agent.send('anything');
      expect(agent.memory.recall('topic'), 'always');
    });

    test('reset clears the conversation', () async {
      final agent = AiAgent(tools: const [_AlwaysTool('ok')]);
      await agent.send('anything');
      agent.reset();
      expect(agent.memory.isEmpty, isTrue);
    });
  });

  group('campus tools answer from real app data', () {
    late AiAgent agent;

    setUp(() => agent = AiAgent());

    test('hostel rent comes from the inventory, not invented', () async {
      final reply = await agent.send('how much is a 6 sharing room');
      expect(reply.toolUsed, 'Hostel rooms');
      expect(reply.text, contains('8000'));
      expect(reply.text, contains('9500'));
    });

    test('hostel question reports the real room structure', () async {
      final reply = await agent.send('tell me about the hostel');
      expect(reply.text, contains('69'));
      expect(reply.text, contains('23'));
    });

    test('a formula question returns the formula and when to use it', () async {
      final reply = await agent.send('what is the variance formula');
      expect(reply.toolUsed, 'Formula lookup');
      expect(reply.text, contains('σ²'));
      expect(reply.text, contains('When to use it'));
    });

    test('a food question lists real dishes with prices', () async {
      final reply = await agent.send('where can I eat lunch');
      expect(reply.toolUsed, 'Canteen menus');
      expect(reply.text, contains('LKR'));
    });

    test('a notices question lists what is on', () async {
      final reply = await agent.send('what events are happening');
      expect(reply.toolUsed, 'Notices and events');
      expect(reply.text, isNotEmpty);
    });

    test('help lists the other tools, not itself', () async {
      final reply = await agent.send('what can you do');
      expect(reply.toolUsed, 'Help');
      expect(reply.text, contains('Hostel rooms'));
      expect(reply.text, contains('Formula lookup'));
      expect(reply.text, isNot(contains('• Help')));
    });

    test('an unknown question admits it rather than inventing', () async {
      final reply = await agent.send('qqzz unrelated nonsense');
      expect(reply.usedModel, isTrue);
      expect(reply.text, contains('do not have an answer'));
    });

    test('a greeting is answered without a tool', () async {
      final reply = await agent.send('hello');
      expect(reply.usedModel, isTrue);
      expect(reply.text.toLowerCase(), contains('hello'));
    });
  });

  group('tool ranking', () {
    test('scores a matching tool above the threshold', () {
      final agent = AiAgent();
      expect(agent.rank('what is the variance formula'), isNotEmpty);
      expect(agent.rank('variance formula').first, isA<FormulaTool>());
    });

    test('ranks nothing for an unrelated message', () {
      expect(AiAgent().rank('qqzz'), isEmpty);
    });
  });

  group('hosted model', () {
    test('is off unless the build enables it', () {
      // Nothing should reach a hosted service by accident, and no API key is
      // shipped in the app either way.
      expect(HostedChatModel.isConfigured, isFalse);
    });

    test('the default agent uses the on-device model', () {
      expect(AiAgent().model, isA<LocalChatModel>());
      expect(AiAgent().model.label, 'On-device assistant');
    });
  });
}
