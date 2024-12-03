import 'package:flutter/material.dart';
import 'package:script_editor/models/keyboard_shortcut_node.dart';

// ignore: must_be_immutable
class OutlinedButtonWithShortcut extends StatelessWidget{
  final ValueChanged<int>updateUiMethod;
  KeyboardShortcutNode? kns;
  OutlinedButtonWithShortcut({super.key, required this.updateUiMethod, this.kns});

  @override
  Widget build(BuildContext context) {
    if (kns != null) {
      return generateButtonWithShortcut(kns!, context);
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
    return ValueListenableBuilder(valueListenable: ksn.assignedNowNotifier, builder: (context, value, child){
      return Tooltip(
        key: GlobalKey(),
        message: ksn.toString(),
        child: OutlinedButton(
        onLongPress:(){
          updateUiMethod(0);
          ksn.assignedNowNotifier.value = true;
          updateUiMethod(0);
        },
        onPressed: (){
          if (ksn.assignedNowNotifier.value) {
            ksn.assignedNowNotifier.value = false;
            updateUiMethod(0);
          } else {
            ksn.onClick();
          }
        },
        child: ksn.assignedNowNotifier.value ? const Text("assign the shortcut") : label,
        ),
      );
    });
  }

}
