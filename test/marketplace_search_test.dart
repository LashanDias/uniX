import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/marketplace_search.dart';

void main() {
  test('Book queries show the book-only marketplace preview', () {
    final items = marketplacePreview();

    for (final query in ['book', 'books', ' BOOK ']) {
      expect(
        items
            .where((p) => matchesMarketplaceSearch(p, query))
            .map((p) => p.title),
        [
          'Calculus book',
          'Engineering Math',
          'Physics Book',
          'Programming Book',
        ],
      );
    }

    expect(
      items
          .where((p) => matchesMarketplaceSearch(p, 'math'))
          .map((p) => p.title),
      ['Engineering Math'],
    );

    expect(items.where((p) => matchesMarketplaceSearch(p, '')).length, 14);
    expect(items.map((p) => p.category).toSet(), {
      'Books',
      'Electronics',
      'Other',
    });
    expect(
      items.where((p) => p.category == 'Books').map((p) => p.imageUrl).toSet(),
      hasLength(4),
    );
    expect(
      items.any(
        (p) => p.title.contains('camera') && p.category == 'Electronics',
      ),
      isTrue,
    );
    expect(
      items.any((p) => p.title.contains('bouquet') && p.category == 'Other'),
      isTrue,
    );
  });
}
