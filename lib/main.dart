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
// int videoWidth = 500;
// int videoHeight = 500;
double _sliderHeightValue = 200;
double _sliderWidthValue = 200;

late File videoFile;
File excelFile = new File("");
late dynamic excel;

bool _sheetSelectorActive = true;
//List<DropdownMenuEntry<String>> sheetsMenuEntry = List.empty(growable: true);
//List<DropdownMenuEntry<String>> sheetsMenuEntry = [];
List<String> sheetsList = List.empty(growable: true);



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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            videoPlayer(context),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                fpsSelector(),
                startTcEntryWidget(),
                OutlinedButton(
                  onPressed: selectVideoFile,
                  child: Text("Open video file...")
                  ),
                OutlinedButton(
                  onPressed: (){
                    selectExcelFile();
                  }  ,
                  child: Text("Open Script file..."),
                  ),
                sheetSelector(),
                OutlinedButton(
                  onPressed: saveScriptFile,
                  child: Text("Save script file"),
                  ),
                Text("Video Height:"),
                Slider(
                  min: 50,
                  max: MediaQuery.sizeOf(context).height,
                  value: _sliderHeightValue,
                  onChanged: (value){
                    setState(() {
                    _sliderHeightValue = value;
                    });
                  }
                ),
                Text("Video Width:"),
                Slider(
                  min: 50,
                  max: MediaQuery.sizeOf(context).width,
                  value: _sliderWidthValue,
                  onChanged: (value){
                    setState(() {
                    _sliderWidthValue = value;
                    });
                  }
                )
              ],
            ),
            Column(
              children: [
                OutlinedButton(onPressed: (){}, child: Text("Insert new TC..."))
              ],
            )
          ],
        ),
      ),
    );
  }



  Widget videoPlayer(BuildContext context){
    return SizedBox(
      child: SizedBox(
        //width: MediaQuery.of(context).size.width,
        //height: MediaQuery.of(context).size.width * 9.0 / 16.0,
        width: _sliderWidthValue,
        height: _sliderHeightValue,
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

  DropdownMenu<String> sheetSelector(){
    // TODO
    return DropdownMenu<String>(
    enabled: _sheetSelectorActive,
    width: 200, // TODO szerokość zale
    label: const Text("select excel sheet"),
    onSelected: (value) {
      print(value);
    },
    dropdownMenuEntries: getDropdownMenuEntries(),
    );
  }

  void saveScriptFile(){
    // TODO
    print("PLACEHOLDER");
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

  Future<void> selectVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
    File file = File(result.files.single.path!);
    player.open(Media(result.files.single.path!));
    } else {
    // User canceled the picker
    }
  }

  Future<void> selectExcelFile() async {
    // select the excel file, list the sheets and save the excel file to the var
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      excelFile = File(result.files.single.path!);
      var bytes = await excelFile.readAsBytesSync();
      excel = await Excel.decodeBytes(bytes);
      _sheetSelectorActive = true;
      for (var table in excel.tables.keys) {
        print(table); //sheet Name
        sheetsList.add(table);
      }
      setState(() {
        
      });
    } else {
    // User canceled the picker
    }
  }

  List<DropdownMenuEntry<String>> getDropdownMenuEntries() {
    return sheetsList.map((String item) {
      return DropdownMenuEntry<String>(
        value: item,
        label: item,
      );
    }).toList();
  }




  // List<ScriptNode> excelToNode(){
  //   List<ScriptNode> myList=[];
  //   file = '/Users/bmajewicz/Desktop/Zeszyt1.xlsx';
  //   bytes = File(file).readAsBytesSync();
  //   excel = Excel.decodeBytes(bytes);
  //   for (var table in excel.tables.keys) {
  //     print(table); //sheet Name
  //     //print(excel.tables[table]?.maxColumns);
  //     //print(excel.tables[table]?.maxRows);
  //     for (var row in excel.tables[table]!.rows) {
  //       int collNr = 0;
  //       ScriptNode scriptNode = ScriptNode.empty();
  //       for (var cell in row) {
  //         switch (collNr) {
  //           case 0:
  //             scriptNode.timecode = Timecode(cell.value.value.toString());
  //             break;
  //           case 1:
  //             scriptNode.charName = cell.value.value.toString();
  //             break;
  //           case 2:
  //             scriptNode.dial = cell.value.value.toString();
  //             break;
  //           default:
  //         }
  //         collNr++;
  //       }
  //       myList.add(scriptNode);
  //     }
  //   }
  //   print(myList.length);
  //   nodes = myList;
  //   return myList;
  // }



}
