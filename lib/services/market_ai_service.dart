/// Local assistant for the marketplace chat.
///
/// Answers on-device so the chat works with no network and no API key. Each
/// intent has its own answer: the previous version returned the same hardcoded
/// price line to every message, including "Write Description".
class MarketAiService {
  /// Item categories recognised from a message, with the guidance to give.
  static const _categoryHints = <String, ({String label, String range})>{
    'phone': (label: 'a phone', range: 'Rs. 25,000 - 90,000'),
    'laptop': (label: 'a laptop', range: 'Rs. 60,000 - 180,000'),
    'calculator': (label: 'a calculator', range: 'Rs. 1,500 - 6,000'),
    'book': (label: 'a textbook', range: 'Rs. 800 - 3,000'),
    'earbud': (label: 'earbuds', range: 'Rs. 2,000 - 12,000'),
    'headphone': (label: 'headphones', range: 'Rs. 2,000 - 12,000'),
    'camera': (label: 'a camera', range: 'Rs. 35,000 - 150,000'),
    'bag': (label: 'a bag', range: 'Rs. 1,500 - 7,000'),
    'lamp': (label: 'a lamp', range: 'Rs. 1,200 - 4,500'),
    'bike': (label: 'a bicycle', range: 'Rs. 15,000 - 60,000'),
  };

  static String? _category(String message) {
    final text = message.toLowerCase();
    for (final entry in _categoryHints.entries) {
      if (text.contains(entry.key)) return entry.key;
    }
    return null;
  }

  /// Intent behind [message]: one of price, description, similar, greeting,
  /// help.
  static String intentOf(String message) {
    final text = message.toLowerCase();
    bool has(List<String> terms) => terms.any(text.contains);

    if (has(['price', 'cost', 'worth', 'how much', 'value'])) return 'price';
    if (has(['description', 'describe', 'write', 'listing text', 'caption'])) {
      return 'description';
    }
    if (has(['similar', 'compare', 'like this', 'find', 'search'])) {
      return 'similar';
    }
    if (has(['hi', 'hello', 'hey', 'good morning', 'good evening'])) {
      return 'greeting';
    }
    return 'help';
  }

  /// The assistant's reply to [message].
  static String reply(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return 'Tell me what you are selling and I can suggest a price, write '
          'the description, or find similar items on campus.';
    }

    final category = _category(trimmed);
    final hint = category == null ? null : _categoryHints[category];

    switch (intentOf(trimmed)) {
      case 'price':
        final opening = hint == null
            ? 'To price it well, start from what the item actually sells for '
                  'on campus, not what it cost new.'
            : 'Second-hand ${hint.label} on campus usually goes for around '
                  '${hint.range}, depending on condition.';
        return '$opening\n\n'
            '1. Search the marketplace for the same item and note the asking '
            'prices.\n'
            '2. Take 40-60% of the new price if it is a year or two old and '
            'in good condition.\n'
            '3. Add the box, charger or receipt to the listing: they let you '
            'hold a higher price.\n'
            '4. Price slightly above your minimum, so you have room to agree '
            'a discount.';
      case 'description':
        final noun = hint?.label ?? 'your item';
        return 'Here is a description you can adapt for $noun:\n\n'
            '"Selling $noun in good working condition. Used carefully for '
            '[how long]. Comes with [box / charger / accessories]. '
            '[Any marks or faults, stated honestly.] Available to collect on '
            'campus. Message me to arrange a time."\n\n'
            'Fill in the brackets, and keep the honest line about faults: '
            'buyers trust a listing that mentions them, and it prevents an '
            'argument at handover.';
      case 'similar':
        final what = hint?.label ?? 'your item';
        return 'To find items like $what:\n\n'
            '1. Go back to the Marketplace and search the main word, not the '
            'full title. "calculator" finds more than "Casio fx-991EX".\n'
            '2. Use the category filter to narrow it down.\n'
            '3. Compare the three closest listings on condition and what is '
            'included, not on price alone.';
      case 'greeting':
        return 'Hello. Tell me what you are selling and I can suggest a '
            'price, write the description, or find similar items on campus.';
      default:
        return 'I can help with three things:\n\n'
            '1. Suggest a price for what you are selling.\n'
            '2. Write the listing description.\n'
            '3. Find similar items already on the marketplace.\n\n'
            'Tell me the item, for example "price for my calculator".';
    }
  }
}
