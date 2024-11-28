import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/keyboard_shortcut_node.dart';
import 'package:script_editor/models/script_node.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/models/timecode.dart';
import 'package:script_editor/resizableWidget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
Duration currentPlaybackPosition = const Duration();
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

int itemIndexFromButton = 0;


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
            if (_scriptTable[i].isThisCurrentTCValueNotifier.value && (selectedCharacterName == "ALL CHARACTERS" || selectedCharacterName == _scriptTable[i].charName)) {
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
                            onEditingComplete: (){
                              tcEntryControllerActive = true;
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
                      OutlinedButton(onPressed: saveFile, child: const Text("SAVE FILE")),
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
            _generateTableAsScrollablePositionListView(),
            ]
          ),
        ),
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



  Widget _generateTableAsScrollablePositionListView() {
    const double widthButtons = 80;
    const double widthColC = 100;
    const double widthColD = 220;
    const EdgeInsetsGeometry paddingSize = EdgeInsets.symmetric(horizontal: 4.0);
    HardwareKeyboard hk = HardwareKeyboard.instance;

    Row headerRow(){
      return Row(
        children: [
          const Padding(
            padding: paddingSize,
            child: SizedBox(width: widthButtons, child: Text("TC from script\nto player")),
          ),
          const Padding(
            padding: paddingSize,
            child: SizedBox(width: widthButtons,  child: Text("TC from player\nto script")),
          ),
          Padding(
            padding: paddingSize,
            child: SizedBox(
              width: widthColC,
              child: FilledButton(
                child: Text("TC in"),
                onPressed: () {
                  setState(() {
                    _scriptTable.sort();
                  });
                },)),
          ),
          Padding(
            padding: paddingSize,
            child: SizedBox(
              width: widthColD,
              child: DropdownMenu(
                dropdownMenuEntries: getCharactersMenuEntries(_scriptTable),
                initialSelection: selectedCharacterName,
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
          const Padding(padding: paddingSize,
            child: SizedBox(
              width: widthButtons,
              child: Text(
                textAlign: TextAlign.center,
                "Delete\nthe line"),
            ),
          ),
        ],
      );
    }

    Row buildRow(BuildContext context, int index){
      if (index == itemIndexFromButton) {
        _scriptTable[index].focusNode.requestFocus();
      }
      if (_scriptTable[index].charName == selectedCharacterName || selectedCharacterName == "ALL CHARACTERS") {
        _scriptTable[index].focusNode.onKeyEvent = (focus, event){
          if (event.runtimeType == KeyDownEvent && hk.isControlPressed) {
            int offset = 0;
            switch (event.logicalKey) {
              case LogicalKeyboardKey.arrowUp:
                offset = -1;
                break;
              case LogicalKeyboardKey.arrowDown:
                offset = 1;
                break;
            }
            try {
              _scriptTable[index+offset].focusNode.requestFocus();
            } catch (e) {
            }
          }
          return KeyEventResult.ignored;
        };
        return Row(
          children: [
            ValueListenableBuilder<bool>(valueListenable: _scriptTable[index].isThisCurrentTCValueNotifier, builder: (context, value, child) {
              return SizedBox(
                width: widthButtons,
                child: ElevatedButton(
                style: _scriptTable[index].isThisCurrentTCValueNotifier.value ? const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)) : const ButtonStyle(),
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
                  child: const Icon(Icons.arrow_downward)),
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
                    focusNode: _scriptTable[index].focusNode,
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
                  child: const Icon(Icons.delete),
                  onPressed: () {
                    itemIndexFromButton = index;
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
        return const Row();
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
                headerRow(),
                buildRow(context, index),
              ],
            );
          } else{
            return buildRow(context, index);
          }
        },
      ),
    );
  }

  // optional - previous function as future and build as futureBuilder
  // Widget showTableAsScrollablePositionListView(){
  //   return FutureBuilder(
  //     future: _generateTableAsScrollablePositionListView(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
  //         // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
  //         //   scriptListController.jumpTo(index: itemIndexFromButton);
  //         //   FocusScope.of(context).requestFocus(_scriptTable[itemIndexFromButton].focusNode);
  //         // },);
  //         return snapshot.data!;
  //       }
  //       else {
  //         return SizedBox(
  //           width: _screenWidth,
  //           child: const Center(child: CircularProgressIndicator()));
  //       }
  //     },);
  // }

  


  void saveFile(){
    scriptSourceFile!.exportListToSheet(_scriptTable, sheetName);
    scriptSourceFile!.saveFile();
  }

  void jumpToTc(Timecode tc){
    player.seek((tc-SettingsClass.videoStartTc).tcAsDuration());
  }

  Timecode tcFromVideo(){
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
            style: scriptNode.isThisCurrentTCValueNotifier.value ? const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)) : const ButtonStyle(),
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
            child: const Icon(Icons.arrow_downward))),
        
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
            child: const Icon(Icons.delete),
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
            child: const Icon(Icons.add),
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
    scriptList.sort();
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
    // ignore: unused_element
    setState(){};
  }
  void initializeShortcutsList(){


    shortcutsMap.putIfAbsent("play/pause", (){
      return KeyboardShortcutNode((){player.playOrPause();}, "play/pause", iconsList: [Icons.play_arrow, Icons.pause]);
    });
    shortcutsMap.putIfAbsent("seek >", (){
      return KeyboardShortcutNode((){player.seek((currentPlaybackPosition+const Duration(seconds: 5)));}, "seek >", iconsList: [Icons.fast_forward]);
    });
    shortcutsMap.putIfAbsent("seek <", (){
      return KeyboardShortcutNode((){player.seek((currentPlaybackPosition-const Duration(seconds: 5)));},"seek <", iconsList: [Icons.fast_rewind]);
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


}


