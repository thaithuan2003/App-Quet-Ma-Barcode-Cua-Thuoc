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
  );
  late final AuthService _authService = AuthService(_apiClient, _tokenStorage);

  bool _loading = true;
  bool _signedIn = false;
  List<String> _roles = [];

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy Barcode',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _signedIn
              ? ShellScreen(apiClient: _apiClient, roles: _roles, onLogout: _handleLogout)
              : LoginScreen(
                  authService: _authService,
                  onSignedIn: (session) => setState(() {
                    _signedIn = true;
                    _roles = session.roles;
                  }),
                ),
    );
  }
}
