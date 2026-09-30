import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unix_app/models/app_models.dart';
import 'package:unix_app/screens/activity/recent_activity_screen.dart';
import 'package:unix_app/screens/auth/login_screen.dart';
import 'package:unix_app/screens/auth/signup_screen.dart';
import 'package:unix_app/screens/hostels/hostels_screen.dart';
import 'package:unix_app/screens/jobs/career_passport_screen.dart';
import 'package:unix_app/screens/jobs/jobs_home_screen.dart';
import 'package:unix_app/screens/jobs/micro_gigs_screen.dart';
import 'package:unix_app/screens/marketplace/marketplace_screen.dart';
import 'package:unix_app/screens/notes/notes_home_screen.dart';
import 'package:unix_app/screens/notifications/notifications_screen.dart';
import 'package:unix_app/screens/tickets/tickets_screen.dart';

/// Screens that can be built without a live Firebase app, by name.
///
/// Anything clipped on the right edge of a phone shows up here: a Row or
/// Column that cannot fit reports a RenderFlex overflow, which the test
/// framework surfaces as an exception.
final _screens = <String, Widget Function()>{
  'Notifications': () => const NotificationsScreen(),
  'Tickets': () => const TicketsScreen(),
  'Recent activity': () => const RecentActivityScreen(),
  'Jobs home': () => const JobsHomeScreen(),
  'Micro gigs': () => const MicroGigsScreen(),
  'Career passport': () => const CareerPassportScreen(),
  'Login': () => const LoginScreen(),
  'Signup': () => const SignupScreen(),
  'Hostels': () => const HostelsScreen(),
  'Hostel list': () => const HostelListScreen(gender: 'Boys'),
  'Hostel detail': () =>
      HostelDetailsScreen(hostel: HostelsScreen.hostels.first),
  'Marketplace': () => const MarketplaceScreen(productStream: Stream.empty()),
  'Notes home': () => const NotesHomeScreen(notesStream: Stream.empty()),
};

/// A small Android phone, a typical phone, and a large phone.
const _phoneWidths = [320.0, 360.0, 430.0];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in _phoneWidths) {
    for (final entry in _screens.entries) {
      testWidgets('${entry.key} fits at width $width', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 820));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(MaterialApp(home: entry.value()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Marketplace product detail fits on a small phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MarketplaceScreen(
          productStream: Stream.value([
            ProductItem(
              id: 'p1',
              title: 'A deliberately long listing title that must not clip',
              category: 'Books',
              price: 1250,
              imageUrl: '',
              sellerName: 'Nimal Perera',
              sellerId: 's1',
              rating: 0,
              reviewsCount: 0,
              description: 'Second-hand calculus textbook in good condition.',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
