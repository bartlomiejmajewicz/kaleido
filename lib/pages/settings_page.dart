
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/models/timecode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});


  @override
  State<SettingsPage> createState() => _SettingsPageState();

}


class _SettingsPageState extends State<SettingsPage> {

  ExcelFile? excelFile;
  TextEditingController tecColl = TextEditingController();
  TextEditingController tecRow = TextEditingController();

  final ValueNotifier<bool> _videoFileSelectorActive = ValueNotifier(true);
  final ValueNotifier<bool> _scriptFileSelectorActive = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    tecColl.text = (SettingsClass.collNumber+1).toString();
    tecRow.text = (SettingsClass.rowNumber+1).toString();
  }

  @override
  Widget build(BuildContext context) {
    if(SettingsClass.scriptFilePath.isNotEmpty){
      try {
        excelFile=ExcelFile(SettingsClass.scriptFilePath);
        excelFile!.loadFile();
        SettingsClass.scriptFile = excelFile;
      // ignore: empty_catches
      } catch (e) {
      }
    }
    return Scaffold(
      body: SizedBox(
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
                    ValueListenableBuilder(valueListenable: _videoFileSelectorActive, builder: (context, value, child) {
                      return OutlinedButton(
                        onPressed: value ? _selectVideoFile : null,
                        child: const Text("select video file..."),
                        );
                    },),
                    
                    SelectableText("selected file: ${SettingsClass.videoFilePath}", maxLines: 2, style: const TextStyle(overflow: TextOverflow.clip),),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select script file:"),
                    ValueListenableBuilder(valueListenable: _scriptFileSelectorActive, builder: (context, value, child) {
                      return OutlinedButton(
                        onPressed: value ? _selectScriptFile : null,
                        child: const Text("select script file..."));
                    },
                    ),
                    SelectableText("selected file: ${SettingsClass.scriptFilePath}", maxLines: 2, style: const TextStyle(overflow: TextOverflow.clip),),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select sheet:"),
                    _sheetSelectorWidget(),
                    Text('selected sheet name: ${SettingsClass.sheetName}'),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select starting column: "),
                    TextFormField(
                      controller: tecColl,
                      onChanged: (value) => setState((){SettingsClass.collNumber = (value!="") ? int.parse(value)-1 : 0;}),
                      inputFormatters: [TextInputFormatter.withFunction(_columnOrRowNumberValidityCheck)]
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
                            }, child: const Icon(Icons.plus_one)),
                            OutlinedButton(onPressed: (){                        
                              if (SettingsClass.collNumber >=1) {
                                setState(() {
                                  SettingsClass.collNumber--;
                                  tecColl.text = (SettingsClass.collNumber+1).toString();
                                });
                              }
                            }, child: const Icon(Icons.exposure_minus_1)),
                          ],
                        ),
                        Flexible(child: Text('selected collumn: ${SettingsClass.collNumber+1}')),
                      ],
                    ),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select starting row: "),
                    TextFormField(
                      controller: tecRow,
                      onChanged: (value) => setState((){SettingsClass.rowNumber = (value!="") ? int.parse(value)-1 : 0;}),
                      inputFormatters: [TextInputFormatter.withFunction(_columnOrRowNumberValidityCheck)]
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
                            }, child: const Icon(Icons.plus_one)),
                            OutlinedButton(onPressed: (){                        
                              if (SettingsClass.rowNumber >=1) {
                                setState(() {
                                  SettingsClass.rowNumber--;
                                  tecRow.text = (SettingsClass.rowNumber+1).toString();
                                });
                              }
                            }, child: const Icon(Icons.exposure_minus_1)),
                          ],
                        ),
                        Flexible(child: Text('selected row: ${SettingsClass.rowNumber+1}', overflow: TextOverflow.clip,)),
                      ],),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select project framerate: "),
                    _fpsSelectorWidget(),
                    Text('selected fps: ${Timecode.framerate}'),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select timecode output formatting: "),
                    _formattingSelector(),
                    Text('selected format: ${_formattingOutput(SettingsClass.timecodeFormatting)}'),
                  ]),
                  PaddingTableRow(children: [
                    const Text("starting TC: "),
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
                      inputFormatters: [TextInputFormatter.withFunction(_tcValidityInputCheck)],
                      //style: TextStyle(backgroundColor: Colors.green),
                      //style: TextStyle().apply(backgroundColor: Colors.amber),
                    )),
                    Text(SettingsClass.videoStartTc.toString())
                  ]),
                ],
              ),
              _sheetPreviewWidget(),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _saveSharedPreference(String key, String value) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(key, value);
  }

  Future<void> _selectVideoFile() async {
    _videoFileSelectorActive.value = false;
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      SettingsClass.videoFilePath = result.files.single.path!;
      _saveSharedPreference('videoPath', result.files.single.path!);
      setState(() {
        
      });
    } else {
    // User canceled the picker
      if (SettingsClass.videoFilePath.isEmpty) {
        _showPickerDialogCancelled('You have to select a video file to continue');
      }
    }
    _videoFileSelectorActive.value = true;
  }


  Future<void> _selectScriptFile() async {
    _scriptFileSelectorActive.value = false;
    // select the excel file, list the sheets and save the excel file to the var
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xls', 'xlsx']);
    if (result != null) {
      SettingsClass.scriptFilePath = result.files.single.path!;
      try {
        excelFile = ExcelFile(result.files.single.path!);
        SettingsClass.scriptFile = excelFile;
        excelFile!.loadFile();
        _saveSharedPreference('scriptPath', result.files.single.path!);
        
      } catch (e) {
        _showPickerDialogCancelled("error while opening the file: $e");
      }
      setState(() {
        
      });
    } else {
    // User canceled the picker
      if (SettingsClass.videoFilePath.isEmpty) {
          _showPickerDialogCancelled('You have to select a script file to continue');
        }
    }
    _scriptFileSelectorActive.value = true;
  }

  TextEditingValue _columnOrRowNumberValidityCheck(TextEditingValue oldValue, TextEditingValue newValue) {
    RegExp numberPattern = RegExp(r'^\d{0,2}$');
    if (numberPattern.hasMatch(newValue.text) && newValue.text!="0"){
      return newValue;
    } else {
      return oldValue;
    }
  }

  DropdownMenu<String> _sheetSelectorWidget(){
    return DropdownMenu<String>(
    enabled: SettingsClass.scriptFilePath.isNotEmpty,
    width: 200,
    label: const Text("select excel sheet"),
    initialSelection: SettingsClass.sheetName.isNotEmpty ? SettingsClass.sheetName : null,
    onSelected: (value) {
      try {
        setState(() {
        SettingsClass.sheetName = value!;
        _saveSharedPreference('sheetName', value);
        });
      } catch (e) {
        _showPickerDialogCancelled("You have to select an existing sheet name to continue");
      }

    },
    dropdownMenuEntries: _getSheetsDropdownMenuEntries(),
    );
  }

  Widget _fpsSelectorWidget(){
    return IntrinsicWidth(
      child: DropdownMenu(
        width: 200,
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
          DropdownMenuEntry(value: 30, label: "29,97 DF / 30 fps"),
        ],
        ),
    );
  }

  Widget _formattingSelector(){
    return IntrinsicWidth(
      child: DropdownMenu(
        width: 200,
        label: const Text("set output formatting"),
        onSelected: (value) {
          setState(() {
            SettingsClass.timecodeFormatting = value;
          });
        },
        initialSelection: SettingsClass.timecodeFormatting,
        dropdownMenuEntries: const <DropdownMenuEntry>[
          DropdownMenuEntry(value: TimecodeFormatting.formatHhMmSsFf, label: "HH:MM:SS:FF"),
          DropdownMenuEntry(value: TimecodeFormatting.formatMmSs, label: "MM:SS"),
        ],
        ),
    );
  }

  String _formattingOutput(TimecodeFormatting tcFormat) {
    switch (tcFormat) {
      case TimecodeFormatting.formatHhMmSsFf:
        return "HH:MM:SS:FF";
      case TimecodeFormatting.formatMmSs:
        return "MM:SS";
      default:
        return "HH:MM:SS:FF";
    }
  }

  List<DropdownMenuEntry<String>> _getSheetsDropdownMenuEntries() {
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

  Future<void> _showPickerDialogCancelled(String description) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selector canceled'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(description),
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

  TextEditingValue _tcValidityInputCheck(TextEditingValue oldValue, TextEditingValue newValue) {
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


  DataTable _sheetPreviewWidget(){
    List<ScriptNode> list = List.empty(growable: true);
    List<DataRow> datarows = List.empty(growable: true);
    if (SettingsClass.scriptFilePath != "" && SettingsClass.sheetName != "" && excelFile != null) {
      excelFile!.importSheetToList(SettingsClass.sheetName, list);
      for (var i = 0; i < 3 && i < list.length; i++) {
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