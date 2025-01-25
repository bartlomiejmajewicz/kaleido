import 'package:flutter/material.dart';
import 'package:script_editor/models/keyboard_shortcut_node.dart';

// ignore: must_be_immutable
class OutlinedButtonWithShortcut extends StatefulWidget{

  static ValueNotifier<bool>? globalReloadNotifier;

  final ValueChanged<int>updateUiMethod;
  KeyboardShortcutNode? kns;
  OutlinedButtonWithShortcut({super.key, required this.updateUiMethod, this.kns});

  @override
  State<OutlinedButtonWithShortcut> createState() => _OutlinedButtonWithShortcutState();
}

class _OutlinedButtonWithShortcutState extends State<OutlinedButtonWithShortcut> {
  @override
  void initState() {
    super.initState();
    OutlinedButtonWithShortcut.globalReloadNotifier ??= ValueNotifier(false);
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
    return ValueListenableBuilder(valueListenable: OutlinedButtonWithShortcut.globalReloadNotifier!, builder: (context, value, child){
      return Tooltip(
        key: GlobalKey(),
        message: ksn.toString(),
        child: OutlinedButton(
        onLongPress:(){
          widget.updateUiMethod(0);
          ksn.assignedNowNotifier = true;
          OutlinedButtonWithShortcut.globalReloadNotifier!.value = true;
          widget.updateUiMethod(0);
        },
        onPressed: (){
          if (ksn.assignedNowNotifier) {
            ksn.assignedNowNotifier = false;
            widget.updateUiMethod(0);
          } else {
            ksn.onClick();
          }
        },
        child: ksn.assignedNowNotifier ? const Text("assign the shortcut") : label,
        ),
      );
    });
  }
}
