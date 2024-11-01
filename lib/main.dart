import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:script_editor/classes.dart';
import 'package:script_editor/resizableWidget.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:script_editor/widgetsMy.dart';

void main() {
  if (kDebugMode) {
    SettingsClass.sheetName = "Arkusz1";
    SettingsClass.videoFilePath = "/Volumes/Macintosh HD/Users/bmajewicz/Desktop/Mix With Phil Allen/Mixing+in+the+box+with+Phil+Allen+-+00+Drum+Cleanup.mp4";
    SettingsClass.scriptFilePath = "/Volumes/Macintosh HD/Users/bmajewicz/Desktop/Zeszyt1.xlsx";
  }
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Script Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
      //home: ScriptPage(title: "script editor"),
      //home: SettingsPage()
    );
  }
}


class ScriptPage extends StatefulWidget {
  const ScriptPage({super.key, required this.title});

  final String title;

  @override
  State<ScriptPage> createState() => _ScriptPageState();
}

class _ScriptPageState extends State<ScriptPage> {

late final player = Player();
late final controller = VideoController(player);
// int videoWidth = 500;
// int videoHeight = 500;
double _sliderHeightValue = 200;
double _sliderWidthValue = 400;

late double _screenWidth;
late double _screenHeight;


late File videoFile;
Duration currentPlaybackPosition = Duration();
late dynamic excel;

//List<DropdownMenuEntry<String>> sheetsMenuEntry = List.empty(growable: true);
//List<DropdownMenuEntry<String>> sheetsMenuEntry = [];
List<ScriptNode> _scriptTable = List.empty(growable: true);
List <DataRow> _dataRows = List.empty(growable: true);
late String sheetName;

ExcelFile? scriptSourceFile=null;


TextEditingController tempTextEditController = TextEditingController();
TextEditingController charNameOldTEC = TextEditingController();
TextEditingController charNameNewTEC = TextEditingController();

bool _firstInit=true;

  @override
  void dispose(){
    player.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {


    _screenWidth = MediaQuery.sizeOf(context).width;
    _screenHeight = MediaQuery.sizeOf(context).height;

    if(_firstInit){
      print("1st INIT");
      _sliderHeightValue = _screenHeight/3;
      _sliderWidthValue = _screenWidth/2;
      _firstInit = false;


      player.open(Media(SettingsClass.videoFilePath));
      // TODO: DO SPRAWDZENIA 
      player.stream.position.listen((e) {
        currentPlaybackPosition = e;
        markCurrentLine(_scriptTable);
      });
      scriptSourceFile = ExcelFile(SettingsClass.scriptFilePath);
      scriptSourceFile!.loadFile();
      scriptSourceFile!.importSheetToList(SettingsClass.sheetName, _scriptTable);
      setState(() {
        //_dataRows = scriptListToTable(_scriptTable);
        scriptListToTable(_scriptTable, _dataRows);
        sheetName = SettingsClass.sheetName;
      });
    }




    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   title: Text(widget.title),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                const Text("Video Height:"),
                  Slider(
                    min: 10,
                    max: _screenHeight,
                    value: _sliderHeightValue,
                    onChanged: (value){
                      setState(() {
                      _sliderHeightValue = value;
                      });
                    },
                  ),
                  const Text("Video Width:"),
                  Slider(
                    min: 10,
                    max: _screenWidth,
                    value: _sliderWidthValue,
                    onChanged: (value){
                      setState(() {
                      _sliderWidthValue = value;
                      });
                    }
                  )
              ],),
              videoPlayer(context),
              Column(
                children: [
                  SizedBox(
                    width: 200, 
                    child: TextFormField(
                      
                      //initialValue: temporaryStr,
                      //key: Key(temporaryStr),
                      controller: tempTextEditController,)),
                  OutlinedButton(onPressed: (){
                    newEntry(_scriptTable);
                    setState(() {
                      //_dataRows = scriptListToTable(_scriptTable);
                      scriptListToTable(_scriptTable, _dataRows);
                    });
                  }, child: const Text("new entry...")),
                  OutlinedButton(onPressed: saveFile, child: Text("SAVE FILE")),
                ],
              ),
              Column(
                children: [
                  Text("Replace the character name:"),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: charNameOldTEC,
                    )),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: charNameNewTEC,
                    )),
                  OutlinedButton(
                    onPressed: (){
                      int a = replaceCharName(charNameOldTEC.text, charNameNewTEC.text, _scriptTable);
                      setState(() {
                        scriptListToTable(_scriptTable, _dataRows);
                      });
                      showDialog(context: context, builder: (BuildContext context){
                        return SimpleDialog(
                            children: [
                              Text(
                                'Records affected: ${a.toString()}',
                                textAlign: TextAlign.center,),
                            ],
                        );
                      });
                    },
                    child: const Text("replace!")),
                ],
              )
            ],
          ),
          showTableAsListView()
          //justTable()
          ]
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

  void markCurrentLine(List<ScriptNode> scriptList){
    bool isThereAChange = false;
    for (var i = 0; i < scriptList.length; i++) {
      if (currentPlaybackPosition+SettingsClass.videoStartTc.tcAsDuration() < scriptList[i].tcIn.tcAsDuration() && !isThereAChange && i>0) {
        scriptList[i-1].isThisCurrentTCValueNotifier.value = true;
        isThereAChange = true;
      } else {
        scriptList[i].isThisCurrentTCValueNotifier.value = false;
      }
    }
  }






  List<DropdownMenuEntry<String>> getDropdownMenuEntries() {
    if(scriptSourceFile?.sheetsList == null){
      return [];
    }
    return scriptSourceFile!.sheetsList.map((String item) {
      return DropdownMenuEntry<String>(
        value: item,
        label: item,
      );
    }).toList();
  }


  Widget showTableAsListView(){
    HardwareKeyboard hardwareKeyboard = HardwareKeyboard.instance;
    return Flexible(
      child: KeyboardListener(
        onKeyEvent: (value) {
          if ((hardwareKeyboard.isMetaPressed || hardwareKeyboard.isControlPressed)
          && value.logicalKey == LogicalKeyboardKey.keyS
          && value.runtimeType == KeyDownEvent) {
            saveFile();
            print("FILE SAVED");
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("file saved!")));
          }
          
          
        },
        focusNode: FocusNode(),
        child: ListView(
          addAutomaticKeepAlives: false,
          shrinkWrap: false,
          children: [
            DataTable(columns: [
              //DataColumn(label: resizableGestureWidget("TC from player\nfrom script")),
              const DataColumn(
                mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.resizeColumn),
                label: ResizableGestureWidget(title: "TC from script\nto player")),
              const DataColumn(
                mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.resizeColumn),
                label: ResizableGestureWidget(title: "TC from player\nto script")),
              DataColumn(label: const Text("TC"),
                onSort:(columnIndex, ascending) {
                  //FIXME: sorting values
                  setState(() {
                  _scriptTable.sort();
                  scriptListToTable(_scriptTable, _dataRows);
                  //_dataRows = scriptListToTable(_scriptTable);
                  });
                },),
              const DataColumn(label: Text("character")),
              DataColumn(label: SizedBox(width: (_screenWidth>1200) ? _screenWidth-1000 : 200, child: Text("dialogue"))),
              const DataColumn(label: Text("Delete\nthe line")),
            ],
              rows: _dataRows,
            )
          ],
        ),
      ),
    );
  }

  


  void saveFile(){
    scriptSourceFile!.exportListToSheet(_scriptTable, sheetName);
    scriptSourceFile!.saveFile();
  }

  void jumpToTc(Timecode tc){
    player.seek((tc-SettingsClass.videoStartTc).tcAsDuration());
  }

  Timecode tcFromVideo(){
    print("TUTEJ: "+currentPlaybackPosition.toString());
    Timecode tc = Timecode();
    tc.tcFromDuration(currentPlaybackPosition);
    return tc;
  }


  void scriptListToTable(List<ScriptNode> scriptList, List<DataRow> myList){
    //myList = List.empty(growable: true);
    myList.clear();
    for (var scriptNode in scriptList) {
      myList.add(DataRow(cells: [
        DataCell(
          ValueListenableBuilder<bool>(valueListenable: scriptNode.isThisCurrentTCValueNotifier, builder: (context, value, child) {
            return ElevatedButton(
            style: scriptNode.isThisCurrentTCValueNotifier.value ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)) : ButtonStyle(),
            onPressed: (){
              jumpToTc(scriptNode.tcIn);
            },
            //child: Text("TC UP")))),
            child: Icon(Icons.arrow_upward));
          },)),
        
        DataCell(
          ElevatedButton(
            onPressed: (){
              scriptNode.tcIn = tcFromVideo()+SettingsClass.videoStartTc;
              scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
              setState(() {
          
              });
            },
            //child: Text("TC DOWN")))),
            child: Icon(Icons.arrow_downward))),
        
        DataCell(SizedBox( width: 100, child: TextFormField(
          //initialValue: scriptNode.timecode.toString(),
          //key: Key(scriptNode.timecode.toString()),
          // FIXME: popraw to, ze nie aktualizuje się cały czas
          controller: scriptNode.textControllerTc,
          onChanged: (value) {
            //FIXME:
            if(Timecode.tcValidateCheck(value)){
              scriptNode.tcIn = Timecode(value);
            }
            print(scriptNode.tcIn.toString());
          },
          inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],
          //style: TextStyle(backgroundColor: Colors.green),
          //style: TextStyle().apply(backgroundColor: Colors.amber),
          ))),
        
        DataCell(SizedBox( width: 200, child: TextFormField(
          initialValue: scriptNode.charName,
          key: Key(scriptNode.charName),
          onChanged: (value){
            scriptNode.charName = value;
          },
          ))),
       
        DataCell(
          TextFormField(
            onChanged: (value) => {
              scriptNode.dial = value
              // zobaczymy czy będzie to wystarczająco efficient ?
            },
            scribbleEnabled: false, 
            initialValue: scriptNode.dial, 
            maxLines: 10,
            key: Key(scriptNode.dial),)),
        //DataCell(SizedBox( width: 150, child: TextFormField(initialValue: scriptNode.charName))),
        //DataCell(TextFormField(initialValue: scriptNode.dial, maxLines: 10,)),
        DataCell(
          ElevatedButton(
            child: Icon(Icons.delete),
            onPressed: () {
              scriptList.remove(scriptNode);
              scriptListToTable(_scriptTable, _dataRows);
              setState(() {
                
              });
            },)),
      ]));
      scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
    }
}


  Future<void> _showPickerDialogCancelled(String whichFile) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Selector canceled'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('You have to select a $whichFile to continue'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  void newEntry(List<ScriptNode> scriptList) {
    Timecode timecode = Timecode();
    timecode.tcFromDuration(currentPlaybackPosition);
    scriptList.add(ScriptNode(timecode+SettingsClass.videoStartTc, tempTextEditController.text, "dialogue"));
  }

  TextEditingValue tcValidityInputCheck(TextEditingValue oldValue, TextEditingValue newValue) {
    String returnedValue="";
    //var tcPattern = RegExp(buildTimecodePattern(Timecode.framerate));
    var tcInProgressPattern = RegExp(r'^\d{0,2}:?\d{0,2}:?\d{0,2}:?\d{0,2}$');
    if (tcInProgressPattern.hasMatch(newValue.text)){
      returnedValue = newValue.text;

      if((returnedValue.length==2 || returnedValue.length==5 || returnedValue.length==8) && oldValue.text.length < newValue.text.length){
        returnedValue+= ":";
      }

    } else {
      returnedValue = oldValue.text;
    }
    return TextEditingValue(text: returnedValue);
  }


  int replaceCharName(String nameOld, String nameNew, List<ScriptNode> scriptList){

    int affected=0;
    for (var scriptNode in scriptList) {
      if (scriptNode.charName == nameOld) {
        scriptNode.charName = nameNew;
        affected++;
      }
    }
    return affected;
  }
}



class SettingsPage extends StatefulWidget {

  @override
  State<SettingsPage> createState() => _SettingsPageState();

}

class _SettingsPageState extends State<SettingsPage> {

  ExcelFile? excelFile;

  @override
  Widget build(BuildContext context) {
    if(SettingsClass.scriptFilePath.isNotEmpty){
      excelFile=ExcelFile(SettingsClass.scriptFilePath);
      excelFile!.loadFile();
    }
    return Scaffold(
      body: SizedBox(
        //width: MediaQuery.sizeOf(context).width,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: ListView(
            children: [
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  PaddingTableRow(
                    children: [
                    const Text("select video file:"),
                    OutlinedButton(onPressed: selectVideoFile, child: Text("select video file...")),
                    SelectableText("selected file: ${SettingsClass.videoFilePath}"),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select script file:"),
                    OutlinedButton(onPressed: selectScriptFile, child: Text("select script file...")),
                    SelectableText("selected file: ${SettingsClass.scriptFilePath}"),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select sheet:"),
                    sheetSelector(),
                    Text('selected sheet name: ${SettingsClass.sheetName}'),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select starting column: "),
                    TextFormField(
                      initialValue: "1", 
                      onChanged: (value) => setState((){SettingsClass.collNumber = (value!="") ? int.parse(value)-1 : 0;}),
                      inputFormatters: [TextInputFormatter.withFunction(numberValidityCheck)]
                    ),
                    Text('selected collumn: ${SettingsClass.collNumber+1}'),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select starting row: "),
                    TextFormField(
                      initialValue: "1", 
                      onChanged: (value) => setState((){SettingsClass.rowNumber = (value!="") ? int.parse(value)-1 : 0;}),
                      inputFormatters: [TextInputFormatter.withFunction(numberValidityCheck)]
                    ),
                    Text('selected row: ${SettingsClass.rowNumber+1}'),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select project framerate: "),
                    fpsSelector(),
                    Text('selected fps: ${Timecode.framerate}'),
                  ]),
                  PaddingTableRow(children: [
                    Text("starting TC: "),
                    SizedBox( width: 100, child: TextFormField(
                      initialValue: SettingsClass.videoStartTc.toString(),
                      onChanged: (value) {
                        //FIXME:
                        if(Timecode.tcValidateCheck(value)){
                          setState(() {
                            SettingsClass.videoStartTc = Timecode(value);
                          });
                        }
                      },
                      inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],
                      //style: TextStyle(backgroundColor: Colors.green),
                      //style: TextStyle().apply(backgroundColor: Colors.amber),
                    )),
                    Text(SettingsClass.videoStartTc.showTimecode())
                  ])
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> selectVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      SettingsClass.videoFilePath = result.files.single.path!;
      File file = File(result.files.single.path!);
      setState(() {
        
      });
    } else {
    // User canceled the picker
      _showPickerDialogCancelled('video file');
    }
  }


  Future<void> selectScriptFile() async {
    // select the excel file, list the sheets and save the excel file to the var
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xls', 'xlsx']);
    if (result != null) {
      SettingsClass.scriptFilePath = result.files.single.path!;
      excelFile = ExcelFile(result.files.single.path!);
      excelFile!.loadFile();
      setState(() {
        
      });
    } else {
    // User canceled the picker
      _showPickerDialogCancelled('script file');
    }
  }

  TextEditingValue numberValidityCheck(TextEditingValue oldValue, TextEditingValue newValue) {
    RegExp numberPattern = RegExp(r'^\d{0,2}$');
    if (numberPattern.hasMatch(newValue.text) && newValue.text!="0"){
      return newValue;
    } else {
      return oldValue;
    }  
  }

  DropdownMenu<String> sheetSelector(){
    return DropdownMenu<String>(
    enabled: SettingsClass.scriptFilePath.isNotEmpty,
    width: 200, // TODO: szerokość zalezna
    label: const Text("select excel sheet"),
    initialSelection: SettingsClass.sheetName.isNotEmpty ? SettingsClass.sheetName : null,
    onSelected: (value) {
      setState(() {
      SettingsClass.sheetName = value!;
      });
    },
    dropdownMenuEntries: getSheetsDropdownMenuEntries(),
    );
  }

  DropdownMenu fpsSelector(){
    return DropdownMenu(
      width: 200, // TODO: szerokość zale
      label: const Text("set video framerate"),
      onSelected: (value) {
        setState(() {
          Timecode.framerate = value;
        });
      },
      initialSelection: Timecode.framerate,
      dropdownMenuEntries: const <DropdownMenuEntry>[
        DropdownMenuEntry(value: 24, label: "23.98 / 24 fps"),
        DropdownMenuEntry(value: 25, label: "25 fps"),
        DropdownMenuEntry(value: 30, label: "29,97 / 30 fps"),
      ],
      );
  }

  List<DropdownMenuEntry<String>> getSheetsDropdownMenuEntries() {
    if(excelFile == null){
      return [];
    }
    if(excelFile?.sheetsList == null){
      return [];
    }
    return excelFile!.sheetsList.map((String item) {
      return DropdownMenuEntry<String>(
        value: item,
        label: item,
      );
    }).toList();
  }

  Future<void> _showPickerDialogCancelled(String whichFile) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selector canceled'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You have to select a $whichFile to continue'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  TextEditingValue tcValidityInputCheck(TextEditingValue oldValue, TextEditingValue newValue) {
    String returnedValue="";
    //var tcPattern = RegExp(buildTimecodePattern(Timecode.framerate));
    var tcInProgressPattern = RegExp(r'^\d{0,2}:?\d{0,2}:?\d{0,2}:?\d{0,2}$');
    if (tcInProgressPattern.hasMatch(newValue.text)){
      returnedValue = newValue.text;

      if((returnedValue.length==2 || returnedValue.length==5 || returnedValue.length==8) && oldValue.text.length < newValue.text.length){
        returnedValue+= ":";
      }

    } else {
      returnedValue = oldValue.text;
    }
    return TextEditingValue(text: returnedValue);
  }

}



class PaddingTableRow extends TableRow{
  PaddingTableRow({List<Widget> children = const <Widget>[]}) : super(children: children.map((child) => Padding(padding: const EdgeInsets.all(10.0), child: child)).toList());

}



// CLASSES FOR THE NAVIGATION

class MyHomePage extends StatefulWidget {
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
        page = SettingsPage();
      case 1:
        page = ScriptPage(title: "script editor");
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

                  if(SettingsClass.scriptFilePath.isEmpty
                  || SettingsClass.sheetName.isEmpty){
                    showDialog(context: context, builder: (BuildContext context){
                        return const SimpleDialog(
                            children: [
                              Text('You have to select all required options',
                                textAlign: TextAlign.center,),
                            ],
                        );
                      });
                  } else {
                    setState(() {
                      //TODO: sprawdź czy wszystkie parametry są wypełnione
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