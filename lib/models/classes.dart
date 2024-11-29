import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:script_editor/models/keyboard_shortcut_node.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/models/timecode.dart';






abstract class SourceFile{
  late File _file;

  void loadFile();
  void saveFile();
  void exportListToFileFormat();

  SourceFile(String fileLocation){
    _file = File(fileLocation);
  }
  SourceFile.fromFile(File file){
    _file = file;
  }

}

class ExcelFile extends SourceFile{

  ExcelFile(super.fileLocation);
  ExcelFile.fromFile(super.file) : super.fromFile();

  late dynamic _excel;
  List<String> sheetsList = List.empty(growable: true);

  @override
  void loadFile() {
    var bytes = _file.readAsBytesSync();
    _excel = Excel.decodeBytes(bytes);
    for (var table in _excel.tables.keys) {
      sheetsList.add(table);
    }
  }


  @override
  void saveFile() {
    var fileBytes = _excel.save();
    _file
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes);
  }
  
  @override
  void exportListToFileFormat() {

  }

  File fileGetter(){
    return _file;
  }

  void importSheetToList(String sheetName, List <ScriptNode> sctiptList){
    sctiptList.clear();
    int rowNr = 0;
    for (var row in _excel.tables[sheetName]!.rows) {
      if (rowNr >= SettingsClass.rowNumber) {
        
        int collNr = 0;
        int tcInColl = SettingsClass.collNumber;
        int charNameColl = SettingsClass.collNumber+1;
        int dialColl = SettingsClass.collNumber+2;
        ScriptNode scriptNode = ScriptNode.empty();
        for (var cell in row) {
          //FIXME: popraw te warunki, bo wiocha
          if(cell != null && cell.value != null && cell.value.value != null){
            if (collNr == tcInColl) {
              scriptNode.tcIn = Timecode(cell.value.value.toString());
            }
            if (collNr == charNameColl) {
              scriptNode.charName = cell.value.value.toString();
            }
            if (collNr == dialColl) {
              scriptNode.dial = cell.value.value.toString();
            }
          }
          collNr++;
        }
        sctiptList.add(scriptNode);
      }
      rowNr++;
    }
    sctiptList.sort();
  }

  void exportListToSheet(List<ScriptNode> myList, String sheetNameLoc){
    Sheet sheetObject = _excel[sheetNameLoc];
    int a=0;
    for (var scriptNode in myList) {
      sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: SettingsClass.collNumber+0, rowIndex: SettingsClass.rowNumber+a), TextCellValue(scriptNode.tcIn.toString()));
      sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: SettingsClass.collNumber+1, rowIndex: SettingsClass.rowNumber+a), TextCellValue(scriptNode.charName));
      sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: SettingsClass.collNumber+2, rowIndex: SettingsClass.rowNumber+a), TextCellValue(scriptNode.dial));
      a++;
    }
    while(a<sheetObject.maxRows){
      sheetObject.removeRow(a);
      a++;
    }
  }



  List<dynamic> listSheets(){
    List<dynamic> sheetsList = List.empty(growable: true);
    for (var table in _excel.tables.keys) {
      sheetsList.add(table);
    }
    return sheetsList;
  }

}

//ignore: must_be_immutable
class OutlinedButtonWithShortcut extends StatelessWidget{
  final ValueChanged<int>updateUiMethod;
  KeyboardShortcutNode? kns;
  OutlinedButtonWithShortcut({super.key, required this.updateUiMethod, this.kns});

  @override
  Widget build(BuildContext context) {
    if (kns != null) {
      return generateButtonWithShortcut(kns!, context);
    } else {
      return OutlinedButton(onPressed: (){}, child: const Text("missing function..."));
    }
  }

  Widget generateButtonWithShortcut(KeyboardShortcutNode ksn, BuildContext context){
    Widget label;
    if (ksn.iconsList != null) {
      List<Widget> iconsList = List.empty(growable: true);
      for (var element in ksn.iconsList!) {
        iconsList.add(Icon(element));
      }
      label = Row(children: iconsList);
    } else {
      label = Text(ksn.description);
    }
    return ValueListenableBuilder(valueListenable: ksn.assignedNowNotifier, builder: (context, value, child){
      return Tooltip(
        key: GlobalKey(),
        message: ksn.toString(),
        child: OutlinedButton(
        onLongPress:(){
          updateUiMethod(0);
          ksn.assignedNowNotifier.value = true;
          updateUiMethod(0);
        },
        onPressed: (){
          if (ksn.assignedNowNotifier.value) {
            ksn.assignedNowNotifier.value = false;
            updateUiMethod(0);
          } else {
            ksn.onClick();
          }
        },
        child: ksn.assignedNowNotifier.value ? const Text("assign the shortcut") : label,
        ),
      );
    });
  }

}
