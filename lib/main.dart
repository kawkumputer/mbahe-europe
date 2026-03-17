import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/cotisation_provider.dart';
import 'providers/compte_rendu_provider.dart';
import 'providers/notification_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/member_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/member_cotisations_screen.dart';
import 'screens/admin_cotisations_screen.dart';
import 'screens/comptes_rendus_list_screen.dart';
import 'screens/compte_rendu_detail_screen.dart';
import 'screens/create_compte_rendu_screen.dart';
import 'screens/admin_payment_dashboard_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/about_screen.dart';
import 'screens/statuts_screen.dart';
import 'screens/reglement_screen.dart';
import 'screens/admin_members_screen.dart';
import 'screens/actualites_list_screen.dart';
import 'screens/actualite_detail_screen.dart';
import 'screens/create_actualite_screen.dart';
import 'screens/edit_actualite_screen.dart';
import 'providers/actualite_provider.dart';
import 'providers/bureau_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/bureau_screen.dart';
import 'screens/manage_mandats_screen.dart';
import 'screens/manage_bureau_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';

LocaleProvider? _localeProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  _localeProvider = LocaleProvider();
  await _localeProvider!.loadLocale();

  runApp(const MbaheEuropeApp());
}

class MbaheEuropeApp extends StatelessWidget {
  const MbaheEuropeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _localeProvider!),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CotisationProvider()),
        ChangeNotifierProvider(create: (_) => CompteRenduProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ActualiteProvider()),
        ChangeNotifierProvider(create: (_) => BureauProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, child) => MaterialApp(
          title: 'MBAHE Europe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('fr', 'FR'),
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
            '/comptes-rendus': (context) => const ComptesRendusListScreen(),
            '/compte-rendu-detail': (context) => const CompteRenduDetailScreen(),
            '/create-compte-rendu': (context) => const CreateCompteRenduScreen(),
            '/admin-payment-dashboard': (context) => const AdminPaymentDashboardScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/about': (context) => const AboutScreen(),
            '/statuts': (context) => const StatutsScreen(),
            '/reglement': (context) => const ReglementScreen(),
            '/admin-members': (context) => const AdminMembersScreen(),
            '/actualites': (context) => const ActualitesListScreen(),
            '/actualite-detail': (context) => const ActualiteDetailScreen(),
            '/create-actualite': (context) => const CreateActualiteScreen(),
            '/edit-actualite': (context) => const EditActualiteScreen(),
            '/bureau': (context) => const BureauScreen(),
            '/manage-mandats': (context) => const ManageMandatsScreen(),
            '/manage-bureau': (context) => const ManageBureauScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/admin-profile': (context) => const ProfileScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
          },
        ),
      ),
    );
  }
}
