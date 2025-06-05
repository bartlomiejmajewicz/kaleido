import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/timecode.dart';

class ScriptList {
  final List<ScriptNode> _list;

  ScriptList(this._list);

  bool markCurrentLine(Timecode currentPlaybackPosition, Timecode videoStartTc, double videoFramerate){
    // return true if something has changed
    bool isThereAChange = false;
    for (var i = 0; i < _list.length; i++) {
      if ((currentPlaybackPosition+videoStartTc).framesCount() < _list[i].tcIn.framesCount() && !isThereAChange && i>0) {
        _list[i-1].isThisCurrentTC = true;
        isThereAChange = true;
      } else {
        _list[i].isThisCurrentTC = false;
      }
    }
    return isThereAChange;
  }

  List<String> getCharactersList([bool sortedAlfabetically = true]){
    List<String> characterNames = List<String>.empty(growable: true);

    for (ScriptNode scriptNode in _list) {
      if (!characterNames.contains(scriptNode.charName)) {
        characterNames.add(scriptNode.charName);
      }
    }

    if (sortedAlfabetically) {
      characterNames.sort((a, b) {
        return a.compareTo(b);
      },);
    }


    return characterNames;
  }

/// get list of all ScriptNode or just selected character's lines
  List<ScriptNode> getList({String? characterName, String? searchLocPhrase, String? searchOrgPhrase}){

    // if (characterName == null) {
    //   return _list;
    // }

    List<ScriptNode> list = List.empty(growable: true);
    for (var element in _list) {
      if (element.charName == characterName || characterName == null) {
        if (searchLocPhrase == null || element.dialLoc.toLowerCase().contains(searchLocPhrase.toLowerCase())) {
          if (searchOrgPhrase == null || element.dialOrg.toLowerCase().contains(searchOrgPhrase.toLowerCase())) {
            list.add(element);
          }
        }
      }
    }
    return list;
  }


/// replaces all instances of character name. Returns instances affected
  int replaceCharName(String nameOld, String nameNew){

    int affected=0;
    for (ScriptNode scriptNode in _list) {
      if (scriptNode.charName == nameOld) {
        scriptNode.charName = nameNew;
        affected++;
      }
    }
    return affected;
  }

  void addNode(ScriptNode scriptNode){
    _list.add(scriptNode);
  }

/// generate ScriptList with other fps
  ScriptList conformToOtherFps(double destinationFps){
    ScriptList destinationScriptList = ScriptList(List<ScriptNode>.empty(growable: true));

    for (ScriptNode element in getList()) {
      // TODO: Timecode conform - adjust for the start TC
      ScriptNode elementConformed = ScriptNode(element.tcIn.conformToOtherFps(destinationFps), element.charName, element.dialLoc, element.dialOrg);
      destinationScriptList.addNode(elementConformed);

    }

    return destinationScriptList;
  }


  int newEntry(Timecode? tcIn, {String? charName = "char name", String? dial = 'dialogue', Timecode? videoStartTc, bool sortAfterAdding = true}) {
    charName ??= "";
    dial ??= "";
    tcIn ??= Timecode();
    videoStartTc ??= Timecode("00:00:00:00");
    ScriptNode scriptNode = ScriptNode(tcIn+videoStartTc, charName, dial, "");

    _list.add(scriptNode);

    if (sortAfterAdding) {
      _list.sort();
    }

    return _list.indexOf(scriptNode);
  }

  void removeItemById(int id){
    _list.removeAt(id);
  }

  void removeItem(ScriptNode scriptNode){
    _list.remove(scriptNode);
  }

  ScriptNode getItemById(int id){
    return _list[id];
  }

  void sortItems(){
    _list.sort();
  }


}