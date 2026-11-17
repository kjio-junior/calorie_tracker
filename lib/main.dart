import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme_controller.dart';
import 'core/widgets/gradient_background.dart';
import 'data/open_food_facts_service.dart';
import 'features/shell/app_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'state/activity_controller.dart';
import 'state/cheat_controller.dart';
import 'state/nav_controller.dart';
import 'state/ai_coach_controller.dart';
import 'state/connectivity_controller.dart';
import 'state/food_controller.dart';
import 'state/history_controller.dart';
import 'state/profile_controller.dart';
import 'state/reminder_controller.dart';
import 'state/ui_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final themeController = await ThemeController.load();
  final profileController = await ProfileController.load();
  final foodController = await FoodController.load();
  final activityController = await ActivityController.load();
  final historyController = await HistoryController.load(
    food: foodController,
    activity: activityController,
  );
  final reminderController = await ReminderController.load();
  final aiCoachController = await AiCoachController.load();
  final cheatController = await CheatController.load(food: foodController);
  final uiPrefs = await UiPrefs.load();
  final connectivity = await ConnectivityController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<ProfileController>.value(
          value: profileController,
        ),
        ChangeNotifierProvider<FoodController>.value(value: foodController),
        ChangeNotifierProvider<ActivityController>.value(
          value: activityController,
        ),
        ChangeNotifierProvider<HistoryController>.value(
          value: historyController,
        ),
        ChangeNotifierProvider<ReminderController>.value(
          value: reminderController,
        ),
        ChangeNotifierProvider<AiCoachController>.value(
          value: aiCoachController,
        ),
        ChangeNotifierProvider<CheatController>.value(value: cheatController),
        ChangeNotifierProvider<NavController>(create: (_) => NavController()),
        ChangeNotifierProvider<UiPrefs>.value(value: uiPrefs),
        ChangeNotifierProvider<ConnectivityController>.value(
          value: connectivity,
        ),
        Provider<OpenFoodFactsService>(
          create: (_) => OpenFoodFactsService(),
          dispose: (_, s) => s.dispose(),
        ),
      ],
      child: const CalorieApp(),
    ),
  );
}

class CalorieApp extends StatelessWidget {
  const CalorieApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();

    return MaterialApp(
      title: 'Calorie Tracker',
      debugShowCheckedModeBanner: false,
      theme: controller.materialTheme,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(controller.textScale)),
          child: GradientBackground(child: child!),
        );
      },
      home: const RootGate(),
    );
  }
}

/// Shows onboarding until a profile and first weigh-in exist, and refreshes
/// "today" whenever the app returns to the foreground (day rollover).
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FoodController>().refreshToday();
      context.read<ActivityController>().refreshToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context.watch<ProfileController>().onboarded;
    return onboarded ? const AppShell() : const OnboardingScreen();
  }
}
