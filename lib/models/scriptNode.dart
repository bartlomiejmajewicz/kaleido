import 'package:flutter/material.dart';
import 'package:script_editor/models/timecode.dart';

class ScriptNode implements Comparable<ScriptNode>{

  late Timecode tcIn = Timecode();
  late String charName="";
  late String dial="";
  late Widget widget;
  bool isThisCurrentTC = false;
  FocusNode dialFocusNode = FocusNode();

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


class ScriptNodeList extends ChangeNotifier {
  late List<ScriptNode> _scriptNodeList;

  ScriptNodeList([List<ScriptNode>? scriptNodeList]){
    _scriptNodeList = scriptNodeList ?? List.empty(growable: true);
    notifyListeners();
  }

  void addElement(ScriptNode scriptNode){
    _scriptNodeList.add(scriptNode);
    notifyListeners();
  }

  void removeElement([int index=0]){
    _scriptNodeList.removeAt(index);
    notifyListeners();
  }

  void notifyListenersManually(){
    notifyListeners();
  }

  int replaceCharName(String oldCharName, String newCharName){
    int countChanges = 0;
    for (ScriptNode scriptNode in _scriptNodeList) {
      if (scriptNode.charName == oldCharName) {
        scriptNode.charName = newCharName;
        countChanges++;
      }
    }
    notifyListeners();
    return countChanges;
  }

  List<ScriptNode> get scriptNodeList{
    return _scriptNodeList;
  }


}
