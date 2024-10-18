import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
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
Timecode startTC = Timecode();
// int videoWidth = 500;
// int videoHeight = 500;
double _sliderHeightValue = 200;
double _sliderWidthValue = 200;

late double _screenWidth;
late double _screenHeight;


late File videoFile;
Duration currentPlaybackPosition = Duration();
File excelFile = new File("");
late dynamic excel;

bool _sheetSelectorActive = true;
//List<DropdownMenuEntry<String>> sheetsMenuEntry = List.empty(growable: true);
//List<DropdownMenuEntry<String>> sheetsMenuEntry = [];
List<String> sheetsList = List.empty(growable: true);
List<ScriptNode> _scriptTable = List.empty(growable: true);
List <DataRow> _dataRows = List.empty(growable: true);
late String sheetName;

String temporaryStr = "";

  TextEditingController tempTextEditController = TextEditingController();

  @override
  void dispose(){
    player.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    _screenWidth =  MediaQuery.sizeOf(context).width;
    _screenHeight =  MediaQuery.sizeOf(context).height;

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
      body: Column(
        children: [Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              const Text("Video Height:"),
                Slider(
                  min: 50,
                  max: _screenHeight,
                  value: _sliderHeightValue,
                  onChanged: (value){
                    setState(() {
                    _sliderHeightValue = value;
                    });
                  }
                ),
                const Text("Video Width:"),
                Slider(
                  min: 50,
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                fpsSelector(),
                startTcEntryWidget(),
                OutlinedButton(
                  onPressed: selectVideoFile,
                  child: const Text("Open video file...")
                  ),
                OutlinedButton(
                  onPressed: (){
                    selectExcelFile();
                  }  ,
                  child: const Text("Open Script file..."),
                  ),
                sheetSelector(),
                OutlinedButton(
                  onPressed: saveFile,
                  child: const Text("Save script file"),
                  ),
                
              ],
            ),
            Column(
              children: [
                OutlinedButton(onPressed: (){}, child: Text("Insert new TC...")),
                SizedBox(
                  width: 200, 
                  child: TextFormField(
                    //initialValue: temporaryStr,
                    //key: Key(temporaryStr),
                    controller: tempTextEditController,)),
                OutlinedButton(onPressed: (){
                  newEntry(_scriptTable);
                  setState(() {
                    _dataRows = scriptListToTable(_scriptTable);
                  });
                }, child: Text("new entry...")),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    initialValue: "TC VALIDATION TEST",
                    inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],)),
              ],
            )
          ],
        ),
        showTableAsListView()
        //justTable()
        ]
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
    width: 200, // TODO: szerokość zale
    label: const Text("select excel sheet"),
    onSelected: (value) {
      importSheetToList(value!, _scriptTable);
      setState(() {
        _dataRows = scriptListToTable(_scriptTable);
        sheetName = value;
      });
    },
    dropdownMenuEntries: getDropdownMenuEntries(),
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
          const Text(":"),
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
          const Text(":"),
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
          const Text(":"),
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

  Future<void> selectExcelFile() async {
    // select the excel file, list the sheets and save the excel file to the var
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xls', 'xlsx']);
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
      _showPickerDialogCancelled('script file');
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


  Widget showTableAsListView(){
    return Flexible(
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
                _dataRows = scriptListToTable(_scriptTable);
                });
              },),
            const DataColumn(label: Text("character")),
            DataColumn(label: SizedBox(width: _screenWidth-900, child: Text("dialogue"))),
          ],
            rows: _dataRows,
          )
        ],
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

          SizedBox( width: 200, child: TextFormField(
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


  void importSheetToList(String sheetName, List <ScriptNode> sctiptList){
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
  
  void exportListToSheet(List<ScriptNode> myList, String sheetNameLoc){
    Sheet sheetObject = excel[sheetNameLoc];
    int a=0;
    for (var scriptNode in myList) {
      //sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1), TextCellValue("ELO"));
      sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: a), TextCellValue(scriptNode.tcIn.toString()));
      sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: a), TextCellValue(scriptNode.charName));
      sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: a), TextCellValue(scriptNode.dial));
      a++;
    }
    // TODO:
  }
  
  void saveSheetToFile(){
    // Sheet sheetObject = excel[sheetName];
    // sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1), TextCellValue("ELO"));
    exportListToSheet(_scriptTable, sheetName);

    var fileBytes = excel.save();

    //FIXME: FIX SAVED FILE LOCATION
    // File('/Users/bmajewicz/Desktop/output_file_name.xlsx')
    // ..createSync(recursive: true)
    // ..writeAsBytesSync(fileBytes);
    excelFile
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes);
  }

  void saveFile(){
    saveSheetToFile();
  }

  void jumpToTc(Timecode tc){
    player.seek((tc-startTC).tcAsDuration());
  }

  Timecode tcFromVideo(){
    print(currentPlaybackPosition.toString());
    Timecode tc = Timecode();
    tc.tcFromDuration(currentPlaybackPosition);
    return tc;
    
  }

  List <DataRow> scriptListToTable(List<ScriptNode> scriptList){
    List<DataRow> myList = List.empty(growable: true);
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
                setState(() {
                  scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
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
       
        DataCell(TextFormField(
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
      ]));
      scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
    }
    return myList;
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

  void newEntry(List<ScriptNode> scriptList) {
    Timecode timecode = Timecode();
    timecode.tcFromDuration(currentPlaybackPosition);
    scriptList.add(ScriptNode(timecode+startTC, "characterName", "dialogue"));
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

