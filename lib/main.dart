import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:script_editor/classes.dart';
import 'package:script_editor/resizableWidget.dart';
import 'package:script_editor/widgetsMy.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

late double _screenWidth;
late double _screenHeight;


late File videoFile;
Duration currentPlaybackPosition = Duration();
late dynamic excel;

//List<DropdownMenuEntry<String>> sheetsMenuEntry = List.empty(growable: true);
//List<DropdownMenuEntry<String>> sheetsMenuEntry = [];
final List<ScriptNode> _scriptTable = List.empty(growable: true);
final List <DataRow> _dataRows = List.empty(growable: true);
String selectedCharacterName = "ALL CHARACTERS";
late String sheetName;

ExcelFile? scriptSourceFile;


TextEditingController tempTextEditController = TextEditingController();
TextEditingController charNameOldTEC = TextEditingController();
TextEditingController charNameNewTEC = TextEditingController();
TextEditingController tcEntryController = TextEditingController();
bool tcEntryControllerActive = true;

ValueNotifier<bool> scrollFollowsVideo = ValueNotifier(false);
ItemScrollController scriptListController = ItemScrollController();
int currentItemScrollIndex = 0;


Map<String, KeyboardShortcutNode> shortcutsMap = <String, KeyboardShortcutNode>{};

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
      _firstInit = false;


      player.open(Media(SettingsClass.videoFilePath));
      player.stream.position.listen((e) {
        currentPlaybackPosition = e;
        markCurrentLine(_scriptTable);
        if (tcEntryControllerActive) {  
          tcEntryController.text =  Timecode.fromDuration(e+SettingsClass.videoStartTc.tcAsDuration()).toString();
        }
        if (scrollFollowsVideo.value) {
          for (var i = 0; i < _scriptTable.length; i++) {
            if (_scriptTable[i].isThisCurrentTCValueNotifier.value) {
              if (currentItemScrollIndex != i) {
                scriptListController.scrollTo(index: i, duration: const Duration(milliseconds: 500));
                currentItemScrollIndex = i;
              }
            }
          }
        }
      });
      scriptSourceFile = ExcelFile(SettingsClass.scriptFilePath);
      scriptSourceFile!.loadFile();
      scriptSourceFile!.importSheetToList(SettingsClass.sheetName, _scriptTable);
      setState(() {
        //_dataRows = scriptListToTable(_scriptTable);
        scriptListToTable(_scriptTable, _dataRows);
        sheetName = SettingsClass.sheetName;
      });

      initializeShortcutsList();
    }




    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: keyEventShortcutProcess,
      child: Scaffold(
        // appBar: AppBar(
        //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        //   title: Text(widget.title),
        // ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      ResizebleWidget(child: Video(controller: controller)),
                      Row(children: [
                        OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap["seek <"]),
                        OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap["play/pause"]),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: tcEntryController,
                            inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],
                            onTap: (){
                              
                              tcEntryControllerActive = false;
                            },
                            onChanged: (String string){print("changed");},
                            onEditingComplete: (){
                              tcEntryControllerActive = true;
                              print("edit complete");
                            },
                            onTapOutside: (PointerDownEvent pde){
                              jumpToTc(Timecode(tcEntryController.text));
                              player.play();
                              tcEntryControllerActive = true;
                            },
                            onSaved: (newValue){
                              jumpToTc(Timecode(tcEntryController.text));
                              player.play();
                              tcEntryControllerActive = true;
                            },
                            onFieldSubmitted: (value){
                              jumpToTc(Timecode(tcEntryController.text));
                              player.play();
                              tcEntryControllerActive = true;
                            }  
                          ),
                        ),
                        OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap["seek >"]),
                        ValueListenableBuilder(valueListenable: scrollFollowsVideo, builder: (context, value, child) {
                          return Checkbox(
                            value: value,
                            onChanged:(value) {
                              scrollFollowsVideo.value = value!;
                            });
                        },),
                        const Text("view follows video"),
                      ]),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 200, 
                        child: TextFormField(
                          controller: tempTextEditController,)),
                      OutlinedButton(onPressed: (){
                        newEntry(_scriptTable, null, tempTextEditController.text);
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
                      const Text("Replace the character name:"),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            helperText: "old character name"
                          ),
                          controller: charNameOldTEC,
                        )),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                            decoration: const InputDecoration(
                              helperText: "new character name",
                            ),
                          controller: charNameNewTEC,
                        )),
                      OutlinedButton(
                        onPressed: (){
                          int a = replaceCharName(charNameOldTEC.text, charNameNewTEC.text, _scriptTable);
                          setState(() {
                            scriptListToTable(_scriptTable, _dataRows);
                            charNameOldTEC.text = "";
                            charNameNewTEC.text = "";
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
                  ),
                  Column(
                    children: [
                      const Text("add new lines:"),
                      Row(
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              onChanged: (value) {
                                shortcutsMap["add char #1"]!.characterName = value;
                              },
                              decoration: const InputDecoration(
                                helperText: "character name #1",
                              ),
                            ),
                          ),
                          OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap["add char #1"])
                        ],
                      ),
                        Row(
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              onChanged: (value) {
                                shortcutsMap["add char #2"]!.characterName = value;
                              },
                              decoration: const InputDecoration(
                                helperText: "character name #2",
                              ),
                            ),
                          ),
                          OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap["add char #2"])
                          //generateButtonWithShortcut(shortcutsList[4]),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            //showTableAsListView(),
            showTableAsScrollablePositionListView(),
            ]
          ),
        ),
      ),
    );
  }



  Widget videoPlayer(BuildContext context){
    return SizedBox(
      child: SizedBox(
        //width: MediaQuery.of(context).size.width,
        //height: MediaQuery.of(context).size.width * 9.0 / 16.0,
        // width: _sliderWidthValue,
        // height: _sliderHeightValue,
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

  List<DropdownMenuEntry<String>> getCharactersMenuEntries(List <ScriptNode> scriptList){
    List<String> characterNames = List<String>.empty(growable: true);

    characterNames.add("ALL CHARACTERS");
    for (ScriptNode scriptNode in scriptList) {
      if (!characterNames.contains(scriptNode.charName)) {
        characterNames.add(scriptNode.charName);
      }
    }

    characterNames.sort((a, b) {
      return a.compareTo(b);
    },);

    return characterNames.map((e){
      return DropdownMenuEntry(
        value: e,
        label: e);
    }).toList();
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
    return Flexible(
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
            DataColumn(
              //label:Text("character"),
              label: DropdownMenu(
                dropdownMenuEntries: getCharactersMenuEntries(_scriptTable),
                initialSelection: "ALL CHARACTERS",
                onSelected: (value) {
                  setState(() {
                    scriptListToTable(_scriptTable, _dataRows, value!);
                  });
                },
                )
              //label: MultiDropdown(items: DropdownItem<dynamic>[DropdownItem(label: "label", value: 4)])
              //label: MultiDropdown(items: items),
            ),
            DataColumn(label: SizedBox(width: (_screenWidth>1200) ? _screenWidth-1000 : 200, child: Text("dialogue"))),
            const DataColumn(label: Text("Delete\nthe line")),
          ],
            rows: _dataRows,
          )
        ],
      ),
    );
  }

  Widget showTableAsScrollablePositionListView(){
    double widthButtons = 80;
    double widthColC = 100;
    double widthColD = 220;

   const EdgeInsetsGeometry paddingSize = EdgeInsets.symmetric(horizontal: 4.0);

    Row _headerRow(){
      return Row(
        children: [
          Padding(
            padding: paddingSize,
            child: SizedBox(width: widthButtons, child: const Text("TC from script\nto player")),
          ),
          Padding(
            padding: paddingSize,
            child: SizedBox(width: widthButtons,  child: const Text("TC from player\nto script")),
          ),
          Padding(
            padding: paddingSize,
            child: SizedBox(width: widthColC,  child: const Text("TC in")),
          ),
          Padding(
            padding: paddingSize,
            child: SizedBox(
              width: widthColD,
              child: DropdownMenu(
                dropdownMenuEntries: getCharactersMenuEntries(_scriptTable),
                initialSelection: "ALL CHARACTERS",
                onSelected: (value) {
                  setState(() {
                    if (value != null) {
                      selectedCharacterName = value;
                    }
                    scriptListToTable(_scriptTable, _dataRows, value!);
                  });
                },
              ),
            ),
          ),
          const Expanded(
            child: Text("Dialogue"),
          ),
          Padding(padding: paddingSize,
            child: SizedBox(
              width: widthButtons,
              child: const Text(
                textAlign: TextAlign.center,
                "Delete\nthe line"),
            ),
          ),
        ],
      );
    }

    Row _buildRow(BuildContext context, int index){
      if (_scriptTable[index].charName == selectedCharacterName || selectedCharacterName == "ALL CHARACTERS") {
        return Row(
          children: [
            ValueListenableBuilder<bool>(valueListenable: _scriptTable[index].isThisCurrentTCValueNotifier, builder: (context, value, child) {
              return SizedBox(
                width: widthButtons,
                child: ElevatedButton(
                style: _scriptTable[index].isThisCurrentTCValueNotifier.value ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)) : ButtonStyle(),
                onPressed: (){
                  jumpToTc(_scriptTable[index].tcIn);
                },
                //child: Text("TC UP")))),
                child: const Icon(Icons.arrow_upward)),
              );
            },),
        
        
            Padding(
              padding: paddingSize,
              child: SizedBox(
                width: widthButtons,
                child: ElevatedButton(
                  onPressed: (){
                    _scriptTable[index].tcIn = tcFromVideo()+SettingsClass.videoStartTc;
                    _scriptTable[index].textControllerTc.value = TextEditingValue(text: _scriptTable[index].tcIn.toString());
                    setState(() {
                
                    });
                  },
                  //child: Text("TC DOWN")))),
                  child: Icon(Icons.arrow_downward)),
              ),
            ),
        
        
            Padding(
              padding: paddingSize,
              child: SizedBox( width: widthColC, child: TextFormField(
                // FIXME: popraw to, ze nie aktualizuje się cały czas
                controller: _scriptTable[index].textControllerTc,
                onChanged: (value) {
                  //FIXME:
                  if(Timecode.tcValidateCheck(value)){
                    _scriptTable[index].tcIn = Timecode(value);
                  }
                  print(_scriptTable[index].tcIn.toString());
                },
                inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],
                )),
            ),
        
        
            Padding(
              padding: paddingSize,
              child: SizedBox( width: widthColD, child: TextFormField(
                  initialValue: _scriptTable[index].charName,
                  key: Key(_scriptTable[index].charName),
                  onChanged: (value){
                    _scriptTable[index].charName = value;
                  },
                  )),
            ),
            
            Flexible(
              child: Padding(
                padding: paddingSize,
                child: SizedBox(
                  height: 50,
                  child: TextFormField(
                    onChanged: (value) => {
                      _scriptTable[index].dial = value
                    },
                    scribbleEnabled: false, 
                    initialValue: _scriptTable[index].dial, 
                    maxLines: 10,
                    key: UniqueKey()),
                ),
              ),
            ),
              
            Padding(
              padding: paddingSize,
              child: SizedBox(
                width: widthButtons,
                child: ElevatedButton(
                  child: Icon(Icons.delete),
                  onPressed: () {
                    _scriptTable.remove(_scriptTable[index]);
                    scriptListToTable(_scriptTable, _dataRows);
                    setState(() {
                      
                    });
                  },),
              ),
            ),
              //TODO: NIE WIEM PO CO TO BYLO OGARNIJ
              //scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
          ],
        );
      } else {
        return Row();
      }
    }


    return Flexible(
      child: ScrollablePositionedList.builder(
        itemScrollController: scriptListController,
        addAutomaticKeepAlives: false,
        shrinkWrap: false,
        itemCount: _scriptTable.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _headerRow(),
                _buildRow(context, index),
              ],
            );
          } else{
            return _buildRow(context, index);
          }
        },
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


  List<Row> scriptListToTableForListView(){
    List<Row> list = List.empty(growable: true);
    for (ScriptNode scriptNode in _scriptTable) {
      list.add(Row(
        children: [
          SizedBox(width: 100, child: TextFormField(initialValue: scriptNode.tcIn.toString())),
          SizedBox(width: 100, child: TextFormField(initialValue: scriptNode.charName)),
          SizedBox(width: 100, child: TextFormField(initialValue: scriptNode.dial)),
        ],
      ));
    }
    return list;
  }

  void scriptListToTable(List<ScriptNode> scriptList, List<DataRow> myList, [String charName = "ALL CHARACTERS"]){
    //myList = List.empty(growable: true);
    myList.clear();
    for (var scriptNode in scriptList) {
      if (scriptNode.charName == charName || charName == "ALL CHARACTERS") {
        myList.add(DataRow(
          // color: WidgetStateColor.resolveWith((states){
          //   return scriptNode.isThisCurrentTCValueNotifier.value ? Colors.lightGreen : Colors.white;
          // }),
          cells: [
        DataCell(
          ValueListenableBuilder<bool>(valueListenable: scriptNode.isThisCurrentTCValueNotifier, builder: (context, value, child) {
            return ElevatedButton(
            style: scriptNode.isThisCurrentTCValueNotifier.value ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)) : ButtonStyle(),
            onPressed: (){
              jumpToTc(scriptNode.tcIn);
            },
            //child: Text("TC UP")))),
            child: const Icon(Icons.arrow_upward));
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
        
        DataCell(SizedBox( width: 250, child: TextFormField(
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

    TextEditingController tecTcEntry = TextEditingController();
    TextEditingController tecCharNameEntry = TextEditingController();
    TextEditingController tecDialEntry = TextEditingController();
    myList.add(DataRow(
      cells: [
        const DataCell(Text('')),
        const DataCell(Text('')),
        DataCell(TextFormField(
          inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],
          controller: tecTcEntry,
        )),
        DataCell(TextFormField(
          controller: tecCharNameEntry,
        )),
        DataCell(TextFormField(
          controller: tecDialEntry,)),
        DataCell(
          OutlinedButton(
            child: Icon(Icons.add),
            onPressed: (){
              Timecode? tc = tecTcEntry.text == "" ? null : Timecode(tecTcEntry.text);
              
              newEntry(_scriptTable, tc, tecCharNameEntry.text, tecDialEntry.text);
              setState(() {
                scriptListToTable(_scriptTable, _dataRows);
              });
            },
            )),
    ]));
      
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


  void newEntry(List<ScriptNode> scriptList, Timecode? tcIn, [String charName = "char name", String dial = 'dialogue']) {
    charName = charName=="" ? "char name" : charName;
    dial = dial=="" ? "char name" : dial;
    Timecode timecode = Timecode();
    if (tcIn == null) {
      timecode.tcFromDuration(currentPlaybackPosition);
    } else {
      timecode = tcIn;
    }
    scriptList.add(ScriptNode(timecode+SettingsClass.videoStartTc, charName, dial));
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






  void keyEventShortcutProcess(KeyEvent keyEvent){
    bool assignShortcutOperation = false; // operation type is assigning the shortcut
    HardwareKeyboard hk = HardwareKeyboard.instance;

    // SAVE THE FILE
    if ((hk.isMetaPressed || hk.isControlPressed)
    && keyEvent.logicalKey == LogicalKeyboardKey.keyS
    && keyEvent.runtimeType == KeyDownEvent) {
      saveFile();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("file saved!")));
    }

    int countModifiers = 0;

    countModifiers = hk.isAltPressed ? countModifiers+1 : countModifiers;
    countModifiers = hk.isControlPressed ? countModifiers+1 : countModifiers;
    countModifiers = hk.isMetaPressed ? countModifiers+1 : countModifiers;
    countModifiers = hk.isShiftPressed ? countModifiers+1 : countModifiers;

    if (keyEvent.runtimeType == KeyDownEvent && hk.logicalKeysPressed.length > countModifiers) {
      shortcutsMap.forEach((key, keyboardShortcutNode){
        if (keyboardShortcutNode.assignedNowNotifier.value) {
          print("assign shortcut");
          keyboardShortcutNode.logicalKeySet = hk.logicalKeysPressed;
          assignShortcutOperation = true;
          keyboardShortcutNode.assignedNowNotifier.value = false;
          setState(() {
            
          });
        }
        if(assignShortcutOperation == false && setEquals(hk.logicalKeysPressed, keyboardShortcutNode.logicalKeySet)){
          keyboardShortcutNode.onClick();
        }
      });
    }
  }

  void updateUi(int a){
    setState(){};
  }
  void initializeShortcutsList(){


    shortcutsMap.putIfAbsent("play/pause", (){
      return KeyboardShortcutNode((){player.playOrPause();}, "play/pause", iconsList: [Icons.play_arrow, Icons.pause]);
    });
    shortcutsMap.putIfAbsent("seek >", (){
      return KeyboardShortcutNode((){player.seek((currentPlaybackPosition+Duration(seconds: 5)));}, "seek >", iconsList: [Icons.fast_forward]);
    });
    shortcutsMap.putIfAbsent("seek <", (){
      return KeyboardShortcutNode((){player.seek((currentPlaybackPosition-Duration(seconds: 5)));},"seek <", iconsList: [Icons.fast_rewind]);
    });
    shortcutsMap.putIfAbsent("add char #1", (){
      KeyboardShortcutNode ksn = KeyboardShortcutNode((){}, "add char #1");
      ksn.onClick = (){
        newEntry(_scriptTable, null, ksn.characterName!);
        setState(() {
          scriptListToTable(_scriptTable, _dataRows);
        });
      };
      return ksn;
    });
    shortcutsMap.putIfAbsent("add char #2", (){
      KeyboardShortcutNode ksn = KeyboardShortcutNode((){}, "add char #2");
      ksn.onClick = (){
        newEntry(_scriptTable, null, ksn.characterName!);
        setState(() {
          scriptListToTable(_scriptTable, _dataRows);
        });
      };
      return ksn;
    });
  }


  // Tooltip generateButtonWithShortcut(KeyboardShortcutNode ksn){
  //   Widget label;
  //   if (ksn.iconsList != null) {
  //     List<Widget> iconsList = List.empty(growable: true);
  //     for (var element in ksn.iconsList!) {
  //       iconsList.add(Icon(element));
  //     }
  //     label = Row(children: iconsList);
  //   } else {
  //     label = Text(ksn.description);
  //   }
  //   return Tooltip(
  //     key: GlobalKey(),
  //     message: ksn.showShortcut(),
  //     child: OutlinedButton(
  //       onLongPress:(){
  //         setState(() {
  //           ksn.assignedNow = true;
  //         });
  //       },
  //       onPressed: (){
  //         if (ksn.assignedNow) {
  //           setState(() {
  //             ksn.assignedNow = false;
  //           });
  //         } else {
  //           ksn.onClick();
  //         }
  //       },
  //       child: ksn.assignedNow ? const Text("assign the shortcut") : label,
  //       //child: Text(ksn.assignedNow ? "assign the shortcut" : ksn.description!)
  //       ),
  //   );
  // }

// >>> TESTS >>>

// <----- TESTS ------

}




class SettingsPage extends StatefulWidget {

  @override
  State<SettingsPage> createState() => _SettingsPageState();

}

class _SettingsPageState extends State<SettingsPage> {

  ExcelFile? excelFile;
  TextEditingController tecColl = TextEditingController();
  TextEditingController tecRow = TextEditingController();

  @override
  void initState() {
    super.initState();
    tecColl.text = (SettingsClass.collNumber+1).toString();
    tecRow.text = (SettingsClass.rowNumber+1).toString();
  }

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
                      controller: tecColl,
                      onChanged: (value) => setState((){SettingsClass.collNumber = (value!="") ? int.parse(value)-1 : 0;}),
                      inputFormatters: [TextInputFormatter.withFunction(numberValidityCheck)]
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            OutlinedButton(onPressed: (){
                              if (SettingsClass.collNumber >=0) {
                                setState(() {
                                  SettingsClass.collNumber++;
                                  tecColl.text = (SettingsClass.collNumber+1).toString();
                                });
                              }
                            }, child: Icon(Icons.plus_one)),
                            OutlinedButton(onPressed: (){                        
                              if (SettingsClass.collNumber >=1) {
                                setState(() {
                                  SettingsClass.collNumber--;
                                  tecColl.text = (SettingsClass.collNumber+1).toString();
                                });
                              }
                            }, child: Icon(Icons.exposure_minus_1)),
                          ],
                        ),
                        Text('selected collumn: ${SettingsClass.collNumber+1}'),
                      ],
                    ),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select starting row: "),
                    TextFormField(
                      controller: tecRow,
                      onChanged: (value) => setState((){SettingsClass.rowNumber = (value!="") ? int.parse(value)-1 : 0;}),
                      inputFormatters: [TextInputFormatter.withFunction(numberValidityCheck)]
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            OutlinedButton(onPressed: (){
                              if (SettingsClass.rowNumber >=0) {
                                setState(() {
                                  SettingsClass.rowNumber++;
                                  tecRow.text = (SettingsClass.rowNumber+1).toString();
                                });
                              }
                            }, child: Icon(Icons.plus_one)),
                            OutlinedButton(onPressed: (){                        
                              if (SettingsClass.rowNumber >=1) {
                                setState(() {
                                  SettingsClass.rowNumber--;
                                  tecRow.text = (SettingsClass.rowNumber+1).toString();
                                });
                              }
                            }, child: Icon(Icons.exposure_minus_1)),
                          ],
                        ),
                        Text('selected row: ${SettingsClass.rowNumber+1}'),
                      ],),
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
              showSheetPreview(),
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


  DataTable showSheetPreview(){
    List<ScriptNode> list = List.empty(growable: true);
    List<DataRow> datarows = List.empty(growable: true);
    if (SettingsClass.scriptFilePath != "" && SettingsClass.sheetName != "" && excelFile != null) {
      excelFile!.importSheetToList(SettingsClass.sheetName, list);
      print(list.length);
      for (var i = 0; i < 3 && i < list.length; i++) {
        print("object");
        datarows.add(
          DataRow(cells:[
            DataCell(Text(list[i].tcIn.toString())),
            DataCell(Text(list[i].charName)),
            DataCell(Text(list[i].dial)),
          ]));
      }
    }

    datarows.add(
          const DataRow(cells:[
            DataCell(Text("...")),
            DataCell(Text("...")),
            DataCell(Text("...")),
          ]));

    return DataTable(columns: const [
            DataColumn(
              label: Text("TC in"),),
            DataColumn(
              label: Text("Character")),
            DataColumn(
              label: Text("Dialogue"),),
          ],
    rows: datarows,
    );
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