
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/main.dart';
import 'package:script_editor/models/script_node.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/models/timecode.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});


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
                    OutlinedButton(onPressed: selectVideoFile, child: const Text("select video file...")),
                    SelectableText("selected file: ${SettingsClass.videoFilePath}", maxLines: 2, style: const TextStyle(overflow: TextOverflow.clip),),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select script file:"),
                    OutlinedButton(onPressed: selectScriptFile, child: const Text("select script file...")),
                    SelectableText("selected file: ${SettingsClass.scriptFilePath}", maxLines: 2, style: const TextStyle(overflow: TextOverflow.clip),),
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
                    fpsSelector(),
                    Text('selected fps: ${Timecode.framerate}'),
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
      setState(() {
        
      });
    } else {
    // User canceled the picker
      _showPickerDialogCancelled('a video file');
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
      _showPickerDialogCancelled('a script file');
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
      try {
        setState(() {
        SettingsClass.sheetName = value!;
        });
      } catch (e) {
        _showPickerDialogCancelled("an existing sheet name");
      }

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
                Text('You have to select $whichFile to continue'),
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
