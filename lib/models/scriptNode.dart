import 'package:flutter/material.dart';
import 'package:script_editor/models/timecode.dart';

class ScriptNode implements Comparable<ScriptNode>{

  late Timecode tcIn = Timecode();
  late String charName="";
  late String dial="";
  late Widget widget;
  ValueNotifier<bool> isThisCurrentTCValueNotifier = ValueNotifier(false);
  FocusNode focusNode = FocusNode();

  TextEditingController textControllerTc=TextEditingController();


  ScriptNode(Timecode timecodeIn, String characterName, String dialogue){
    tcIn = timecodeIn;
    charName = characterName;
    dial = dialogue;
  }

  ScriptNode.empty();

  @override
  String toString() {
    return "$tcIn - $charName - $dial";
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
