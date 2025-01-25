import 'package:flutter/material.dart';
import 'package:script_editor/models/keyboard_shortcut_node.dart';
import 'package:script_editor/models/utils.dart';

// ignore: must_be_immutable
class OutlinedButtonWithShortcut extends StatefulWidget{

  static List<OutlinedButtonWithShortcut>? buttonsWithShortcutsList;
  static ChangeNotifierReload? globalButtonsReloadNotifier;

  //final ValueChanged<int>updateUiMethod;
  Function? updateUi;
  KeyboardShortcutNode? kns;
  OutlinedButtonWithShortcut({super.key, this.updateUi, this.kns});

  @override
  State<OutlinedButtonWithShortcut> createState() => _OutlinedButtonWithShortcutState();
}

class _OutlinedButtonWithShortcutState extends State<OutlinedButtonWithShortcut> {
  @override
  void initState() {
    super.initState();
    OutlinedButtonWithShortcut.globalButtonsReloadNotifier ??= ChangeNotifierReload();
    OutlinedButtonWithShortcut.buttonsWithShortcutsList ??= List.empty(growable: true);

    OutlinedButtonWithShortcut.buttonsWithShortcutsList!.add(widget);
  }

  @override
  void dispose() {
    OutlinedButtonWithShortcut.buttonsWithShortcutsList!.remove(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kns != null) {
      return generateButtonWithShortcut(widget.kns!, context);
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

    return ListenableBuilder(
      key: UniqueKey(),
      listenable: OutlinedButtonWithShortcut.globalButtonsReloadNotifier!,
      builder: (context, child) {
        return Tooltip(
          key: UniqueKey(),
          message: ksn.toString(),
          child: OutlinedButton(
            key: UniqueKey(),
          onLongPress:(){
            ksn.assignedNow = true;
            OutlinedButtonWithShortcut.globalButtonsReloadNotifier!.reload();
          },
          onPressed: (){
            if (ksn.assignedNow) {
              ksn.assignedNow = false;
              OutlinedButtonWithShortcut.globalButtonsReloadNotifier!.reload();
            } else {
              ksn.onClick();
            }
          },
          child: ksn.assignedNow ? const Text("assign the shortcut") : label,
          ),
        );
      }
    );
  }
}
