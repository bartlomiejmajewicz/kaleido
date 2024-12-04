import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:script_editor/main.dart';
import 'package:script_editor/widgets/char_name_widget_with_autocomplete.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/keyboard_shortcut_node.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/models/timecode.dart';
import 'package:script_editor/widgets/outlined_button_with_shortcut.dart';
import 'package:script_editor/widgets/resizable_widget.dart';
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

late double _screenWidth;
late double _screenHeight;

Duration _currentPlaybackPosition = const Duration();

final List<ScriptNode> _scriptTable = List.empty(growable: true);
static const String allCharactersConst = "ALL CHARACTERS";
String selectedCharacterName = allCharactersConst;
late String sheetName;

ExcelFile? scriptSourceFile;


TextEditingController tempTextEditController = TextEditingController();
TextEditingController charNameOldTEC = TextEditingController();
TextEditingController charNameNewTEC = TextEditingController();
TextEditingController tcEntryController = TextEditingController();
bool tcEntryControllerActive = true;

ValueNotifier<bool> scrollFollowsVideo = ValueNotifier(false);
ValueNotifier<bool> focusNodeFollowsVideo = ValueNotifier(false);
ItemScrollController scriptListController = ItemScrollController();
int currentItemScrollIndex = 0;

int itemIndexFromButton = 0;

final ValueNotifier<bool> _scriptTableRebuildFlag = ValueNotifier(true);

Widget _listView = const Flexible(child: Text(""));


Map<String, KeyboardShortcutNode> shortcutsMap = <String, KeyboardShortcutNode>{};

KeyNotifier? kn;

void _printMe(){
  print("text");
}

@override
  void deactivate() {
    print("deac");
    kn!.removeListener(keyEventShortcutProcessFromProvider);
    super.deactivate();
  }

  @override
  void dispose(){
    kn!.removeListener(keyEventShortcutProcessFromProvider);
    player.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    
    WidgetsFlutterBinding.ensureInitialized();

    kn = context.read<KeyNotifier>();
    kn!.addListener(keyEventShortcutProcessFromProvider);


    player.open(Media(SettingsClass.videoFilePath));
    player.stream.position.listen((e) {
      _currentPlaybackPosition = e;
      markCurrentLine(_scriptTable);
      if (tcEntryControllerActive) {  
        tcEntryController.text =  Timecode.fromDuration(e+SettingsClass.videoStartTc.tcAsDuration()).toString();
      }
      focusNodeOrViewFollowsVideo(scrollFollowsVideo.value, focusNodeFollowsVideo.value);
    });

    if (SettingsClass.scriptFile == null) {
      scriptSourceFile = ExcelFile(SettingsClass.scriptFilePath);
      scriptSourceFile!.loadFile();
    }
    else {
      scriptSourceFile = SettingsClass.scriptFile;
    }
    scriptSourceFile!.importSheetToList(SettingsClass.sheetName, _scriptTable);
    sheetName = SettingsClass.sheetName;
    _updateTableListViewFromScriptList();
    _scriptTableRebuildRequest();

    initializeShortcutsList();
  }


  @override
  Widget build(BuildContext context) {


      _screenWidth = MediaQuery.sizeOf(context).width;
      _screenHeight = MediaQuery.sizeOf(context).height;

    SettingsClass.videoHeight = _screenHeight/3;
    SettingsClass.videoWidth = _screenWidth/2;


    return Scaffold(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap["save"]),
                    ]
                  ),
                ),
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
                        ValueListenableBuilder(valueListenable: focusNodeFollowsVideo, builder: (context, value, child) {
                        return Checkbox(
                          value: value,
                          onChanged:(value) {
                            focusNodeFollowsVideo.value = value!;
                          });
                      },),
                      const Text("focus follows video"),
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
                      int newEntryIndex = newEntry(_scriptTable, null, tempTextEditController.text);
                      _updateTableListViewFromScriptList();
                      _scriptTableRebuildRequest();
                      _scriptTable[newEntryIndex].focusNode.requestFocus();
                    }, child: const Text("new entry...")),
                    OutlinedButton(
                      onPressed: () {
                        _saveFileWithSnackbar(context);
                      }, 
                      child: const Text("SAVE FILE")),
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
                        charNameOldTEC.text = "";
                        charNameNewTEC.text = "";
                        _updateTableListViewFromScriptList();
                        _scriptTableRebuildRequest();
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
                        OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap["add char #2"]),
                        //generateButtonWithShortcut(shortcutsList[4]),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          ValueListenableBuilder(valueListenable: _scriptTableRebuildFlag, builder: (context, value, child) {
            //return _generateTableAsScrollablePositionListView();
            return _listView;
          },)
          ]
        ),
      ),
    );
  }



  void markCurrentLine(List<ScriptNode> scriptList){
    bool isThereAChange = false;
    for (var i = 0; i < scriptList.length; i++) {
      if (_currentPlaybackPosition+SettingsClass.videoStartTc.tcAsDuration() < scriptList[i].tcIn.tcAsDuration() && !isThereAChange && i>0) {
        scriptList[i-1].isThisCurrentTCValueNotifier.value = true;
        isThereAChange = true;
      } else {
        scriptList[i].isThisCurrentTCValueNotifier.value = false;
      }
    }
  }

  List<DropdownMenuEntry<String>> getCharactersMenuEntries(List <ScriptNode> scriptList){
    List<String> characterNames = List<String>.empty(growable: true);

    for (ScriptNode scriptNode in scriptList) {
      if (!characterNames.contains(scriptNode.charName)) {
        characterNames.add(scriptNode.charName);
      }
    }

    characterNames.sort((a, b) {
      return a.compareTo(b);
    },);

    characterNames.insert(0, allCharactersConst);

    return characterNames.map((e){
      return DropdownMenuEntry(
        value: e,
        label: e);
    }).toList();
  }

  List<String> getCharactersList(List <ScriptNode> scriptList){
    List<String> characterNames = List<String>.empty(growable: true);

    for (ScriptNode scriptNode in scriptList) {
      if (!characterNames.contains(scriptNode.charName)) {
        characterNames.add(scriptNode.charName);
      }
    }

    characterNames.sort((a, b) {
      return a.compareTo(b);
    },);

    return characterNames;
  }


  void _updateTableListViewFromScriptList(){
    _listView = _generateTableAsScrollablePositionListView();
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
                child: const Text("TC in"),
                onPressed: () {
                  _scriptTable.sort();
                  _updateTableListViewFromScriptList();
                  _scriptTableRebuildRequest();
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
                  if (value != null) {
                    selectedCharacterName = value;
                  }
                  _updateTableListViewFromScriptList();
                  _scriptTableRebuildRequest();
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
      // if (index == itemIndexFromButton && (Platform.isMacOS ||Platform.isLinux || Platform.isWindows)) {
      //   _scriptTable[index].focusNode.requestFocus();
      // }

      if (_scriptTable[index].charName != selectedCharacterName && selectedCharacterName != allCharactersConst) {
        return const Row();
      }
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
          // ignore: empty_catches
          } catch (e) {
          }
        }
        return KeyEventResult.ignored;
      };

      _scriptTable[index].textControllerTc.text = _scriptTable[index].tcIn.toString();
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
                  // _updateTableListViewFromScriptList();
                  // _scriptTableRebuildRequest();
                },
                //child: Text("TC DOWN")))),
                child: const Icon(Icons.arrow_downward)),
            ),
          ),
      
      
          Padding(
            padding: paddingSize,
            child: SizedBox(width: widthColC, child: TextFormField(
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
            child: SizedBox(
              width: widthColD,
              child: CharNameWidgetWithAutocomplete(
                charactersNamesList: getCharactersList(_scriptTable),
                initialValue: _scriptTable[index].charName,
                updateFunction: (value) => _scriptTable[index].charName=value,
                maxOptionsWidth: widthColD,
                ),
              ),
          ),
          
          Flexible(
            child: Padding(
              padding: paddingSize,
              child: SizedBox(
                height: 50,
                child: TextFormField(
                  autofocus: true,
                  focusNode: _scriptTable[index].focusNode,
                  onChanged: (value) {
                    { 
                      _scriptTable[index].dial = value;
                  }
                  },
                  scribbleEnabled: false, 
                  initialValue: _scriptTable[index].dial, 
                  maxLines: 10,
                  ),
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
                  _updateTableListViewFromScriptList();
                  _scriptTableRebuildRequest();
                  _scriptTable[index].focusNode.requestFocus();
                },),
            ),
          ),
            //TODO: NIE WIEM PO CO TO BYLO OGARNIJ
            //scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
        ],
      );
    }

    return Flexible(
      child: Column(
        children: [
          headerRow(),
          Expanded(
            child: ScrollablePositionedList.builder(
              itemScrollController: scriptListController,
              addAutomaticKeepAlives: false,
              shrinkWrap: false,
              itemCount: _scriptTable.length,
              itemBuilder: (context, index) {
                return buildRow(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }


  


  int _saveFile(){
    try {
      scriptSourceFile!.exportListToSheet(_scriptTable, sheetName);
      scriptSourceFile!.saveFile();
      return 0;
    } catch (e) {
      return 100;
    }
  }

  void _saveFileWithSnackbar(BuildContext context){
    if (_saveFile() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("file saved!"),));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("file could NOT be saved"),
            backgroundColor: Colors.red,));
    }
  }

  void jumpToTc(Timecode tc){
    player.seek((tc-SettingsClass.videoStartTc).tcAsDuration());
  }

  Timecode tcFromVideo(){
    Timecode tc = Timecode();
    tc.tcFromDuration(_currentPlaybackPosition);
    return tc;
  }


  




  int newEntry(List<ScriptNode> scriptList, Timecode? tcIn, [String charName = "char name", String dial = 'dialogue']) {
    charName = charName=="" ? "char name" : charName;
    dial = dial=="" ? "char name" : dial;
    Timecode timecode = Timecode();
    if (tcIn == null) {
      timecode.tcFromDuration(_currentPlaybackPosition);
    } else {
      timecode = tcIn;
    }
    ScriptNode scriptNode = ScriptNode(timecode+SettingsClass.videoStartTc, charName, dial);
    scriptList.add(scriptNode);
    scriptList.sort();
    return scriptList.indexOf(scriptNode);
  }

  TextEditingValue tcValidityInputCheck(TextEditingValue oldValue, TextEditingValue newValue) {
    String returnedValue="";
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




  void keyEventShortcutProcessFromProvider(){
    if (kn == null) {
      return;
    }
    if (kn!.currentKeyEvent == null) {
      return;
    }
    _keyEventShortcutProcess(kn!.currentKeyEvent!);
  }


  void _keyEventShortcutProcess(KeyEvent keyEvent){
    bool assignShortcutOperation = false; // operation type is assigning the shortcut
    HardwareKeyboard hk = HardwareKeyboard.instance;

    // SAVE THE FILE - hardcoded shortcut
    if ((hk.isMetaPressed || hk.isControlPressed)
    && keyEvent.logicalKey == LogicalKeyboardKey.keyS
    && keyEvent.runtimeType == KeyDownEvent) {
      _saveFileWithSnackbar(context);
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
          _updateTableListViewFromScriptList();
          _scriptTableRebuildRequest();
        }
        if(assignShortcutOperation == false && setEquals(hk.logicalKeysPressed, keyboardShortcutNode.logicalKeySet)){
          keyboardShortcutNode.onClick();
        }
      });
    }
  }

  void _scriptTableRebuildRequest(){
    if(kDebugMode){
      print("_scriptTableRebuildRequest");
    }
    _scriptTableRebuildFlag.value = !_scriptTableRebuildFlag.value;
  }

  void updateUi(int a){
    // ignore: unused_element
    setState(() {
    });
  }
  void initializeShortcutsList(){


    shortcutsMap.putIfAbsent("play/pause", (){
      return KeyboardShortcutNode((){player.playOrPause();}, "play/pause", iconsList: [Icons.play_arrow, Icons.pause]);
    });
    shortcutsMap.putIfAbsent("seek >", (){
      return KeyboardShortcutNode((){player.seek((_currentPlaybackPosition+const Duration(seconds: 5)));}, "seek >", iconsList: [Icons.fast_forward]);
    });
    shortcutsMap.putIfAbsent("seek <", (){
      return KeyboardShortcutNode((){player.seek((_currentPlaybackPosition-const Duration(seconds: 5)));},"seek <", iconsList: [Icons.fast_rewind]);
    });
    shortcutsMap.putIfAbsent("add char #1", (){
      KeyboardShortcutNode ksn = KeyboardShortcutNode((){}, "add char #1");
      ksn.onClick = (){

        int newEntryIndex = newEntry(_scriptTable, null, ksn.characterName!);
        _updateTableListViewFromScriptList();
        _scriptTableRebuildRequest();
        _scriptTable[newEntryIndex].focusNode.requestFocus();
      };
      return ksn;
    });
    shortcutsMap.putIfAbsent("add char #2", (){
      KeyboardShortcutNode ksn = KeyboardShortcutNode((){}, "add char #2");
      ksn.onClick = (){
        int newEntryIndex = newEntry(_scriptTable, null, ksn.characterName!);
        _updateTableListViewFromScriptList();
        _scriptTableRebuildRequest();
        _scriptTable[newEntryIndex].focusNode.requestFocus();
      };
      return ksn;
    });
    shortcutsMap.putIfAbsent("save", (){
      KeyboardShortcutNode ksn = KeyboardShortcutNode((){}, "save ", iconsList: [Icons.save]);
      ksn.onClick = (){
        _saveFileWithSnackbar(context);
      };
      return ksn;
    });
  }


  void focusNodeOrViewFollowsVideo(bool scrollFollowsVideo, bool focusNodeFollowsVideo){
    if (scrollFollowsVideo == false && focusNodeFollowsVideo == false){
      return;
    }

    for (var i = 0; i < _scriptTable.length; i++) {
      if (_scriptTable[i].isThisCurrentTCValueNotifier.value && (selectedCharacterName == allCharactersConst || selectedCharacterName == _scriptTable[i].charName)) {
        if (currentItemScrollIndex != i) {
          if (scrollFollowsVideo) {
            scriptListController.scrollTo(index: i, duration: const Duration(milliseconds: 500));
          }
          if (focusNodeFollowsVideo) {
            try {
              _scriptTable[i].focusNode.requestFocus();
            // ignore: empty_catches
            } catch (e) {
            }
          }
          currentItemScrollIndex = i;
        }
      }
    }

  }

}
