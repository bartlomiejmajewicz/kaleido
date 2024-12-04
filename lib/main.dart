
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/pages/script_page.dart';
import 'package:script_editor/pages/settings_page.dart';

void main() {
  if (kDebugMode && Platform.isMacOS) {
    SettingsClass.sheetName = "Arkusz1";
    SettingsClass.videoFilePath = "/Volumes/Macintosh HD/Users/bmajewicz/Desktop/Mix With Phil Allen/Mixing+in+the+box+with+Phil+Allen+-+00+Drum+Cleanup.mp4";
    SettingsClass.scriptFilePath = "/Volumes/Macintosh HD/Users/bmajewicz/Desktop/Zeszyt1.xlsx";
  }
  if (kDebugMode && Platform.isAndroid) {
    SettingsClass.sheetName = "Script";
    SettingsClass.videoFilePath = "/data/user/0/com.example.script_editor/cache/file_picker/1733260531214/Friends.S08E21-The One with the Cooking Class.720p.bluray-sujaidr.mp4";
    SettingsClass.scriptFilePath = "/data/user/0/com.example.script_editor/cache/file_picker/1733260552163/Friends.S08E21-The One with the Cooking Class.720p.bluray-sujaidr.xlsx";
  }
  MediaKit.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create:(_) => KeyNotifier(),
      child: const MyApp()),
      );
    
}

// class used to pass the keys pressed down the widget tree
class KeyNotifier extends ChangeNotifier {
  KeyEvent? _currentKeyEvent;
  KeyEvent? get currentKeyEvent => _currentKeyEvent;

  void updateKey(KeyEvent keyEvent){
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
        //home: ScriptPage(title: "script editor"),
        //home: SettingsPage()
      ),
    );
  }

}





class PaddingTableRow extends TableRow{
  PaddingTableRow({List<Widget> children = const <Widget>[]}) : super(children: children.map((child) => Padding(padding: const EdgeInsets.all(10.0), child: child)).toList());

}



// CLASSES FOR THE NAVIGATION

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const SettingsPage();
      case 1:
        page = const ScriptPage(title: "script editor");
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: false,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.playlist_play_rounded),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  if(!SettingsClass.isDataComplete()){
                    showDialog(context: context, builder: (BuildContext context){
                        return const SimpleDialog(
                            children: [
                              Text('You have to select all required options to continue',
                                textAlign: TextAlign.center,),
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