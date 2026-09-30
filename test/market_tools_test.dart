import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/ai/agent_memory.dart';
import 'package:unix_app/services/ai/ai_agent.dart';
import 'package:unix_app/services/ai/market_tools.dart';

void main() {
  group('SellingTool', () {
    const tool = SellingTool();

    test('handles a pricing question', () async {
      final result = await tool.run('suggest price', AgentMemory());
      expect(result.handled, isTrue);
      expect(result.facts['sellingIntent'], 'price');
    });

    test('handles a description request differently', () async {
      final price = await tool.run('suggest price', AgentMemory());
      final description = await tool.run('write description', AgentMemory());
      expect(description.text, isNot(price.text));
      expect(description.facts['sellingIntent'], 'description');
    });

    test('defers a general question so another tool can take it', () async {
      // "help" is not a selling question, so this tool must step aside rather
      // than answering everything that reaches it.
      final result = await tool.run('what can you do', AgentMemory());
      expect(result.handled, isFalse);
    });

    test('defers a greeting', () async {
      final result = await tool.run('hello', AgentMemory());
      expect(result.handled, isFalse);
    });

    test('a bare follow-up still counts as selling after a selling turn', () {
      const tool = SellingTool();
      final fresh = AgentMemory();
      final afterSelling = AgentMemory()..remember('topic', 'selling');

      // "how much" alone scores on its own trigger, so use a phrase that only
      // makes sense with context.
      expect(tool.score('what about that', fresh), 0);
      expect(tool.score('what about that', afterSelling), greaterThan(0));
    });
  });

  group('CareerTool', () {
    const tool = CareerTool();

    test('answers a CV question', () async {
      final result = await tool.run('how do I improve my CV', AgentMemory());
      expect(result.handled, isTrue);
      expect(result.text, contains('I reviewed your message'));
      expect(result.facts['topic'], 'career');
    });

    test('defers an empty message', () async {
      final result = await tool.run('   ', AgentMemory());
      expect(result.handled, isFalse);
    });
  });

  group('agents built for each screen', () {
    test('the marketplace agent prefers selling help for a price question',
        () async {
      final agent = AiAgent(
        tools: [const SellingTool(), ...AiAgent.defaultTools()],
      );
      final reply = await agent.send('what price should I ask for my laptop');
      expect(reply.toolUsed, 'Selling help');
    });

    test('the marketplace agent can still answer a campus question', () async {
      // The point of the agent: the selling assistant is not trapped in one
      // subject, it reaches the same campus tools as everything else.
      final agent = AiAgent(
        tools: [const SellingTool(), ...AiAgent.defaultTools()],
      );
      final reply = await agent.send('how much is a 6 sharing hostel room');
      expect(reply.toolUsed, 'Hostel rooms');
      expect(reply.text, contains('8000'));
    });

    test('the career agent answers career questions', () async {
      final agent = AiAgent(
        tools: [const CareerTool(), ...AiAgent.defaultTools()],
      );
      final reply = await agent.send('how should I prepare for an interview');
      expect(reply.toolUsed, 'Career advice');
    });

    test('the career agent can also look up a formula', () async {
      final agent = AiAgent(
        tools: [const CareerTool(), ...AiAgent.defaultTools()],
      );
      final reply = await agent.send('give me the standard deviation formula');
      expect(reply.toolUsed, 'Formula lookup');
      expect(reply.text, contains('σ'));
    });

    test('memory carries across turns in one conversation', () async {
      final agent = AiAgent(
        tools: [const SellingTool(), ...AiAgent.defaultTools()],
      );
      await agent.send('I am selling my calculator, suggest a price');
      expect(agent.memory.recall('topic'), 'selling');
      expect(agent.memory.turns, hasLength(2));
    });
  });
}
