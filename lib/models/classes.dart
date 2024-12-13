import 'dart:io';

import 'package:excel/excel.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/models/timecode.dart';


enum TimecodeFormatting{
  formatHhMmSsFf,
  formatMmSs
}


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
    try {
      var fileBytes = _excel.save();
      _file
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);
    } catch (e) {
      throw e;
    }

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
    if (_excel.tables[sheetName] == null) {
      return;
    }
    for (var row in _excel.tables[sheetName]!.rows) {
      if (rowNr >= SettingsClass.rowNumber) {
        
        int collNr = 0;
        int tcInColl = SettingsClass.collNumber;
        int charNameColl = SettingsClass.collNumber+1;
        int dialColl = SettingsClass.collNumber+2;
        ScriptNode scriptNode = ScriptNode.empty();
        for (var cell in row) {
          if (cell == null) {
            break;
          }
          if (cell.value == null) {
            break;
          }
          if (cell.value.value == null) {
            break;
          }

          if (collNr == tcInColl) {
            scriptNode.tcIn = Timecode(cell.value.value.toString());
            if (sctiptList.isNotEmpty && Timecode.tcAsMmSsValidateCheck(cell.value.value.toString()) && !Timecode.tcValidateCheck(cell.value.value.toString())) {
              if (sctiptList.last.tcIn.m <= scriptNode.tcIn.m) {
                // previous TC is most probably in the same hour
                scriptNode.tcIn.h = sctiptList.last.tcIn.h;
              } else {
                // previous TC m is later than new TC == new hour
                scriptNode.tcIn.h = sctiptList.last.tcIn.h+1;
              }
            }
          }
          if (collNr == charNameColl) {
            scriptNode.charName = cell.value.value.toString();
          }
          if (collNr == dialColl) {
            scriptNode.dial = cell.value.value.toString();
          }
          collNr++;
        }
        sctiptList.add(scriptNode);
      }
      rowNr++;
    }
    //sctiptList.sort();
  }

  void exportListToSheet(List<ScriptNode> myList, String sheetNameLoc, TimecodeFormatting tcFormatting){
    Sheet sheetObject = _excel[sheetNameLoc];
    int a=0;
    for (var scriptNode in myList) {
      switch (tcFormatting) {
        case TimecodeFormatting.formatMmSs:
          sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: SettingsClass.collNumber+0, rowIndex: SettingsClass.rowNumber+a), TextCellValue(scriptNode.tcIn.asStringFormattedMmSs()));
          break;
        default:
          sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: SettingsClass.collNumber+0, rowIndex: SettingsClass.rowNumber+a), TextCellValue(scriptNode.tcIn.toString()));
          break;
      }
      sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: SettingsClass.collNumber+1, rowIndex: SettingsClass.rowNumber+a), TextCellValue(scriptNode.charName));
      sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: SettingsClass.collNumber+2, rowIndex: SettingsClass.rowNumber+a), TextCellValue(scriptNode.dial));
      a++;
    }
    while(a<sheetObject.rows.length){
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
