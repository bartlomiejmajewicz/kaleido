import 'dart:ffi';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class Timecode implements Comparable<Timecode> {

  static int framerate = 25; // TODO FRAMERATE SET

  

  int h=0;
  int m=0;
  int s=0;
  int f=0;


  Timecode([String timecodeAsText="00:00:00:00"]) {
    if (!tcValidateCheck(timecodeAsText)) {
      timecodeAsText = "00:00:00:00";
    }
    List<String> splittedTc = timecodeAsText.split(':');
    h = int.parse(splittedTc[0]);
    m = int.parse(splittedTc[1]);
    s = int.parse(splittedTc[2]);
    f = int.parse(splittedTc[3]);
  }

  Timecode.fromDuration(Duration duration){
    tcFromDuration(duration);
  }


  static bool tcValidateCheck(String timecodeAsText) {
  // check if the TC is a valid value
  var tcValidateCheck = RegExp(r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d):([0-5]\d)$');
    if(tcValidateCheck.hasMatch(timecodeAsText)){
      return true;
    } else{
      return false;
    }
  }

  String showTimecode(){
    String output="";
    if(h<10){
      output = "0";
    }
    output += h.toString();

    output += ":";

    if (m<10) {
      output += "0";
    }
    output += m.toString();

    output += ":";

    if (s<10) {
      output += "0";
    }
    output += s.toString();
    
    output += ":";

    if (f<10) {
      output += "0";
    }
    output += f.toString();


    return output;

  }

  int framesCount(){
    int frCount=0;
    frCount += f;
    frCount += s*framerate;
    frCount += m*60*framerate;
    frCount += h*60*60*framerate;

    return frCount;

  }

  tcFromDuration(Duration duration){
    int millis = duration.inMilliseconds;
    h = millis ~/ (1000*3600);
    millis = millis - (h*1000*3600);
    m = millis ~/ (1000*60);
    millis = millis - (m*1000*60);
    s = millis ~/ (1000);
    millis = millis - s*1000;
    f = (framerate * millis / 1000).round();
  }

  Duration tcAsDuration(){
    return Duration(
      hours: h,
      minutes: m,
      seconds: s,
      milliseconds:  ((f/framerate)*1000).round()
      );
  }

  Timecode operator + (Timecode other){
    return Timecode.fromDuration(tcAsDuration()+other.tcAsDuration());
  }

  Timecode operator - (Timecode other){
    return Timecode.fromDuration(tcAsDuration()-other.tcAsDuration());
  }
  
  @override
  int compareTo(Timecode other) {
    if (framesCount() < other.framesCount()) {
      return -1;
    } else if (framesCount() < other.framesCount()) {
      return 1;
    } else {
      return 0;
    }
  }
  
  @override
  String toString() {
    return showTimecode();
  }


}




class ScriptNode implements Comparable<ScriptNode>{

  late Timecode tcIn = Timecode();
  late String charName="";
  late String dial="";
  late Widget widget;
  ValueNotifier<bool> isThisCurrentTCValueNotifier = ValueNotifier(false);

  TextEditingController textControllerTc=TextEditingController();


  ScriptNode(Timecode timecodeIn, String characterName, String dialogue){
    tcIn = timecodeIn;
    charName = characterName;
    dial = dialogue;
  }

  ScriptNode.empty();

  @override
  String toString() {
    // TODO: implement toString
    return dial;
  }
  
  @override
  int compareTo(ScriptNode other) {
    if (tcIn.framesCount()<other.tcIn.framesCount()){
      return -1;
    } else {
      return 1;
    }
  }
  


}




// UNUSED CLASS
class MyExcellApp {

  MyExcellApp(){
    var file = '/Users/bmajewicz/Desktop/Zeszyt1.xlsx';
    var bytes = File(file).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    for (var table in excel.tables.keys) {
      print(table); //sheet Name
      print(excel.tables[table]?.maxColumns);
      print(excel.tables[table]?.maxRows);
      for (var row in excel.tables[table]!.rows) {
        for (var cell in row) {
          print('cell ${cell?.rowIndex}/${cell?.columnIndex}');
          final value = cell?.value;
          final numFormat = cell?.cellStyle?.numberFormat ?? NumFormat.standard_0;
          switch(value){
            case null:
              print('  empty cell');
              print('  format: ${numFormat}');
            case TextCellValue():
              print('  text: ${value.value}');
            case FormulaCellValue():
              print('  formula: ${value.formula}');
              print('  format: ${numFormat}');
            case IntCellValue():
              print('  int: ${value.value}');
              print('  format: ${numFormat}');
            case BoolCellValue():
              print('  bool: ${value.value ? 'YES!!' : 'NO..' }');
              print('  format: ${numFormat}');
            case DoubleCellValue():
              print('  double: ${value.value}');
              print('  format: ${numFormat}');
            case DateCellValue():
              print('  date: ${value.year} ${value.month} ${value.day} (${value.asDateTimeLocal()})');
            case TimeCellValue():
              print('  time: ${value.hour} ${value.minute} ... (${value.asDuration()})');
            case DateTimeCellValue():
              print('  date with time: ${value.year} ${value.month} ${value.day} ${value.hour} ... (${value.asDateTimeLocal()})');
          }

          print('$row');
        }
      }
    }
  }
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
      print('from ExcelFile $table'); //sheet Name
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
      //sheetObject.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1), TextCellValue("ELO"));
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

class KeyboardShortcutNode{
  Set<LogicalKeyboardKey>? logicalKeySet;
  String? characterName;
  String description;
  bool assignedNow=false;
  List<IconData>? iconsList;
  late Function onClick;

  KeyboardShortcutNode(this.onClick, this.description, {this.characterName, this.logicalKeySet, this.iconsList});


  String showShortcut(){
    String result = "";
    if (logicalKeySet != null) {
      for (LogicalKeyboardKey lkk in logicalKeySet!) {
        if (result != "") {
          result = "$result + ";
        }
        result = result + lkk.keyLabel;
      }
    }
    result = Platform.isMacOS ? result.replaceAll('Meta', 'Cmd') : result;
    result = Platform.isWindows ? result.replaceAll('Meta', 'Win') : result;
    return result;
  }
}



class SettingsClass{
  // TODO: WYZERUJ DO RELEASE
  static int rowNumber = 0;
  static int collNumber = 0;
  static String sheetName = "";
  static String videoFilePath = "";
  static String scriptFilePath = "";
  static double videoWidth = 200;
  static double videoHeight = 200;
  static Timecode videoStartTc=Timecode();

}

// UNUSED
class OutlinedButtonWithShortcut extends Tooltip {
  OutlinedButtonWithShortcut(
    {super.key,
    required onPressed, 
    required Widget child,
    required KeyboardShortcutNode keyboardShortcutNode,
    required List<KeyboardShortcutNode> shortcutsList}):
    super(
      message: keyboardShortcutNode.showShortcut(),
      child: OutlinedButton(
        onLongPress:(){
          keyboardShortcutNode.assignedNow = true;
        },
        onPressed: (){
          keyboardShortcutNode.onClick();
        },
        
        child: Text(keyboardShortcutNode.assignedNow ? "assign the shortcut" : keyboardShortcutNode.description!)),
    ){
      shortcutsList.add(keyboardShortcutNode);
  }

}


