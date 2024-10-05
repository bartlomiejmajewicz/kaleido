import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:script_editor/classes.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

late final player = Player();
late final controller = VideoController(player);
int framerate = 25;
Timecode startTC = Timecode();


  @override
  void dispose(){
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: [
            videoPlayer(context),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                fpsSelector(),
                startTcEntryWidget(),
                const Text(
                  'You have pushed the button this many times:',
                ),
                ElevatedButton(
                  onPressed: (){},
                  child: Text("elevated")
                  ),
                TextButton(
                  onPressed: (){},
                  child: Text("text button"),
                  ),
                OutlinedButton(
                  onPressed: ()=>{},
                  child: Text("outlinedButt"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Center videoPlayer(BuildContext context){
    return Center(
      child: SizedBox(
        //width: MediaQuery.of(context).size.width,
        //height: MediaQuery.of(context).size.width * 9.0 / 16.0,
        width: 500,
        height: 500,
        // Use [Video] widget to display video output.
        child: Video(controller: controller),
      ),
    );
  }


  DropdownMenu fpsSelector(){
    return DropdownMenu(
      width: 200, // TODO szerokość zale
      label: const Text("set video framerate"),
      onSelected: (value) {
        framerate = value;
      },
      dropdownMenuEntries: const <DropdownMenuEntry>[
        DropdownMenuEntry(value: 24, label: "23.98 / 24 fps"),
        DropdownMenuEntry(value: 25, label: "25 fps"),
        DropdownMenuEntry(value: 30, label: "29,97 / 30 fps"),
      ],
      );
  }

  Widget startTcEntryWidget(){
    return Column(
      children: [
        const Text("entry start TC:"),
        Row(children: [
          Container(
            width: 50,
            child: TextFormField(
              initialValue: "00",
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (value != "") {
                  setStartTcFromTextField(0, int.parse(value));
                }
              },
            ),
          ),
          Text(":"),
          Container(
            width: 50,
            child: TextFormField(
              initialValue: "00",
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (value != "") {
                  setStartTcFromTextField(1, int.parse(value));
                }
              },
            ),
          ),
          Text(":"),
          Container(
            width: 50,
            child: TextFormField(
              initialValue: "00",
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (value != "") {
                  setStartTcFromTextField(2, int.parse(value));
                }
              },
            ),
          ),
          Text(":"),
          Container(
            width: 50,
            child: TextFormField(
              initialValue: "00",
              textAlign: TextAlign.center,
              onChanged: (value) {
                if (value != "") {
                  setStartTcFromTextField(3, int.parse(value));
                }
              },
            ),
          ),
        ],)
      ],
    );
  }


  void setStartTcFromTextField(int field, int value){
    // function changes video startTC from entry in the menu

    switch (field) {
      case 0:
        startTC.h = value;
      break;
      case 1:
        startTC.m = value;
      break;
      case 2:
        startTC.s = value;
      break;
      case 3:
        startTC.f = value;
      break;
    }

    print(startTC);
  }



}
