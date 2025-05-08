import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymaptest/config/theme/app_theme.dart';
import 'bindings/binding.dart';
import 'core/constants/color_constants.dart';
import 'core/routes/app_pages.dart';
import 'core/utils/logs.dart';
import 'features/authentication/handler/auth_handler.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await InitialBinding().dependencies();

    runApp(const MyApp());
  } catch (e) {
    DevLogs.logError('Initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Driver Companion',
      defaultTransition: Transition.cupertino,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      getPages: AppPages.routes,
      initialRoute: Routes.initialScreen,
      home: AuthHandler(),
    );
  }
}

