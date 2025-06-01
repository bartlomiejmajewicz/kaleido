import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:script_editor/bloc/settings_bloc.dart';
import 'package:script_editor/models/authorisation.dart';
import 'package:script_editor/pages/authorization_page.dart';
import 'package:script_editor/pages/conform_page.dart';
import 'package:script_editor/pages/script_page.dart';
import 'package:script_editor/pages/settings_page.dart';
import 'package:script_editor/pages/validation_page.dart';

// prevents Android from blocking HTTP request (CERTIFICATE_VERIFY_FAILED)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  MediaKit.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Authorisation.initialize();

  MediaKit.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
        create: (_) => KeyNotifier(),
        child: BlocProvider(
          create: (context) => SettingsBloc()..add(SetValuesFromSharedPreferences()),
          child: const MyApp(),
        )),
  );
}

// class used to pass the keys pressed down the widget tree
class KeyNotifier extends ChangeNotifier {
  KeyEvent? _currentKeyEvent;
  KeyEvent? get currentKeyEvent => _currentKeyEvent;

  void updateKey(KeyEvent keyEvent) {
    _currentKeyEvent = keyEvent;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent keyEvent) {
        context.read<KeyNotifier>().updateKey(keyEvent);
      },
      child: MaterialApp(
        title: 'Script Editor',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

// CLASSES FOR THE NAVIGATION

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  bool isNavigationRailExtended = false;

  Timer? navigationRailExtendedTimer;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const SettingsPage();
      case 1:
        page = const ScriptPage(title: "script editor");
      case 2:
        page = const ValidationPage(title: "validation");
      case 3:
        page = ConformPage(title: "conform");
      case 4:
        page = AuthorizationPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: MouseRegion(
                onEnter: (event) {
                  navigationRailExtendedTimer =
                      Timer(const Duration(milliseconds: 800), () {
                    setState(() {
                      isNavigationRailExtended = true;
                    });
                  });
                },
                onExit: (event) {
                  if (navigationRailExtendedTimer != null) {
                    navigationRailExtendedTimer!.cancel();
                  }
                  setState(() {
                    isNavigationRailExtended = false;
                  });
                },
                child: NavigationRail(
                  extended: isNavigationRailExtended,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.playlist_play_rounded),
                      label: Text('Script editor'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.troubleshoot),
                      label: Text('Script validator')
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.cached_rounded),
                      label: Text('Script conform'),
                    ),
                    NavigationRailDestination(
                        icon: Icon(Icons.enhanced_encryption),
                        label: Text('License'))
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    if (!context.read<SettingsBloc>().state.isDataComplete() && value == 1) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const SimpleDialog(
                              children: [
                                Text(
                                  'You have to select all required options to continue',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          });
                    } else {
                      setState(() {
                        selectedIndex = value;
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}
