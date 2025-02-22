import 'package:flutter/material.dart';
import 'package:script_editor/models/timecode.dart';

class ScriptNode implements Comparable<ScriptNode>{

  Timecode tcIn = Timecode();
  String charName="";
  String dialOrg="";
  String dialLoc="";
  bool isThisCurrentTC = false;
  FocusNode dialFocusNode = FocusNode();

  TextEditingController textControllerTc=TextEditingController();


  ScriptNode(Timecode timecodeIn, String characterName, String dialLocalized, this.dialOrg){
    tcIn = timecodeIn;
    charName = characterName;
    dialLoc = dialLocalized;
  }

  ScriptNode.empty();

  @override
  String toString() {
    return "$tcIn - $charName - $dialLoc";
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
