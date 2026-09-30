import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/models/app_models.dart';
import 'package:unix_app/screens/marketplace/marketplace_screen.dart';

ProductItem item(String id, String category) => ProductItem(
  id: id,
  title: 'Item $id',
  category: category,
  price: 100,
  imageUrl: '',
  sellerName: 'Seller',
  sellerId: 'seller-1',
  rating: 0,
  reviewsCount: 0,
  description: 'Description',
);

void main() {
  testWidgets('Filters categories and search and displays new book cards', (
    tester,
  ) async {
    final stream = StreamController<List<ProductItem>>();
    addTearDown(stream.close);
    await tester.pumpWidget(
      MaterialApp(home: MarketplaceScreen(productStream: stream.stream)),
    );
    final products = [item('book', 'Books'), item('calculator', 'Electronics')];
    stream.add(products);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Books'));
    await tester.pumpAndSettle();
    expect(find.text('Item book'), findsOneWidget);
    expect(find.text('Item calculator'), findsNothing);
    stream.add([...products, item('new book', 'Books')]);
    await tester.pumpAndSettle();
    expect(find.text('Item new book'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'new book');
    await tester.pumpAndSettle();
    expect(find.text('Item book'), findsNothing);
    expect(find.text('Item new book'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
