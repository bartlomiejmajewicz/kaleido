import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:script_editor/bloc/settings_bloc.dart';
import 'package:script_editor/main.dart';
import 'package:script_editor/models/authorisation.dart';
import 'package:script_editor/models/utils.dart';
import 'package:script_editor/models/script_list.dart';
import 'package:script_editor/widgets/char_name_widget_with_autocomplete.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/keyboard_shortcut_node.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/models/timecode.dart';
import 'package:script_editor/widgets/outlined_button_with_shortcut.dart';
import 'package:script_editor/widgets/resizable_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:path/path.dart' as path_package;

class ScriptPage extends StatefulWidget {
  const ScriptPage({super.key, required this.title});

  final String title;

  @override
  State<ScriptPage> createState() => _ScriptPageState();
}


class _ScriptPageState extends State<ScriptPage> {


final Player videoPlayer = Player();
late final controller = VideoController(videoPlayer);
late final List<Player> audioPlayers = List.empty(growable: true);

late double _screenWidth;
late double _screenHeight;

Duration _currentPlaybackPosition = const Duration();

late ScriptList scriptList;
static const String allCharactersConst = "ALL CHARACTERS";
String? selectedCharacterName;
late String sheetName;

ExcelFile? scriptSourceFile;


final TextEditingController _tecDialLocSearch = TextEditingController();
final FocusNode _dialLocSearchFocusNode = FocusNode();
TextEditingController tempTextEditController = TextEditingController();
TextEditingController charNameOldTEC = TextEditingController();
TextEditingController charNameNewTEC = TextEditingController();
TextEditingController tcEntryController = TextEditingController();
TextEditingController charName01 = TextEditingController();
TextEditingController charName02 = TextEditingController();
bool tcEntryControllerActive = true;

ValueNotifier<bool> scrollFollowsVideo = ValueNotifier(false);
ValueNotifier<bool> focusNodeFollowsVideo = ValueNotifier(false);
ItemScrollController scriptListController = ItemScrollController();
int currentItemScrollIndex = 0;

int? itemIndexFromButton;
Key? currentKeyFromButton;

final ChangeNotifierReload _lowerPanelReload = ChangeNotifierReload();
final ChangeNotifierReload _upperPanelReload = ChangeNotifierReload();
final ChangeNotifierReload _lowerPanelHeaderReload = ChangeNotifierReload();
<<<<<<< HEAD
=======


final double widthButtons = 80;
final double widthColC = 100;
final double widthColD = 220;
final EdgeInsetsGeometry paddingSizeScript = const EdgeInsets.symmetric(horizontal: 4.0);
final GlobalKey rowEExpandedKey = GlobalKey();
>>>>>>> cce7b97567cf91bab25fe5e8b616317a21cdc03f


final double widthButtons = 80;
final double widthColC = 100;
final double widthColD = 220;
final EdgeInsetsGeometry paddingSizeScript = const EdgeInsets.symmetric(horizontal: 4.0);
final GlobalKey rowEExpandedKey = GlobalKey();


KeyNotifier? keyEventNotifier;

bool _isTcFromScriptToPlayerVisible = true;
bool _isTcPlayerToScriptVisible = true;
bool _isTcInVisible = true;
bool _isCharacterVisible = true;

final ValueNotifier<bool> _isUpperMenuVisible = ValueNotifier(true);

final ChangeNotifierReload _arrowHighlightedReload = ChangeNotifierReload();

@override
  void deactivate() {
    keyEventNotifier!.removeListener(keyEventShortcutProcessFromProvider);
    super.deactivate();
  }

  @override
  void dispose(){
    keyEventNotifier!.removeListener(keyEventShortcutProcessFromProvider);
    videoPlayer.dispose();
    super.dispose();
  }

  /// called to initialize async videoPlayer methods outside of the initState()
  Future<void> initStateFuture() async {
    await videoPlayer.open(Media(context.read<SettingsBloc>().state.videoFilePath!));
    await videoPlayer.setSubtitleTrack(SubtitleTrack.no());
  }

  @override
  void initState() {
    super.initState();

    
    WidgetsFlutterBinding.ensureInitialized();

    keyEventNotifier = context.read<KeyNotifier>();
    keyEventNotifier!.addListener(keyEventShortcutProcessFromProvider);


    initStateFuture();
    videoPlayer.stream.position.listen((e) {
      _currentPlaybackPosition = e;
      if (scriptList.markCurrentLine(Timecode.fromFramesCount(Timecode.countFrames(e, context.read<SettingsBloc>().state.inputFramerate), context.read<SettingsBloc>().state.inputFramerate)+context.read<SettingsBloc>().state.startingTimecode, context.read<SettingsBloc>().state.startingTimecode, context.read<SettingsBloc>().state.inputFramerate)) {
        _arrowHighlightedReload.reload();
      }
      
      if (tcEntryControllerActive) {
        tcEntryController.text = (Timecode.fromFramesCount(Timecode.countFrames(e, context.read<SettingsBloc>().state.inputFramerate), context.read<SettingsBloc>().state.inputFramerate)+context.read<SettingsBloc>().state.startingTimecode).toString();
      }
      focusNodeOrViewFollowsVideo(scrollFollowsVideo.value, focusNodeFollowsVideo.value, scriptList, selectedCharacterName);
    });

    scriptSourceFile = ExcelFile(context.read<SettingsBloc>().state.scriptFilePath!);
    scriptSourceFile!.loadFile();

    List<ScriptNode>? scriptNodesTemporary = scriptSourceFile!.importSheetToList(context.read<SettingsBloc>().state.selectedSheetName!, context.read<SettingsBloc>().state.collNumber, context.read<SettingsBloc>().state.rowNumber, context.read<SettingsBloc>().state.inputFramerate);
    if (scriptNodesTemporary != null) {
      scriptList = ScriptList(scriptNodesTemporary);
    }
    sheetName = context.read<SettingsBloc>().state.selectedSheetName!;
     _lowerPanelReload.reload();
  }


  @override
  Widget build(BuildContext context) {


    _screenWidth = MediaQuery.sizeOf(context).width;
    _screenHeight = MediaQuery.sizeOf(context).height;

    // size-responsive visibility
    _isTcFromScriptToPlayerVisible = _screenWidth < 850 ? false : true;
    _isTcPlayerToScriptVisible = _screenWidth < 800 ? false : true;
    _isTcInVisible = _screenWidth < 750 ? false : true;
    _isCharacterVisible = _screenWidth < 550 ? false : true;


    if (SettingsClass.videoHeight > _screenHeight/2) {
      SettingsClass.videoHeight = _screenHeight/3;
    }
    if (SettingsClass.videoWidth > _screenWidth/2) {
      SettingsClass.videoWidth = _screenWidth/3;
    }


    return Scaffold(
      appBar: Authorisation.isLicenseActive() ? null : AppBar(
        centerTitle: true,
        title: const Text(
          "License not active. Saving disabled.",
          style: TextStyle(color: Colors.red),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenableBuilder(
              listenable: _upperPanelReload,
              builder: (context, child) {
                return _upperPanelWidget(context);
              },),
            ListenableBuilder(
              listenable: _lowerPanelHeaderReload,
              builder: (context, child) {
                return _lowerPanelHeader();
              },),
            ListenableBuilder(
              listenable: _lowerPanelReload,
              builder: (context, child) {
                return _generateTableAsScrollablePositionListView(scriptList.getList(characterName: selectedCharacterName, searchPhrase: _tecDialLocSearch.text));
              },),
          ]
        ),
      ),
    );
  }

  Widget _upperPanelWidget(BuildContext context) {
    EdgeInsets paddingEdgeInsets = const EdgeInsets.all(4.0);

    Widget switchAudio(){

      List<Widget> list = List.empty(growable: true);
      list.add(const Text("Select audio track:"));
      list.add(
        OutlinedButtonWithShortcut(
          kns: KeyboardShortcutNode(
            () async {
              await videoPlayer.setAudioTrack(AudioTrack.uri(context.read<SettingsBloc>().state.videoFilePath!));
            },),
          child: const Text("org audio"),
        ));

      for (AudioTrack audioTrack in videoPlayer.state.tracks.audio) {
        list.add(
          OutlinedButtonWithShortcut(
            kns: KeyboardShortcutNode(
              ()async{
                await videoPlayer.setAudioTrack(audioTrack);
              },
            ),
          child: Text(audioTrack.id),
          )
        );
      }


      for (var i = 0; i < context.read<SettingsBloc>().state.audioFilesPaths.length; i++) {
        list.add(
          OutlinedButtonWithShortcut(
            kns: KeyboardShortcutNode(
              () async {
                await videoPlayer.setAudioTrack(AudioTrack.uri(context.read<SettingsBloc>().state.audioFilesPaths[i]));
              },
            ),
            child: Text(path_package.basename(context.read<SettingsBloc>().state.audioFilesPaths[i])),
            ));
      }

      return ValueListenableBuilder(
        valueListenable: SettingsClass.videoHeightNotifier,
        builder: (context, value, child) {
          return SizedBox(
            height: value,
            width: 200,
            child: ListView(
              children: list,
            ),
          );
        },
      );
    }


    Padding visibilityControllers(EdgeInsets paddingEdgeInsets) {
      return Padding(
        padding: paddingEdgeInsets,
        child: IntrinsicWidth(
          child: Column(
            children: [
              OutlinedButton(
                onPressed: (){
                  _isTcFromScriptToPlayerVisible = !_isTcFromScriptToPlayerVisible;
                  _upperPanelReload.reload();
                  _lowerPanelHeaderReload.reload();
<<<<<<< HEAD
                  _lowerPanelReload.reload();
=======
                  _scriptTableRebuildRequest();
>>>>>>> cce7b97567cf91bab25fe5e8b616317a21cdc03f
                },
                child: Row(
                  children: [
                    const Text("TC from script: "),
                    Icon(
                      _isTcFromScriptToPlayerVisible ? Icons.check_box_outlined : Icons.check_box_outline_blank)
                  ],
                )),
              OutlinedButton(
                onPressed: (){
                  _isTcPlayerToScriptVisible = !_isTcPlayerToScriptVisible;
                  _upperPanelReload.reload();
                  _lowerPanelHeaderReload.reload();
<<<<<<< HEAD
                  _lowerPanelReload.reload();
=======
                  _scriptTableRebuildRequest();
>>>>>>> cce7b97567cf91bab25fe5e8b616317a21cdc03f
                },
                child: Row(
                  children: [
                    const Text("TC to script: "),
                    Icon(
                      _isTcPlayerToScriptVisible ? Icons.check_box_outlined : Icons.check_box_outline_blank)
                  ],
                )),
              OutlinedButton(
                onPressed: (){
                  _isTcInVisible = !_isTcInVisible;
                  _upperPanelReload.reload();
                  _lowerPanelHeaderReload.reload();
<<<<<<< HEAD
                  _lowerPanelReload.reload();
=======
                  _scriptTableRebuildRequest();
>>>>>>> cce7b97567cf91bab25fe5e8b616317a21cdc03f
                },
                child: Row(
                  children: [
                    const Text("TC in: "),
                    Icon(
                      _isTcInVisible ? Icons.check_box_outlined : Icons.check_box_outline_blank)
                  ],
                )),
              OutlinedButton(
                onPressed: (){
                  _isCharacterVisible = !_isCharacterVisible;
                  _upperPanelReload.reload();
                  _lowerPanelHeaderReload.reload();
<<<<<<< HEAD
                  _lowerPanelReload.reload();
=======
                  _scriptTableRebuildRequest();
>>>>>>> cce7b97567cf91bab25fe5e8b616317a21cdc03f
                },
                child: Row(
                  children: [
                    const Text("char name visible: "),
                    Icon(
                      _isCharacterVisible ? Icons.check_box_outlined : Icons.check_box_outline_blank)
                  ],
                )),
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
              Row(
                children: [
                  Padding(
                    padding: paddingEdgeInsets,
                    child: OutlinedButtonWithShortcut(
                      kns: KeyboardShortcutNode((){
                        if (_isUpperMenuVisible.value) {
                            _isUpperMenuVisible.value = false;
                          } else {
                            _isUpperMenuVisible.value = true;
                          }
                      }),
                      child: const Icon(Icons.swap_vert),
                    ),
                  ),
                  OutlinedButtonWithShortcut(
                    kns: KeyboardShortcutNode((){_saveFileWithSnackbar(context);}),
                    child: const Icon(Icons.save),)
                ],
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
                                Padding(padding: paddingEdgeInsets,
                                  child: switchAudio()
                                ),
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
                                          int a = scriptList.replaceCharName(charNameOldTEC.text, charNameNewTEC.text);
                                          charNameOldTEC.text = "";
                                          charNameNewTEC.text = "";
                                          _lowerPanelReload.reload();
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
                                              controller: charName01,
                                              decoration: const InputDecoration(
                                                helperText: "character name #1",
                                              ),
                                            ),
                                          ),
                                          OutlinedButtonWithShortcut(
                                            kns: KeyboardShortcutNode((){
                                              int newEntryIndex = scriptList.newEntry(Timecode.fromDuration(_currentPlaybackPosition, context.read<SettingsBloc>().state.inputFramerate), charName: charName01.text, videoStartTc: context.read<SettingsBloc>().state.startingTimecode);
                                              _lowerPanelReload.reload();
                                              scriptList.getItemById(newEntryIndex).dialFocusNode.requestFocus();
                                            },),
                                            child: const Text("add char #1"),),
                                        ],
                                      ),
                                        Row(
                                        children: [
                                          SizedBox(
                                            width: 200,
                                            child: TextFormField(
                                              controller: charName02,
                                              decoration: const InputDecoration(
                                                helperText: "character name #2",
                                              ),
                                            ),
                                          ),
                                          OutlinedButtonWithShortcut(
                                            kns: KeyboardShortcutNode((){
                                              int newEntryIndex = scriptList.newEntry(Timecode.fromDuration(_currentPlaybackPosition, context.read<SettingsBloc>().state.inputFramerate), charName: charName02.text, videoStartTc: context.read<SettingsBloc>().state.startingTimecode);
                                              _lowerPanelReload.reload();
                                              scriptList.getItemById(newEntryIndex).dialFocusNode.requestFocus();
                                            },),
                                            child: const Text("add char #2")),
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
                OutlinedButtonWithShortcut(
                  kns: KeyboardShortcutNode((){videoPlayer.seek((_currentPlaybackPosition-const Duration(seconds: 5)));}),
                  child: const Icon(Icons.fast_rewind),
                ),
                OutlinedButtonWithShortcut(
                  kns: KeyboardShortcutNode((){videoPlayer.playOrPause();}),
                  child: const Row(children: [Icon(Icons.play_arrow), Icon(Icons.pause)],),
                ),
                
                OutlinedButtonWithShortcut(
                  kns: KeyboardShortcutNode((){videoPlayer.seek((_currentPlaybackPosition+const Duration(seconds: 5)));}),
                  child: const Icon(Icons.fast_forward),
                ),

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
                      videoPlayer.play();
                      tcEntryControllerActive = true;
                    },
                    onSaved: (newValue){
                      jumpToTc(Timecode(tcEntryController.text));
                      videoPlayer.play();
                      tcEntryControllerActive = true;
                    },
                    onFieldSubmitted: (value){
                      jumpToTc(Timecode(tcEntryController.text));
                      videoPlayer.play();
                      tcEntryControllerActive = true;
                    }  
                  ),
                ),
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

  



  List<DropdownMenuEntry<String>> getCharactersMenuEntries(List <String> charactersNamesList){

    charactersNamesList.insert(0, allCharactersConst);

    return charactersNamesList.map((e){
      return DropdownMenuEntry(
        value: e,
        label: e);
    }).toList();
  }





  Widget _generateTableAsScrollablePositionListView(List<ScriptNode> list) {
    // reduced number of Flexible used in the E (dialogue) column - we render it once in the header and take width size to the other rows
    RenderBox? renderBox;

    

    Widget buildRow(BuildContext context, ScriptNode scriptNode, int scriptNodeIndex){
      // if (index == itemIndexFromButton && (Platform.isMacOS ||Platform.isLinux || Platform.isWindows)) {
      //   _scriptTable[index].focusNode.requestFocus();
      // }
      Key? keyForDialField;
      if (scriptNodeIndex == itemIndexFromButton) {
        keyForDialField = currentKeyFromButton;
      } else {
        keyForDialField = UniqueKey();
      }

      renderBox ??= rowEExpandedKey.currentContext?.findRenderObject() as RenderBox?;

      scriptNode.textControllerTc.text = scriptNode.tcIn.toString();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ListenableBuilder(
            listenable: _arrowHighlightedReload,
            builder: (context, child) {
              return SizedBox(
                width: _isTcFromScriptToPlayerVisible ? widthButtons : 0,
                child: ElevatedButton(
                style: scriptNode.isThisCurrentTC ? const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)) : const ButtonStyle(),
                onPressed: (){
                  jumpToTc(scriptNode.tcIn);
                },
                child: _isTcFromScriptToPlayerVisible ? const Icon(Icons.arrow_upward) : null,
                ),
              );
            },
           
          ),
      
      
          Padding(
            padding: paddingSizeScript,
            child: _isTcPlayerToScriptVisible ? SizedBox(
              width: widthButtons,
              child: ElevatedButton(
                onPressed: (){
                  scriptNode.tcIn = tcFromVideo()+context.read<SettingsBloc>().state.startingTimecode;
                  scriptNode.textControllerTc.value = TextEditingValue(text: scriptNode.tcIn.toString());
                },
                child: const Icon(Icons.arrow_downward),
              ),
            ) : null,
          ),
      
      
          Padding(
            padding: paddingSizeScript,
            child: _isTcInVisible ? SizedBox(
              width: widthColC,
              child: TextFormField(
                controller: scriptNode.textControllerTc,
                onChanged: (value) {
                  if(Timecode.tcValidateCheck(value, context.read<SettingsBloc>().state.inputFramerate)){
                    scriptNode.tcIn = Timecode(value);
                  }
                },
              inputFormatters: [TextInputFormatter.withFunction(tcValidityInputCheck)],
              )) : null,
          ),
      
      
          Padding(
            key: UniqueKey(),
            padding: paddingSizeScript,
            child: _isCharacterVisible ? SizedBox(
              width: widthColD,
              child: CharNameWidgetWithAutocomplete(
                charactersNamesList: scriptList.getCharactersList(),
                initialValue: scriptNode.charName,
                updateFunction: (value) => scriptNode.charName=value,
                maxOptionsWidth: widthColD,
                ),
              ) : null,
          ),
          
          Padding(
            key: keyForDialField,
            padding: paddingSizeScript,
            child: SizedBox(
              width: renderBox==null ? 300 : renderBox!.size.width,
              child: TextFormField(
                onTap: () {
                  itemIndexFromButton = scriptNodeIndex;
                  currentKeyFromButton = keyForDialField;
                },
                minLines: null,
                maxLines: null,
                autofocus: true,
                focusNode: scriptNode.dialFocusNode,
                onChanged: (value) {
                  { 
                    scriptNode.dialLoc = value;
                }
                },
                scribbleEnabled: false, 
                initialValue: scriptNode.dialLoc, 
                ),
            ),
          ),
            
          Padding(
            padding: paddingSizeScript,
            child: SizedBox(
              width: widthButtons,
              child: ElevatedButton(
                child: const Icon(Icons.delete),
                onPressed: () {
                  scriptList.removeItem(scriptNode);
                  currentKeyFromButton = UniqueKey();
                  _lowerPanelReload.reload();
                  try {
                    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
                      scriptList.getItemById(scriptNodeIndex-1).dialFocusNode.requestFocus();
                    }
                  // ignore: empty_catches
                  } catch (e) {
                  }
                },),
            ),
          ),
        ],
      );
    }

    return Flexible(
      child: Column(
        children: [
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
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return buildRow(context, list[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  


  int _saveFile(){
    if (!Authorisation.isLicenseActive()) {
      return 100;
    }
    try {
      scriptSourceFile!.exportListToSheet(scriptList.getList(), sheetName, context.read<SettingsBloc>().state.timecodeFormatting, context.read<SettingsBloc>().state.rowNumber, context.read<SettingsBloc>().state.collNumber);
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
    videoPlayer.seek((tc-context.read<SettingsBloc>().state.startingTimecode).tcAsDuration());
  }

  Timecode tcFromVideo(){
    Timecode tc = Timecode.fromFramesCount(Timecode.countFrames(_currentPlaybackPosition, context.read<SettingsBloc>().state.inputFramerate), context.read<SettingsBloc>().state.inputFramerate)+context.read<SettingsBloc>().state.startingTimecode;
    return tc;
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
      if (OutlinedButtonWithShortcut.buttonsWithShortcutsList == null) {
        return;
      }
      for (OutlinedButtonWithShortcut element in OutlinedButtonWithShortcut.buttonsWithShortcutsList!) {
        if (element.kns!.assignedNow) {
          element.kns!.logicalKeySet = hk.logicalKeysPressed;
          assignShortcutOperation = true;
          element.kns!.assignedNow = false;
          try {
            OutlinedButtonWithShortcut.globalButtonsReloadNotifier!.reload();
          // ignore: empty_catches
          } catch (e) {
          }
          
        }
        if(assignShortcutOperation == false && setEquals(hk.logicalKeysPressed, element.kns!.logicalKeySet)){
          element.kns!.onClick();
        }
      }
    }
  }


  void updateUi(int a){
    // ignore: unused_element
    setState(() {
    });
  }


  void focusNodeOrViewFollowsVideo(bool scrollFollowsVideo, bool focusNodeFollowsVideo, ScriptList scriptList, String? selectedCharacterName){
    if (scrollFollowsVideo == false && focusNodeFollowsVideo == false){
      return;
    }

    for (var i = 0; i < scriptList.getList().length; i++) {
      if (scriptList.getItemById(i).isThisCurrentTC && (selectedCharacterName == null || selectedCharacterName == scriptList.getItemById(i).charName)) {
        if (currentItemScrollIndex != i) {
          if (scrollFollowsVideo) {
            scriptListController.scrollTo(index: i, duration: const Duration(milliseconds: 500));
          }
          if (focusNodeFollowsVideo) {
            try {
              scriptList.getItemById(i).dialFocusNode.requestFocus();
            // ignore: empty_catches
            } catch (e) {
            }
          }
          currentItemScrollIndex = i;
        }
      }
    }

  }
  
  Widget _lowerPanelHeader() {
    return Row(
      children: [
        Padding(
          padding: paddingSizeScript,
          child: _isTcFromScriptToPlayerVisible ? SizedBox(
            width: widthButtons,
            child: const Text("TC from script\nto player"),
          ) : null
        ),
        Padding(
          padding: paddingSizeScript,
          child: _isTcPlayerToScriptVisible ? SizedBox(
            width: widthButtons,
            child: const Text("TC from player\nto script")
          ) : null,
        ),
        Padding(
          padding: paddingSizeScript,
          child: _isTcInVisible ? SizedBox(
            width: widthColC,
            child: FilledButton(
              child: const Text("TC in"),
              onPressed: () {
                scriptList.sortItems();
<<<<<<< HEAD
                _lowerPanelReload.reload();
=======
                _scriptTableRebuildRequest();
>>>>>>> cce7b97567cf91bab25fe5e8b616317a21cdc03f
              },)) : null,
        ),
        Padding(
          padding: paddingSizeScript,
          child: _isCharacterVisible ? SizedBox(
            width:  widthColD,
            child: DropdownMenu(
              dropdownMenuEntries: getCharactersMenuEntries(scriptList.getCharactersList()),
              initialSelection: allCharactersConst,
              onSelected: (value) {
                selectedCharacterName = value;
                if (value == allCharactersConst) {
                  selectedCharacterName = null;
                }
<<<<<<< HEAD
                _lowerPanelReload.reload();
=======
                _scriptTableRebuildRequest();
>>>>>>> cce7b97567cf91bab25fe5e8b616317a21cdc03f
              },
            ),
          ) : null,
        ),
        Expanded(
          key: rowEExpandedKey,
<<<<<<< HEAD
          child: Stack(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: "search in loc dialogue...",
                  hintStyle: TextStyle(color: Colors.grey)
                ),
                controller: _tecDialLocSearch,
                focusNode: _dialLocSearchFocusNode,
                onChanged: (value) {
                  _lowerPanelReload.reload();
                },
              ),
              Container(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: (){
                    _tecDialLocSearch.text = "";
                    _lowerPanelReload.reload();
                  },
                  child: const Icon(Icons.cancel)),
              ),
            ],
=======
          child: TextField(
            decoration: const InputDecoration(
              hintText: "search in loc dialogue...",
              hintStyle: TextStyle(color: Colors.grey)
            ),
            controller: _tecDialLocSearch,
            focusNode: _dialLocSearchFocusNode,
            onChanged: (value) {
              _scriptTableRebuildRequest();
            },
>>>>>>> cce7b97567cf91bab25fe5e8b616317a21cdc03f
          ),
        ),
        Padding(padding: paddingSizeScript,
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
}
