import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcutNode{
  Set<LogicalKeyboardKey>? logicalKeySet;
  String? characterName;
  String description;
  ValueNotifier<bool> assignedNowNotifier = ValueNotifier(false);
  List<IconData>? iconsList;
  late Function onClick;

  KeyboardShortcutNode(this.onClick, this.description, {this.characterName, this.logicalKeySet, this.iconsList});


  String _showShortcut(){
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

  @override
  String toString() {
    return _showShortcut();
  }
}
