import 'dart:io';
import 'package:flutter/services.dart';

class KeyboardShortcutNode{
  Set<LogicalKeyboardKey>? logicalKeySet;
  bool assignedNow = false;
  late Function onClick;

  KeyboardShortcutNode(this.onClick, {this.logicalKeySet});


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
