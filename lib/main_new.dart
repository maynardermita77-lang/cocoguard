import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CocoGuardApp());
}

class CocoGuardApp extends StatelessWidget {
  const CocoGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'CocoGuard',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF2d7a3e),
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2d7a3e),
              primary: const Color(0xFF2d7a3e),
              secondary: const Color(0xFFc6a030),
            ),
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2d7a3e),
              primary: const Color(0xFF2d7a3e),
              secondary: const Color(0xFFc6a030),
            ),
            scaffoldBackgroundColor: Colors.black,
          ),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
