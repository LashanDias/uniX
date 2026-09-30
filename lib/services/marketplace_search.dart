import '../models/app_models.dart';

List<ProductItem> marketplacePreview() => [
  for (final item in [
    ('Calculus book', 'Books', 1200.0, 'calculus_book.jfif'),
    ('Engineering Math', 'Books', 950.0, 'art:math'),
    ('Physics Book', 'Books', 1100.0, 'art:physics'),
    ('Programming Book', 'Books', 1400.0, 'art:programming'),
    ('Scientific calculator', 'Electronics', 3500.0, 'calculator.jfif'),
    ('Wireless earbuds', 'Electronics', 4500.0, 'earbuds.jfif'),
    ('Student smartphone', 'Electronics', 35000.0, 'art:phone'),
    ('DSLR camera', 'Electronics', 65000.0, 'art:camera'),
    ('USB study lamp', 'Electronics', 1800.0, 'art:lamp'),
    ('Handmade canvas art', 'Other', 1800.0, 'art:painting'),
    ('Handmade flower bouquet', 'Other', 2500.0, 'art:flowers'),
    ('Crochet keychain', 'Other', 650.0, 'art:craft'),
    ('Campus backpack', 'Other', 2200.0, 'backpack.jfif'),
    ('Study stationery set', 'Other', 900.0, 'art:stationery'),
  ])
    ProductItem(
      id: 'preview-${item.$1}',
      title: item.$1,
      category: item.$2,
      price: item.$3,
      imageUrl: item.$4.startsWith('art:')
          ? item.$4
          : 'assets/images/${item.$4}',
      sellerName: '',
      sellerId: '',
      rating: 0,
      reviewsCount: 0,
      description: 'Preview item, not a live listing.',
    ),
];

bool matchesMarketplaceSearch(ProductItem product, String query) {
  final words = query.trim().toLowerCase().split(RegExp(r'\s+'));
  final searchable = '${product.title} ${product.category}'.toLowerCase();
  return words.every((word) {
    final term = word.endsWith('s') && word.length > 3
        ? word.substring(0, word.length - 1)
        : word;
    if (term == 'bag') {
      return searchable.contains('bag') ||
          searchable.contains('backpack') ||
          searchable.contains('rucksack');
    }
    return searchable.contains(term);
  });
}
