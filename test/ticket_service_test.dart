import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/ticket_service.dart';

/// These mirror the limits in the tickets block of firestore.rules.
///
/// The rules are the real enforcement and are covered by
/// test/tickets_rules_test.mjs against the emulator. This checks the client
/// catches the same mistakes first, so an admin sees a sentence they can act
/// on instead of a raw permission-denied error.
void main() {
  String? check({
    String title = 'Talent Night 2026',
    String details = 'Sep 18 - Main Auditorium',
    String price = 'LKR 750',
    String imageUrl = '',
  }) => TicketService.validationError(
    title: title,
    details: details,
    price: price,
    imageUrl: imageUrl,
  );

  test('accepts a complete event', () {
    expect(check(), isNull);
  });

  test('accepts an event with no image, since the field is optional', () {
    expect(check(imageUrl: ''), isNull);
  });

  test('requires a title', () {
    expect(check(title: ''), isNotNull);
    expect(check(title: '   '), isNotNull);
  });

  test('refuses a title past the limit the rules allow', () {
    expect(check(title: 'x' * TicketService.titleLimit), isNull);
    expect(check(title: 'x' * (TicketService.titleLimit + 1)), isNotNull);
  });

  test('refuses date and venue past the limit', () {
    expect(check(details: 'x' * TicketService.detailsLimit), isNull);
    expect(check(details: 'x' * (TicketService.detailsLimit + 1)), isNotNull);
  });

  test('refuses a price past the limit', () {
    expect(check(price: 'x' * TicketService.priceLimit), isNull);
    expect(check(price: 'x' * (TicketService.priceLimit + 1)), isNotNull);
  });

  test('accepts a free event, because price is free text', () {
    expect(check(price: 'Free'), isNull);
  });

  test('refuses a plain-http image link', () {
    // An http image is blocked by the browser on an https page, so the card
    // would silently show the placeholder instead of the poster.
    expect(check(imageUrl: 'http://example.com/poster.jpg'), isNotNull);
    expect(check(imageUrl: 'https://example.com/poster.jpg'), isNull);
  });

  test('refuses an image link past the limit', () {
    final tooLong = 'https://${'x' * TicketService.imageUrlLimit}';
    expect(check(imageUrl: tooLong), isNotNull);
  });

  test('explains the problem rather than just failing', () {
    expect(check(title: ''), contains('title'));
    expect(check(imageUrl: 'http://example.com'), contains('https://'));
  });
}
