import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/admin_service.dart';

AdminUser user({
  String uid = 'u1',
  String name = 'Nimal Perera',
  String email = 'nimal@sltc.ac.lk',
  String role = 'Student',
  bool blocked = false,
}) =>
    AdminUser(uid: uid, name: name, email: email, role: role, blocked: blocked);

void main() {
  group('AdminUser.displayName', () {
    test('falls back when the profile has no name saved', () {
      expect(user(name: '').displayName, '(no name set)');
      expect(user(name: '   ').displayName, '(no name set)');
    });

    test('trims a saved name', () {
      expect(user(name: '  Nimal  ').displayName, 'Nimal');
    });
  });

  group('AdminUser.initial', () {
    test('uppercases the first letter', () {
      expect(user(name: 'nimal').initial, 'N');
    });

    test('never returns half a surrogate pair', () {
      // A name starting with an astral character must still render one glyph.
      final initial = user(name: '\u{1F600} Nimal').initial;
      expect(initial.runes.length, 1);
      expect(initial, '\u{1F600}');
    });

    test('falls back to the email when no name is saved', () {
      expect(user(name: '', email: 'kamala@sltc.ac.lk').initial, 'K');
    });

    test('falls back to a question mark when name and email are empty', () {
      expect(user(name: '', email: '').initial, '?');
    });
  });

  group('AdminUser.isAdmin', () {
    test('recognises an approved admin email', () {
      expect(user(email: 'amashanki191@gmail.com').isAdmin, isTrue);
    });

    test('is case insensitive', () {
      expect(user(email: 'AMASHANKI191@Gmail.com').isAdmin, isTrue);
    });

    test('rejects an ordinary student', () {
      expect(user(email: 'nimal@sltc.ac.lk').isAdmin, isFalse);
    });
  });

  group('AdminUser.matches', () {
    final target = user(name: 'Nimal Perera', email: 'nimal@sltc.ac.lk');

    test('an empty search keeps every account', () {
      expect(target.matches(''), isTrue);
      expect(target.matches('   '), isTrue);
    });

    test('matches on name, email and role regardless of case', () {
      expect(target.matches('nimal'), isTrue);
      expect(target.matches('PERERA'), isTrue);
      expect(target.matches('sltc.ac.lk'), isTrue);
      expect(target.matches('student'), isTrue);
    });

    test('excludes accounts that do not match', () {
      expect(target.matches('kamala'), isFalse);
    });
  });
}
