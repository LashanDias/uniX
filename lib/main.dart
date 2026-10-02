import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'services/app_check_service.dart';
import 'services/local_firebase.dart';
import 'services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'models/app_models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_otp_screen.dart';
import 'screens/auth/new_password_screen.dart';
import 'screens/main_layout.dart';
import 'screens/notes/notes_home_screen.dart';
import 'screens/notes/upload_notes_screen.dart';
import 'screens/notes/short_notes_screen.dart';
import 'screens/notes/reference_sheet_screen.dart';
import 'screens/notices/notice_board_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/notes/note_detail_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'screens/marketplace/add_product_screen.dart';
import 'screens/marketplace/product_detail_screen.dart';
import 'screens/marketplace/ai_market_assistant_screen.dart';
import 'screens/jobs/jobs_home_screen.dart';
import 'screens/jobs/career_passport_screen.dart';
import 'screens/jobs/micro_gigs_screen.dart';
import 'screens/hostels/hostels_screen.dart';
import 'screens/lost_found/lost_found_screen.dart';
import 'screens/restaurants/restaurants_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/activity/recent_activity_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/recruiter/recruiter_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/tickets/tickets_screen.dart';
import 'screens/marketplace/rental_flow_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: LocalFirebase.enabled
        ? LocalFirebase.options
        : DefaultFirebaseOptions.currentPlatform,
  );
  // Attest this client before anything talks to Firestore, so the backend can
  // tell a request from the real app apart from a script replaying a token.
  if (LocalFirebase.enabled) {
    await LocalFirebase.connect();
  } else {
    await AppCheckService.activate();
  }
  runApp(const UnixApp());
}

class UnixApp extends StatelessWidget {
  const UnixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNIX Mobile',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/forgot_password':
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen(),
            );
          case '/reset_otp':
            return MaterialPageRoute(
              builder: (_) => const ResetPasswordOtpScreen(),
            );
          case '/new_password':
            return MaterialPageRoute(builder: (_) => const NewPasswordScreen());
          case '/main':
            return MaterialPageRoute(builder: (_) => const MainLayout());
          case '/notes':
            return MaterialPageRoute(builder: (_) => const NotesHomeScreen());
          case '/upload_notes':
            return MaterialPageRoute(builder: (_) => const UploadNotesScreen());
          case '/notice_board':
            return MaterialPageRoute(builder: (_) => const NoticeBoardScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/formula_sheets':
            return MaterialPageRoute(
              builder: (_) => const ReferenceSheetsScreen(),
            );
          case '/short_notes':
            return MaterialPageRoute(builder: (_) => const ShortNotesScreen());
          case '/note_detail':
            final note = settings.arguments as NoteItem;
            return MaterialPageRoute(
              builder: (_) => NoteDetailScreen(note: note),
            );
          case '/marketplace':
            return MaterialPageRoute(builder: (_) => const MarketplaceScreen());
          case '/add_product':
            return MaterialPageRoute(builder: (_) => const AddProductScreen());
          case '/product_detail':
            final product = settings.arguments as ProductItem;
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            );
          case '/ai_market_assistant':
            return MaterialPageRoute(
              builder: (_) => const AiMarketAssistantScreen(),
            );
          case '/jobs':
            return MaterialPageRoute(builder: (_) => const JobsHomeScreen());
          case '/career_passport':
            return MaterialPageRoute(
              builder: (_) => const CareerPassportScreen(),
            );
          case '/micro_gigs':
            return MaterialPageRoute(builder: (_) => const MicroGigsScreen());
          case '/hostels':
            return MaterialPageRoute(builder: (_) => const HostelsScreen());
          case '/apply_hostel':
            return MaterialPageRoute(
              builder: (_) => ApplyHostelScreen(
                initialHostel: settings.arguments as String?,
              ),
            );
          case '/lost_found':
            return MaterialPageRoute(builder: (_) => const LostFoundScreen());
          case '/lost_item_detail':
            return MaterialPageRoute(
              // This route only ever shows the built-in sample items.
              builder: (_) => LostItemDetailScreen.example(
                title: settings.arguments as String? ?? 'Black wallet',
              ),
            );
          case '/report_item':
            return MaterialPageRoute(builder: (_) => const ReportItemScreen());
          case '/find_item':
            return MaterialPageRoute(builder: (_) => const FindItemScreen());
          case '/restaurants':
            return MaterialPageRoute(builder: (_) => const RestaurantsScreen());
          case '/recent_activity':
            return MaterialPageRoute(
              builder: (_) => const RecentActivityScreen(),
            );
          case '/notifications':
            return MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            );
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/edit_profile':
            return MaterialPageRoute(builder: (_) => const EditProfileScreen());
          case '/admin':
            return MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(),
            );
          case '/recruiter':
            return MaterialPageRoute(
              builder: (_) => const RecruiterDashboardScreen(),
            );
          case '/tickets':
            return MaterialPageRoute(builder: (_) => const TicketsScreen());
          case '/rental-flow':
            return MaterialPageRoute(builder: (_) => const RentalFlowScreen());
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}

/// Decides what the app opens on.
///
/// Previously `initialRoute: '/login'` sent everybody to the login form, so a
/// student who was already signed in had to type their password again on every
/// launch. This waits for Firebase to report the stored session and then opens
/// the right home screen, falling back to the login form when nobody is signed
/// in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  /// The signed-in user stream, or null when Firebase is not available.
  ///
  /// Widget tests pump `UnixApp` without calling `Firebase.initializeApp`, and
  /// a missing Firebase app should show the login form rather than crash.
  static Stream<User?>? _authState() {
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = _authState();
    if (authState == null) return const LoginScreen();
    return StreamBuilder<User?>(
      stream: authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StartupSplash();
        }
        if (snapshot.data == null) return const LoginScreen();
        return const _SignedInHome();
      },
    );
  }
}

/// Sends a signed-in user to the home screen their role expects.
class _SignedInHome extends StatelessWidget {
  const _SignedInHome();

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: AuthService.homeRoute(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _StartupSplash();
      }
      // If the profile could not be read, fall back to the student home
      // rather than stranding the user on a spinner.
      return snapshot.data == '/recruiter'
          ? const RecruiterDashboardScreen()
          : const MainLayout();
    },
  );
}

/// Shown for the moment it takes to read the stored session.
class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 88,
            width: 88,
            child: Image(
              image: AssetImage('assets/images/unix_logo.png'),
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    ),
  );
}

/// Lets a mouse drag any scrollable, not just a finger.
///
/// Flutter leaves mouse dragging off by default, so on the web the horizontal
/// strips -- Quick Access, the restaurant filters, the notice board
/// categories -- looked scrollable but would not move when dragged. Set on
/// MaterialApp so every scrollable in the app behaves the same way.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
