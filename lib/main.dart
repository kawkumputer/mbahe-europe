import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cotisation_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/member_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/member_cotisations_screen.dart';
import 'screens/admin_cotisations_screen.dart';

void main() {
  runApp(const MbaheEuropeApp());
}

class MbaheEuropeApp extends StatelessWidget {
  const MbaheEuropeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CotisationProvider()),
      ],
      child: MaterialApp(
        title: 'MBAHE Europe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/pending-approval': (context) => const PendingApprovalScreen(),
          '/member-home': (context) => const MemberHomeScreen(),
          '/admin-home': (context) => const AdminHomeScreen(),
          '/member-cotisations': (context) => const MemberCotisationsScreen(),
          '/admin-cotisations': (context) => const AdminCotisationsScreen(),
        },
      ),
    );
  }
}
