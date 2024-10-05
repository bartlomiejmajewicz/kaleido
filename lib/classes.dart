import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';


class Timecode implements Comparable<Timecode> {

  int framerate = 25; // TODO FRAMERATE SET

  

  int h=0;
  int m=0;
  int s=0;
  int f=0;


  Timecode(String timecodeAsText) {
    List<String> splittedTc = timecodeAsText.split(':');
    h = int.parse(splittedTc[0]);
    m = int.parse(splittedTc[1]);
    s = int.parse(splittedTc[2]);
    f = int.parse(splittedTc[3]);

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

  
  @override
  int compareTo(Timecode other) {
    if (framesCount() < other.framesCount()) {
      return -1;
    } else if (framesCount() < other.framesCount()) {
      return 1;
    } else {
      return 0;
    }
    // TODO: implement compareTo
    throw UnimplementedError();
  }
  
  @override
  String toString() {
    return showTimecode();
  }


}








class ScriptNode implements Comparable<ScriptNode>{

  late Timecode timecode;
  late String charName;
  late String dial;
  late Widget widget;

  ScriptNode(Timecode timecodeIn, String characterName, String dialogue){
    timecode = timecodeIn;
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
    if (timecode.framesCount()<other.timecode.framesCount()){
      return -1;
    } else {
      return 1;
    }
    // TODO: implement compareTo
    throw UnimplementedError();
  }
  


}








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


