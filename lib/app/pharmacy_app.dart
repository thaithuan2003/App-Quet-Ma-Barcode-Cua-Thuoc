import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/services/auth_service.dart';
import 'shell_screen.dart';

class PharmacyApp extends StatefulWidget {
  const PharmacyApp({super.key});

  @override
  State<PharmacyApp> createState() => _PharmacyAppState();
}

class _PharmacyAppState extends State<PharmacyApp> {
  final TokenStorage _tokenStorage = TokenStorage();
  late final ApiClient _apiClient = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokenStorage: _tokenStorage,
    onUnauthorized: _handleSessionExpired,
  );
  late final AuthService _authService = AuthService(_apiClient, _tokenStorage);

  bool _loading = true;
  bool _signedIn = false;
  List<String> _roles = [];
  String? _loginMessage;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await _tokenStorage.readToken();
    final roles = await _tokenStorage.readRoles();
    setState(() {
      _signedIn = token != null;
      _roles = roles;
      _loading = false;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    setState(() {
      _signedIn = false;
      _roles = [];
      _loginMessage = null;
    });
  }

  Future<void> _handleSessionExpired() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _signedIn = false;
      _roles = [];
      _loginMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy Barcode',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF60A5FA),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F7FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFDCEEFF),
          foregroundColor: Color(0xFF0F172A),
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _signedIn
              ? ShellScreen(apiClient: _apiClient, roles: _roles, onLogout: _handleLogout)
              : LoginScreen(
                  authService: _authService,
                  message: _loginMessage,
                  onSignedIn: (session) => setState(() {
                    _signedIn = true;
                    _roles = session.roles;
                    _loginMessage = null;
                  }),
                ),
    );
  }
}
