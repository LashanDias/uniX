import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'models/app_models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_otp_screen.dart';
import 'screens/auth/new_password_screen.dart';
import 'screens/main_layout.dart';
import 'screens/notes/notes_home_screen.dart';
import 'screens/notes/upload_notes_screen.dart';
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
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/recruiter/recruiter_dashboard_screen.dart';

void main() {
  runApp(const UnixApp());
}

class UnixApp extends StatelessWidget {
  const UnixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNIX Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/forgot_password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
          case '/reset_otp':
            return MaterialPageRoute(builder: (_) => const ResetPasswordOtpScreen());
          case '/new_password':
            return MaterialPageRoute(builder: (_) => const NewPasswordScreen());
          case '/main':
            return MaterialPageRoute(builder: (_) => const MainLayout());
          case '/notes':
            return MaterialPageRoute(builder: (_) => const NotesHomeScreen());
          case '/upload_notes':
            return MaterialPageRoute(builder: (_) => const UploadNotesScreen());
          case '/note_detail':
            final note = settings.arguments as NoteItem;
            return MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note));
          case '/marketplace':
            return MaterialPageRoute(builder: (_) => const MarketplaceScreen());
          case '/add_product':
            return MaterialPageRoute(builder: (_) => const AddProductScreen());
          case '/product_detail':
            final product = settings.arguments as ProductItem;
            return MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product));
          case '/ai_market_assistant':
            return MaterialPageRoute(builder: (_) => const AiMarketAssistantScreen());
          case '/jobs':
            return MaterialPageRoute(builder: (_) => const JobsHomeScreen());
          case '/career_passport':
            return MaterialPageRoute(builder: (_) => const CareerPassportScreen());
          case '/micro_gigs':
            return MaterialPageRoute(builder: (_) => const MicroGigsScreen());
          case '/hostels':
            return MaterialPageRoute(builder: (_) => const HostelsScreen());
          case '/lost_found':
            return MaterialPageRoute(builder: (_) => const LostFoundScreen());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/edit_profile':
            return MaterialPageRoute(builder: (_) => const EditProfileScreen());
          case '/recruiter':
            return MaterialPageRoute(builder: (_) => const RecruiterDashboardScreen());
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
