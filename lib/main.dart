import 'package:agri_direct/utils/theme/theme.dart';
import 'package:agri_direct/utils/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'features/authentication/screens/onboarding/onboarding.dart';
import 'features/authentication/screens/login/signIn.dart';
import 'features/home/Farmer/navigatorMenu/farmerNavigator_menu.dart';
import 'features/home/Buyer/navigatorMenu/buyerNavigator_menu.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // Determine initial screen: if a user is already signed-in, route them to their role navigator.
  Widget initialScreen;
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = (doc.exists ? (doc.data()?['role'] ?? 'Farmer') : 'Farmer').toString();
      if (role.toLowerCase() == 'buyer') {
        initialScreen = const BuyerNavigatorMenu();
      } else {
        initialScreen = const NavigatorMenu();
      }
    } catch (e) {
      // On any error fetching role, default to Farmer navigator so the user remains logged in.
      initialScreen = const NavigatorMenu();
    }
  } else {
    initialScreen = seenOnboarding ? const SignInScreen() : const OnboardingScreen();
  }

  runApp(ProviderScope(child: MyApp(initialScreen: initialScreen)));
}

class MyApp extends ConsumerWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      themeMode: themeMode,
      theme: UTheme.lightTheme,
      darkTheme: UTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      // Wrap initial screen in PermissionGate so we request location permission at startup
      home: PermissionGate(child: initialScreen),
    );
  }
}

/// PermissionGate requests location permission when the app launches and
/// optionally shows dialogs to guide the user if permission is denied.
class PermissionGate extends StatefulWidget {
  final Widget child;
  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLocationPermission());
  }

  Future<void> _ensureLocationPermission() async {
    try {
      LocationPermission status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        status = await Geolocator.requestPermission();
      }

      if (status == LocationPermission.denied) {
        // Show a simple dialog explaining why we need location and allow retry or continue without
        final retry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Location permission'),
            content: const Text('This app uses location to suggest nearby places and autofill addresses. Please allow location access.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Continue without')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Retry')),
            ],
          ),
        );
        if (retry == true) {
          await Geolocator.requestPermission();
        }
      } else if (status == LocationPermission.deniedForever) {
        // Permission permanently denied; ask user to go to settings
        final open = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Location permission required'),
            content: const Text('Please enable location permission from app settings to use location features.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Continue without')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Open settings')),
            ],
          ),
        );
        if (open == true) {
          await Geolocator.openAppSettings();
        }
      }
    } catch (e) {
      // ignore errors but proceed
    } finally {
      if (mounted) setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      // show a simple loading placeholder until permission flow completes
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
