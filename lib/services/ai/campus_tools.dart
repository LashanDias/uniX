import '../boarding_store.dart';
import '../girls_hostel_inventory.dart';
import '../notice_board_service.dart';
import '../reference_sheets.dart';
import '../restaurant_catalog.dart';
import 'agent_memory.dart';
import 'agent_tool.dart';

/// Looks up a formula or a revision sheet.
class FormulaTool extends AgentTool {
  const FormulaTool();

  @override
  String get name => 'Formula lookup';

  @override
  String get description => 'Find a formula and when to use it.';

  @override
  List<String> get triggers => const [
    'formula',
    'variance',
    'standard deviation',
    'mean',
    'probability',
    'bayes',
    'complexity',
    'big-o',
    'big o',
    'equation',
  ];

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async {
    final needle = message.toLowerCase();

    for (final sheet in ReferenceSheets.all) {
      for (final entry in sheet.entries) {
        if (!needle.contains(entry.title.toLowerCase())) continue;
        final formulas = entry.formulas.entries
            .map((f) => f.key.isEmpty ? f.value : '${f.key}: ${f.value}')
            .join('\n');
        return ToolResult(
          text:
              '${entry.title} (${sheet.title} sheet)\n\n$formulas\n\n'
              'When to use it:\n'
              '${entry.whenToUse.map((w) => '• $w').join('\n')}\n\n'
              'Open Notes → Formula reference sheets for the full sheet.',
          facts: {'lastFormula': entry.title},
        );
      }
    }

    final sheets = ReferenceSheets.all
        .where((sheet) => sheet.matches(message))
        .toList();
    if (sheets.isEmpty) return ToolResult.notHandled;

    return ToolResult(
      text:
          'I have these formula sheets: '
          '${sheets.map((s) => s.title).join(', ')}.\n\n'
          'Name a formula, for example "variance" or "Bayes", and I will '
          'give you it with when to use it.',
    );
  }
}

/// Answers hostel room and price questions.
class HostelTool extends AgentTool {
  const HostelTool();

  @override
  String get name => 'Hostel rooms';

  @override
  String get description => 'Room availability and rent for the girls hostel.';

  @override
  List<String> get triggers => const [
    'hostel',
    'room',
    'sharing',
    'rent',
    'accommodation',
    'boarding',
    'annex',
    'stay',
  ];

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async {
    final lower = message.toLowerCase();

    if (lower.contains('boarding') || lower.contains('annex')) {
      final category = lower.contains('annex')
          ? BoardingCategory.annex
          : BoardingCategory.boarding;
      final places = BoardingStore.seeded
          .where((place) => place.category == category)
          .toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      if (places.isEmpty) return ToolResult.notHandled;
      final lines = places
          .map((p) => '• ${p.name} — ${p.distanceLabel}, ${p.kind}')
          .join('\n');
      return ToolResult(
        text:
            '${category.label} near campus, nearest first:\n\n$lines\n\n'
            'Open Hostels → ${category.label} for addresses, phone numbers '
            'and directions.',
      );
    }

    final sixSharing = GirlsHostelInventory.monthlyPrice(6);
    final fourSharing = GirlsHostelInventory.monthlyPrice(4);

    if (lower.contains('price') ||
        lower.contains('rent') ||
        lower.contains('cost') ||
        lower.contains('how much')) {
      return ToolResult(
        text:
            'Girls hostel (HUB 02) rent, per room:\n\n'
            '• 4-sharing — LKR $fourSharing per month, '
            'LKR ${GirlsHostelInventory.weeklyPrice(4)} per week\n'
            '• 6-sharing — LKR $sixSharing per month, '
            'LKR ${GirlsHostelInventory.weeklyPrice(6)} per week\n\n'
            'A 6-sharing room is cheaper per room and per bed.',
        facts: {'topic': 'hostel'},
      );
    }

    var free = 0;
    for (var floor = 0; floor < GirlsHostelInventory.floors.length; floor++) {
      free += GirlsHostelInventory.availableOn(floor).length;
    }
    return ToolResult(
      text:
          'The girls hostel (HUB 02) has ${GirlsHostelInventory.totalRooms} '
          'rooms across ${GirlsHostelInventory.floors.length} floors, '
          '${GirlsHostelInventory.roomsPerFloor} per floor: '
          '${GirlsHostelInventory.sixSharingPerFloor} six-sharing and '
          '${GirlsHostelInventory.fourSharingPerFloor} four-sharing on each.\n\n'
          '$free rooms currently have a free bed. Rent is LKR $fourSharing '
          'per month for 4-sharing and LKR $sixSharing for 6-sharing.',
      facts: {'topic': 'hostel'},
    );
  }
}

/// Answers questions about campus food.
class CanteenTool extends AgentTool {
  const CanteenTool();

  @override
  String get name => 'Canteen menus';

  @override
  String get description => 'What the canteens serve and what it costs.';

  @override
  List<String> get triggers => const [
    'food',
    'eat',
    'canteen',
    'restaurant',
    'menu',
    'lunch',
    'breakfast',
    'dinner',
    'rice',
    'hungry',
  ];

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async {
    final lower = message.toLowerCase();

    final dishes = [
      for (final place in restaurantCatalog)
        for (final dish in place.menu)
          if (lower.contains(dish.name.toLowerCase().split(' ').first))
            (place: place.name, dish: dish),
    ];
    if (dishes.isNotEmpty) {
      final lines = dishes
          .take(5)
          .map(
            (d) =>
                '• ${d.dish.name} — LKR ${d.dish.price.toStringAsFixed(0)} '
                'at ${d.place}',
          )
          .join('\n');
      return ToolResult(text: 'Found these:\n\n$lines');
    }

    final vegetarian = lower.contains('veg');
    final matching = [
      for (final place in restaurantCatalog)
        for (final dish in place.menu)
          if (!vegetarian || dish.vegetarian) (place: place.name, dish: dish),
    ];
    if (matching.isEmpty) return ToolResult.notHandled;

    matching.sort((a, b) => a.dish.price.compareTo(b.dish.price));
    final cheapest = matching
        .take(5)
        .map(
          (d) =>
              '• ${d.dish.name} — LKR ${d.dish.price.toStringAsFixed(0)} '
              'at ${d.place}',
        )
        .join('\n');
    return ToolResult(
      text:
          '${restaurantCatalog.length} places to eat near campus. '
          '${vegetarian ? 'Cheapest vegetarian dishes' : 'Cheapest dishes'}:'
          '\n\n$cheapest\n\n'
          'Open Restaurants to see menus and place an order.',
      facts: {'topic': 'food'},
    );
  }
}

/// Answers what is on at the campus, from the notice board.
class NoticeTool extends AgentTool {
  const NoticeTool();

  @override
  String get name => 'Notices and events';

  @override
  String get description => 'What is happening on campus and when.';

  @override
  List<String> get triggers => const [
    'notice',
    'event',
    'happening',
    'agm',
    'club',
    'today',
    'tomorrow',
    'announcement',
    'exam result',
  ];

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async {
    // The sample board is compiled in, so this answers offline. Live notices
    // need Firestore, which the board itself reads.
    final notices = NoticeBoardService.sortForBoard(
      NoticeBoardService.sampleNotices(),
    );
    if (notices.isEmpty) return ToolResult.notHandled;

    final lines = notices
        .take(4)
        .map((n) {
          final when = n.whenLabel;
          return '• ${n.title}${when == null ? '' : ' ($when)'} — ${n.category}';
        })
        .join('\n');
    return ToolResult(
      text:
          'On the notice board right now:\n\n$lines\n\n'
          'Open Notice Board for the full text and any flyers. Events that '
          'have already happened drop off automatically.',
      facts: {'topic': 'notices'},
    );
  }
}

/// Explains what the assistant can do.
class HelpTool extends AgentTool {
  const HelpTool(this.others);

  /// The other tools, so help stays correct when one is added or removed.
  final List<AgentTool> others;

  @override
  String get name => 'Help';

  @override
  String get description => 'List what the assistant can do.';

  @override
  List<String> get triggers => const [
    'help',
    'what can you do',
    'how do you work',
    'commands',
    'options',
  ];

  @override
  Future<ToolResult> run(String message, AgentMemory memory) async {
    final lines = others
        .map((tool) => '• ${tool.name} — ${tool.description}')
        .join('\n');
    return ToolResult(
      text: 'I can look things up across the app:\n\n$lines\n\n'
          'Just ask in your own words, for example "how much is a 6 sharing '
          'room" or "what is the variance formula".',
    );
  }
}
