import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:script_editor/classes.dart';
import 'package:script_editor/resizableWidget.dart';
import 'package:numberpicker/numberpicker.dart';

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
Timecode startTC = Timecode();
// int videoWidth = 500;
// int videoHeight = 500;
double _sliderHeightValue = 200;
double _sliderWidthValue = 400;

late double _screenWidth;
late double _screenHeight;


late File videoFile;
Duration currentPlaybackPosition = Duration();
late dynamic excel;

bool _sheetSelectorActive = true;
//List<DropdownMenuEntry<String>> sheetsMenuEntry = List.empty(growable: true);
//List<DropdownMenuEntry<String>> sheetsMenuEntry = [];
List<ScriptNode> _scriptTable = List.empty(growable: true);
List <DataRow> _dataRows = List.empty(growable: true);
late String sheetName;

ExcelFile? scriptSourceFile=null;

static String temporaryStr = "";

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
      });
      scriptSourceFile = ExcelFile(SettingsClass.scriptFilePath);
      scriptSourceFile!.loadFile();
      scriptSourceFile!.importSheetToList(SettingsClass.sheetName, _scriptTable);
      setState(() {
        //_dataRows = scriptListToTable(_scriptTable);
        scriptListToTable(_scriptTable, _dataRows);
        sheetName = SettingsClass.sheetName;
      });

      startTC = SettingsClass.videoStartTc;
      

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
                      showDialog(context: context, builder: (BuildContext context){
                        return SimpleDialog(
                            children: [
                              Text(
                                'Records affected: ${replaceCharName(charNameOldTEC.text, charNameNewTEC.text, _scriptTable).toString()}',
                                textAlign: TextAlign.center,),
                            ],
                        );
                      });



                      // TODO: toast - ile rekordów zmieniono
                      scriptListToTable(_scriptTable, _dataRows);
                      setState(() {
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

  DropdownMenu fpsSelector(){
    return DropdownMenu(
      width: 200, // TODO: szerokość zale
      label: const Text("set video framerate"),
      onSelected: (value) {
        Timecode.framerate = value;
      },
      dropdownMenuEntries: const <DropdownMenuEntry>[
        DropdownMenuEntry(value: 24, label: "23.98 / 24 fps"),
        DropdownMenuEntry(value: 25, label: "25 fps"),
        DropdownMenuEntry(value: 30, label: "29,97 / 30 fps"),
      ],
      );
  }

  DropdownMenu<String> sheetSelector(){
    return DropdownMenu<String>(
    enabled: _sheetSelectorActive,
    width: 200, // TODO: szerokość zalezna
    label: const Text("select excel sheet"),
    onSelected: (value) {
      scriptSourceFile!.importSheetToList(value!, _scriptTable);
      //importSheetToList(value!, _scriptTable);
      setState(() {
        //_dataRows = scriptListToTable(_scriptTable);
        scriptListToTable(_scriptTable, _dataRows);
        sheetName = value;
      });
    },
    dropdownMenuEntries: getDropdownMenuEntries(),
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      File file = File(result.files.single.path!);
      player.open(Media(result.files.single.path!));
      // TODO: DO SPRAWDZENIA 
      player.stream.position.listen((e) {
        currentPlaybackPosition = e;
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
      // excelFile = File(result.files.single.path!);
      // var bytes = await excelFile.readAsBytesSync();
      // excel = await Excel.decodeBytes(bytes);
      // _sheetSelectorActive = true;
      // for (var table in excel.tables.keys) {
      //   print(table); //sheet Name
      //   sheetsList.add(table);
      // }
      //ExcelFile myExcelFile = ExcelFile(result.files.single.path!);
      scriptSourceFile = ExcelFile(result.files.single.path!);
      scriptSourceFile!.loadFile();
      //sheetsList = scriptSourceFile!.sheetsList;
      //excelFile = scriptSourceFile!.file_getter();


      setState(() {
        
      });
    } else {
    // User canceled the picker
      _showPickerDialogCancelled('script file');
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
          }
          
          
        },
        focusNode: FocusNode(),
        child: ListView(
          addAutomaticKeepAlives: false,
          shrinkWrap: false,
          children: [
            DataTable(columns: [
              DataColumn(label: Text("TC from script\nto player")),
              DataColumn(label: Text("TC from player\nto script")),
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

// TESTY ALE NIEUDANE >>
  Widget showTableAsRowsAndColls(){
    return Flexible(
      child: ListView(
        children: scriptListToRows(_scriptTable)
        )
    );
  }

  List<Widget> scriptListToRows(List<ScriptNode> scriptList){
    List<Widget> siema = List.empty(growable: true);
    for (var scriptNode in scriptList) {
      siema.add(Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints.tight(Size(100,30)), 
            child: ElevatedButton(
              onPressed: (){
                jumpToTc(scriptNode.tcIn);
              },
              //child: Text("TC UP")))),
              child: Icon(Icons.arrow_upward))),
          ConstrainedBox(
            constraints: BoxConstraints.tight(Size(100,30)),
            child: ElevatedButton(
              onPressed: (){
                scriptNode.tcIn = tcFromVideo()+startTC;
                setState(() {
                  scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
                });
              },
              //child: Text("TC DOWN")))),
              child: Icon(Icons.arrow_downward))),
          SizedBox( width: 100, child: TextFormField(
            controller: scriptNode.textControllerTc,
            onChanged: (value) {
              //FIXME:
              if(Timecode.tcValidateCheck(value)){
                scriptNode.tcIn = Timecode(value);
              }
              print(scriptNode.tcIn.toString());
            },
            inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],
            )),

          SizedBox( width: 180, child: TextFormField(
            initialValue: scriptNode.charName,
            key: Key(scriptNode.charName),
            onChanged: (value){
              scriptNode.charName = value;
            },
          )),

          Flexible(
            child: TextFormField(
            onChanged: (value) => {
              scriptNode.dial = value
              // zobaczymy czy będzie to wystarczająco efficient ?
            },
            scribbleEnabled: false, 
            initialValue: scriptNode.dial, 
            maxLines: 1,
            key: Key(scriptNode.dial),),
          )

      ]));
    }
    return siema;
  }
// << TESTY ALE NIEUDANE

/* void importSheetToList(String sheetName, List <ScriptNode> sctiptList){
      //sctiptList = List.empty(growable: true);
      sctiptList.clear();
      for (var row in excel.tables[sheetName]!.rows) {
        int collNr = 0;
        ScriptNode scriptNode = ScriptNode.empty();
        for (var cell in row) {
          //FIXME: popraw te warunki, bo wiocha
          if(cell != null && cell.value != null && cell.value.value != null){
            switch (collNr) {
            case 0:
              scriptNode.tcIn = Timecode(cell.value.value.toString());
              break;
            case 1:
              scriptNode.charName = cell.value.value.toString();
            break;
            case 2:
              scriptNode.dial = cell.value.value.toString();
            break;
            }
          }
          
          collNr++;
        }
        sctiptList.add(scriptNode);
      }
      sctiptList.sort();
      // TODO: sprawdź w których miejscach sortować listy
  }
  */



  void saveFile(){
    scriptSourceFile!.exportListToSheet(_scriptTable, sheetName);
    scriptSourceFile!.saveFile();
  }

  void jumpToTc(Timecode tc){
    player.seek((tc-startTC).tcAsDuration());
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
          ConstrainedBox(
            constraints: BoxConstraints.tight(Size(100,30)), 
            child: ElevatedButton(
              onPressed: (){
                jumpToTc(scriptNode.tcIn);
              },
              //child: Text("TC UP")))),
              child: Icon(Icons.arrow_upward)))),
        
        DataCell(
          ConstrainedBox(
            constraints: BoxConstraints.tight(Size(100,30)),
            child: ElevatedButton(
              onPressed: (){
                scriptNode.tcIn = tcFromVideo()+startTC;
                scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
                setState(() {

                });
              },
              //child: Text("TC DOWN")))),
              child: Icon(Icons.arrow_downward)))),
        
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
    scriptList.add(ScriptNode(timecode+startTC, tempTextEditController.text, "dialogue"));
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

  // String buildTimecodePattern(int fps) {
  // // Sprawdzenie, ile maksymalnie klatek na sekundę jest dopuszczalne
  // String framePattern;
  // if (fps <= 10) {
  //   framePattern = r'[0-9]';  // dla FPS <= 10 (klatki 0-9)
  // } else if (fps <= 99) {
  //   framePattern = r'[0-' + (fps - 1).toString().padLeft(2, '0')[0] + '][0-9]';
  // } else {
  //   throw ArgumentError('FPS musi być w zakresie 1-99');
  // }
  // // Budowanie pełnego wzorca timecode
  // return r'^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d:' + framePattern + r'$';
  // }
  
  // bool tcValidateCheck(String value) {
  //   // check if the TC is a valid value
  //   var tcValidateCheck = RegExp(r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d):([0-5]\d)$');
  //   if(tcValidateCheck.hasMatch(value)){
  //     return true;
  //   } else{
  //     return false;
  //   }
  // }
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



// class PaddingCell extends Padding {
//   PaddingCell({Key? key, required Widget child}) : super(key: key, padding: const EdgeInsets.all(10.0), child: child);
// }

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
                  setState(() {
                    //TODO: sprawdź czy wszystkie parametry są wypełnione
                    selectedIndex = value;
                  });
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