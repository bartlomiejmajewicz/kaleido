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


class UpperPanelReload extends ChangeNotifier{
  void upperPanelReload(){
    notifyListeners();
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

UpperPanelReload upperPanelReload = UpperPanelReload();

Widget _lowerPanel = const Flexible(child: Text(""));


Map<String, KeyboardShortcutNode> shortcutsMap = <String, KeyboardShortcutNode>{};

KeyNotifier? keyEventNotifier;

final ValueNotifier<bool> _isTcFromScriptToPlayerVisible = ValueNotifier(true);
final ValueNotifier<bool> _isTcPlayerToScriptVisible = ValueNotifier(true);
final ValueNotifier<bool> _isTcInVisible = ValueNotifier(true);
final ValueNotifier<bool> _isCharacterVisible = ValueNotifier(true);
final ValueNotifier<double> _listViewElementHeight = ValueNotifier(50);

final ValueNotifier<bool> _isUpperMenuVisible = ValueNotifier(true);

@override
  void deactivate() {
    keyEventNotifier!.removeListener(keyEventShortcutProcessFromProvider);
    super.deactivate();
  }

  @override
  void dispose(){
    keyEventNotifier!.removeListener(keyEventShortcutProcessFromProvider);
    player.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    
    WidgetsFlutterBinding.ensureInitialized();

    keyEventNotifier = context.read<KeyNotifier>();
    keyEventNotifier!.addListener(keyEventShortcutProcessFromProvider);


    player.open(Media(SettingsClass.videoFilePath));
    player.stream.position.listen((e) {
      _currentPlaybackPosition = e;
      markCurrentLine(_scriptTable);
      if (tcEntryControllerActive) {
        tcEntryController.text =  (Timecode.fromFramesCount(Timecode.countFrames(e))+SettingsClass.videoStartTc).toString();
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

    _initializeShortcutsList();
  }


  @override
  Widget build(BuildContext context) {


    _screenWidth = MediaQuery.sizeOf(context).width;
    _screenHeight = MediaQuery.sizeOf(context).height;

    // size-responsive visibility
    _isTcFromScriptToPlayerVisible.value = _screenWidth < 850 ? false : true;
    _isTcPlayerToScriptVisible.value = _screenWidth < 800 ? false : true;
    _isTcInVisible.value = _screenWidth < 750 ? false : true;
    _isCharacterVisible.value = _screenWidth < 550 ? false : true;


    SettingsClass.videoHeight = _screenHeight/3;
    SettingsClass.videoWidth = _screenWidth/2;


    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _upperPanelWidget(context),
          ListenableBuilder(
            listenable: upperPanelReload,
            builder: (context, child) {
              return _lowerPanel;
            },),
          ]
        ),
      ),
    );
  }

  Widget _upperPanelWidget(BuildContext context) {
    EdgeInsets paddingEdgeInsets = const EdgeInsets.all(4.0);


    Padding visibilityControllers(EdgeInsets paddingEdgeInsets) {
      return Padding(
        padding: paddingEdgeInsets,
        child: IntrinsicWidth(
          child: Column(
            children: [
              _createVisibilityOptionButtonWithNotifier(_isTcFromScriptToPlayerVisible, "TC from script: "),
              _createVisibilityOptionButtonWithNotifier(_isTcPlayerToScriptVisible, "TC from script: "),
              _createVisibilityOptionButtonWithNotifier(_isTcInVisible, "TC in: "),
              _createVisibilityOptionButtonWithNotifier(_isCharacterVisible, "char name visible: "),
              Row(
                children: [
                  const Text("Line height:"),
                  Column(
                    children: [
                      IconButton(
                        onPressed: (){
                          _listViewElementHeight.value+=5;
                          _updateTableListViewFromScriptList();
                          _scriptTableRebuildRequest();
                        },
                        icon: const Icon(Icons.arrow_drop_up_outlined)
                        ),
                      IconButton(
                        onPressed: (){
                          _listViewElementHeight.value-=5;
                          _updateTableListViewFromScriptList();
                          _scriptTableRebuildRequest();
                        },
                        icon: const Icon(Icons.arrow_drop_down_outlined)
                        ),
                    ],
                  ),
                  ValueListenableBuilder(
                    valueListenable: _listViewElementHeight,
                    builder: (context, value, child) {
                      return Text(_listViewElementHeight.value.toString());
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    

    return LayoutBuilder(
      builder: (context, constraints) {

        // size-responsive visibility
        Widget leftFromVideo = constraints.maxWidth < 900 ? const SizedBox() : visibilityControllers(paddingEdgeInsets);
        Widget rightFromVideo = constraints.maxWidth >= 900 ? const SizedBox() : visibilityControllers(paddingEdgeInsets);
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: paddingEdgeInsets,
                child: OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap['upperPanelVisibility'],),
              ),
              ValueListenableBuilder(
                valueListenable: _isUpperMenuVisible,
                builder: (context, value, child) {
                  return SizedBox(
                    height: _isUpperMenuVisible.value ? null : 0,
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: paddingEdgeInsets,
                                  child: Column(
                                    children: [
                                      OutlinedButtonWithShortcut(updateUiMethod: updateUi, kns: shortcutsMap["save"]),
                                    ]
                                  ),
                                ),
                                leftFromVideo,
                                Padding(
                                  padding: paddingEdgeInsets,
                                  child: Column(
                                    children: [
                                      ResizebleWidget(child: Video(controller: controller)),
                                    ],
                                  ),
                                ),
                                rightFromVideo,
                                Padding(
                                  padding: paddingEdgeInsets,
                                  child: Column(
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
                                ),
                                Padding(
                                  padding: paddingEdgeInsets,
                                  child: Column(
                                    children: [
                                      const Text("Add new lines:"),
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
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                        
                      ],
                    ),
                  );
                },
              ),
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
        );
      },
      
    );
    
  }

  

  OutlinedButton _createVisibilityOptionButtonWithNotifier(ValueNotifier<bool> valueListenable, String text) {
    return OutlinedButton(
      child: ValueListenableBuilder(valueListenable: valueListenable, builder: (context, value, child) {
        Icon icon = Icon( value ? Icons.check_box_outlined : Icons.check_box_outline_blank);
        return Row(
          children: [
            Text(text),
            icon,
          ],
        );
      },),
      onPressed: () {
        valueListenable.value = !valueListenable.value;
        _updateTableListViewFromScriptList();
        _scriptTableRebuildRequest();
    },);
  }





  void markCurrentLine(List<ScriptNode> scriptList){
    bool isThereAChange = false;
    for (var i = 0; i < scriptList.length; i++) {
      if ((Timecode.fromFramesCount(Timecode.countFrames(_currentPlaybackPosition))+SettingsClass.videoStartTc).framesCount() < scriptList[i].tcIn.framesCount() && !isThereAChange && i>0) {
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
    _lowerPanel = _generateTableAsScrollablePositionListView();
  }


  Widget _generateTableAsScrollablePositionListView() {
    const double widthButtons = 80;
    const double widthColC = 100;
    const double widthColD = 220;
    const EdgeInsetsGeometry paddingSize = EdgeInsets.symmetric(horizontal: 4.0);

    
    Row headerRow(){
      return Row(
        children: [
          Padding(
            padding: paddingSize,
            child: _isTcFromScriptToPlayerVisible.value ? const SizedBox(
              width: widthButtons,
              child: Text("TC from script\nto player"),
            ) : null
          ),
          Padding(
            padding: paddingSize,
            child: _isTcPlayerToScriptVisible.value ? const SizedBox(
              width: widthButtons,
              child: Text("TC from player\nto script")
            ) : null,
          ),
          Padding(
            padding: paddingSize,
            child: _isTcInVisible.value ? SizedBox(
              width: widthColC,
              child: FilledButton(
                child: const Text("TC in"),
                onPressed: () {
                  _scriptTable.sort();
                  _updateTableListViewFromScriptList();
                  _scriptTableRebuildRequest();
                },)) : null,
          ),
          Padding(
            padding: paddingSize,
            child: _isCharacterVisible.value ? SizedBox(
              width:  widthColD,
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
            ) : null,
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

    Widget buildRow(BuildContext context, int index){
      // if (index == itemIndexFromButton && (Platform.isMacOS ||Platform.isLinux || Platform.isWindows)) {
      //   _scriptTable[index].focusNode.requestFocus();
      // }

      if (_scriptTable[index].charName != selectedCharacterName && selectedCharacterName != allCharactersConst) {
        return const Row();
      }

      _scriptTable[index].textControllerTc.text = _scriptTable[index].tcIn.toString();
      return SizedBox(
        height: _listViewElementHeight.value,
        child: Row(
          key: UniqueKey(),
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ValueListenableBuilder<bool>(valueListenable: _scriptTable[index].isThisCurrentTCValueNotifier, builder: (context, value, child) {
              return SizedBox(
                width: _isTcFromScriptToPlayerVisible.value ? widthButtons : 0,
                child: ElevatedButton(
                style: _scriptTable[index].isThisCurrentTCValueNotifier.value ? const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)) : const ButtonStyle(),
                onPressed: (){
                  jumpToTc(_scriptTable[index].tcIn);
                },
                child: _isTcFromScriptToPlayerVisible.value ? const Icon(Icons.arrow_upward) : null,
                ),
              );
            },),
        
        
            Padding(
              padding: paddingSize,
              child: _isTcPlayerToScriptVisible.value ? SizedBox(
                width: widthButtons,
                child: ElevatedButton(
                  onPressed: (){
                    _scriptTable[index].tcIn = tcFromVideo()+SettingsClass.videoStartTc;
                    _scriptTable[index].textControllerTc.value = TextEditingValue(text: _scriptTable[index].tcIn.toString());
                  },
                  child: const Icon(Icons.arrow_downward),
                ),
              ) : null,
            ),
        
        
            Padding(
              padding: paddingSize,
              child: _isTcInVisible.value ? SizedBox(
                width: widthColC,
                child: TextFormField(
                  controller: _scriptTable[index].textControllerTc,
                  onChanged: (value) {
                    if(Timecode.tcValidateCheck(value)){
                      _scriptTable[index].tcIn = Timecode(value);
                    }
                  },
                inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],
                )) : null,
            ),
        
        
            Padding(
              padding: paddingSize,
              child: _isCharacterVisible.value ? SizedBox(
                width: widthColD,
                child: CharNameWidgetWithAutocomplete(
                  charactersNamesList: getCharactersList(_scriptTable),
                  initialValue: _scriptTable[index].charName,
                  updateFunction: (value) => _scriptTable[index].charName=value,
                  maxOptionsWidth: widthColD,
                  ),
                ) : null,
            ),
            
            Flexible(
              child: Padding(
                padding: paddingSize,
                child: SizedBox(
                  //height: _listViewElementHeight.value,
                  child: TextFormField(
                    minLines: null,
                    maxLines: null,
                    autofocus: true,
                    focusNode: _scriptTable[index].dialFocusNode,
                    onChanged: (value) {
                      { 
                        _scriptTable[index].dial = value;
                    }
                    },
                    scribbleEnabled: false, 
                    initialValue: _scriptTable[index].dial, 
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
                    try {
                      _scriptTable[index].dialFocusNode.requestFocus();
                    // ignore: empty_catches
                    } catch (e) {
                    }
                  },),
              ),
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: Column(
        children: [
          headerRow(),
          Expanded(
            child: Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.arrowRight, control: true) : DirectionalFocusIntent(TraversalDirection.right, ignoreTextFields: false),
                SingleActivator(LogicalKeyboardKey.arrowLeft, control: true) : DirectionalFocusIntent(TraversalDirection.left, ignoreTextFields: false),
                SingleActivator(LogicalKeyboardKey.arrowDown, control: true) : DirectionalFocusIntent(TraversalDirection.down, ignoreTextFields: false),
                SingleActivator(LogicalKeyboardKey.arrowUp, control: true) : DirectionalFocusIntent(TraversalDirection.up, ignoreTextFields: false)
              },
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
          ),
        ],
      ),
    );
  }


  


  int _saveFile(){
    try {
      scriptSourceFile!.exportListToSheet(_scriptTable, sheetName, SettingsClass.timecodeFormatting);
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
    Timecode tc = Timecode.fromFramesCount(Timecode.countFrames(_currentPlaybackPosition))+SettingsClass.videoStartTc;
    return tc;
  }


  int newEntry(List<ScriptNode> scriptList, Timecode? tcIn, [String? charName = "char name", String dial = 'dialogue']) {
    charName ??= "";
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
    if (keyEventNotifier == null) {
      return;
    }
    if (keyEventNotifier!.currentKeyEvent == null) {
      return;
    }
    _keyEventShortcutProcess(keyEventNotifier!.currentKeyEvent!);
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
    upperPanelReload.upperPanelReload();
    //_scriptTableRebuildFlag.value = !_scriptTableRebuildFlag.value;

  }

  void updateUi(int a){
    // ignore: unused_element
    setState(() {
    });
  }
  void _initializeShortcutsList(){


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

        int newEntryIndex = newEntry(_scriptTable, null, ksn.characterName);
        _updateTableListViewFromScriptList();
        _scriptTableRebuildRequest();
        _scriptTable[newEntryIndex].dialFocusNode.requestFocus();
      };
      return ksn;
    });
    shortcutsMap.putIfAbsent("add char #2", (){
      KeyboardShortcutNode ksn = KeyboardShortcutNode((){}, "add char #2");
      ksn.onClick = (){
        int newEntryIndex = newEntry(_scriptTable, null, ksn.characterName);
        _updateTableListViewFromScriptList();
        _scriptTableRebuildRequest();
        _scriptTable[newEntryIndex].dialFocusNode.requestFocus();
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
    shortcutsMap.putIfAbsent("upperPanelVisibility", (){
      KeyboardShortcutNode ksn = KeyboardShortcutNode((){
        if (_isUpperMenuVisible.value) {
            _isUpperMenuVisible.value = false;
          } else {
            _isUpperMenuVisible.value = true;
          }
      }, "upperPanelVisibility", iconsList: [Icons.swap_vert]);
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
              _scriptTable[i].dialFocusNode.requestFocus();
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
