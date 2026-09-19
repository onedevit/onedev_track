import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/client_dashboard.dart';
import 'services/app_localizations.dart';

// مدير الثيم (فاتح / داكن) على مستوى التطبيق للتحكم فيه من أي مكان
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const FreelancePortalApp());
}

class FreelancePortalApp extends StatefulWidget {
  const FreelancePortalApp({super.key});

  @override
  State<FreelancePortalApp> createState() => _FreelancePortalAppState();
}

class _FreelancePortalAppState extends State<FreelancePortalApp> {
  Widget _homeScreen = const Scaffold(body: Center(child: CircularProgressIndicator()));

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');
    final loginTimeStr = prefs.getString('login_time');

    if (token != null && role != null && loginTimeStr != null) {
      final loginTime = DateTime.parse(loginTimeStr);
      final now = DateTime.now();
      
      if (now.difference(loginTime).inHours < 24) {
        setState(() {
          if (role == 'admin') {
            _homeScreen = const AdminDashboard();
          } else {
            _homeScreen = const ClientDashboard();
          }
        });
        return;
      } else {
        await prefs.clear();
      }
    }
    
    setState(() {
      _homeScreen = const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (_, Locale currentLocale, __) {
            final bool isRtl = currentLocale.languageCode == 'ar';

            return MaterialApp(
              title: AppLocalizations.tr('app_title'),
              debugShowCheckedModeBanner: false,
              locale: currentLocale,
              builder: (context, child) {
                return Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                );
              },
              themeMode: currentMode,
              theme: ThemeData(
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E293B), brightness: Brightness.light),
                useMaterial3: true,
                fontFamily: 'Segoe UI',
                scaffoldBackgroundColor: const Color(0xFFF8FAFC),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  foregroundColor: Color(0xFF1E293B),
                  elevation: 0,
                ),
                cardTheme: const CardThemeData(color: Colors.white, surfaceTintColor: Colors.white),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6), brightness: Brightness.dark),
                useMaterial3: true,
                fontFamily: 'Segoe UI',
                scaffoldBackgroundColor: const Color(0xFF0F172A),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1E293B),
                  surfaceTintColor: Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                cardTheme: const CardThemeData(color: Color(0xFF1E293B), surfaceTintColor: Color(0xFF1E293B)),
                dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E293B)),
              ),
              home: _homeScreen,
            );
          },
        );
      },
    );
  }
}
