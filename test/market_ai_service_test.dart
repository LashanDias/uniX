import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/market_ai_service.dart';

void main() {
  group('intentOf', () {
    test('recognises a price question', () {
      expect(MarketAiService.intentOf('Suggest price'), 'price');
      expect(MarketAiService.intentOf('how much is this worth'), 'price');
    });

    test('recognises a description request', () {
      expect(MarketAiService.intentOf('Write Description'), 'description');
    });

    test('recognises a search request', () {
      expect(MarketAiService.intentOf('Find similar items'), 'similar');
    });

    test('recognises a greeting', () {
      expect(MarketAiService.intentOf('hello'), 'greeting');
    });

    test('falls back to help', () {
      expect(MarketAiService.intentOf('zxcv'), 'help');
    });
  });

  group('reply', () {
    test('gives a different answer to each preset button', () {
      // The bug this covers: every button returned the same hardcoded price
      // line, so "Write Description" answered with a price.
      final price = MarketAiService.reply('Suggest price');
      final description = MarketAiService.reply('Write Description');
      final similar = MarketAiService.reply('Find similar items');

      expect({price, description, similar}, hasLength(3));
    });

    test('a description request never answers with a price range', () {
      final reply = MarketAiService.reply('Write Description');
      expect(reply, isNot(contains('42,000')));
      expect(reply.toLowerCase(), contains('condition'));
    });

    test('a price request talks about pricing', () {
      final reply = MarketAiService.reply('Suggest price');
      expect(reply.toLowerCase(), contains('price'));
    });

    test('uses the item category when the message names one', () {
      final reply = MarketAiService.reply('price for my calculator');
      expect(reply, contains('calculator'));
      expect(reply, contains('Rs.'));
    });

    test('still answers usefully when no category is named', () {
      final reply = MarketAiService.reply('what price should I ask');
      expect(reply, isNotEmpty);
      expect(reply.toLowerCase(), contains('price'));
    });

    test('handles an empty message without throwing', () {
      expect(MarketAiService.reply('   '), isNotEmpty);
    });

    test('never returns the old hardcoded line', () {
      for (final message in [
        'Suggest price',
        'Write Description',
        'Find similar items',
        'hello',
        'anything else',
      ]) {
        expect(
          MarketAiService.reply(message),
          isNot(contains('Based on market analysis')),
        );
      }
    });
  });
}
