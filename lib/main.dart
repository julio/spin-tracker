import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'vinyl_home_page.dart';
import 'auth/login_view.dart';
import 'services/discogs_auth_service.dart';

final _logger = Logger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const NeedlApp());
}

class NeedlApp extends StatefulWidget {
  const NeedlApp({super.key});

  static _NeedlAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_NeedlAppState>();
  }

  @override
  State<NeedlApp> createState() => _NeedlAppState();
}

class _NeedlAppState extends State<NeedlApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
    DiscogsAuthService().init();
  }

  void _initDeepLinks() {
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'needl' && uri.host == 'discogs-callback') {
      final oauthToken = uri.queryParameters['oauth_token'];
      final oauthVerifier = uri.queryParameters['oauth_verifier'];
      if (oauthToken != null && oauthVerifier != null) {
        DiscogsAuthService()
            .completeOAuthFlow(oauthToken, oauthVerifier)
            .then((username) {
          _logger.info('Discogs connected as $username');
        }).catchError((e) {
          _logger.severe('Discogs OAuth callback failed: $e');
        });
      }
    }
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    const lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF6200EE),
      onPrimary: Colors.white,
      secondary: Color(0xFF03DAC6),
      onSecondary: Colors.black,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xDE000000),
      error: Color(0xFFB00020),
      onError: Colors.white,
      surfaceContainerHighest: Color(0xFFF5F5F5),
    );

    const darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFBB86FC),
      onPrimary: Colors.black,
      secondary: Color(0xFF03DAC6),
      onSecondary: Colors.black,
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xDEFFFFFF),
      error: Color(0xFFCF6679),
      onError: Colors.black,
      surfaceContainerHighest: Color(0xFF2C2C2C),
    );

    return MaterialApp(
      title: 'Needl',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xDE000000),
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFFFFFFFF),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          indicatorColor: Color(0x1F6200EE),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x1F000000),
          space: 1,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Color(0xDEFFFFFF),
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          indicatorColor: Color(0x3DBB86FC),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0x1FFFFFFF),
          space: 1,
        ),
      ),
      themeMode: _themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const VinylHomePage();
        }
        return const LoginView();
      },
    );
  }
}
