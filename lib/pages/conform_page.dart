
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:script_editor/bloc/settings_bloc.dart';
import 'package:script_editor/models/authorisation.dart';
import 'package:script_editor/models/script_list.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/timecode.dart';
import 'package:super_clipboard/super_clipboard.dart';

class ConformPage extends StatelessWidget {
  ConformPage({super.key, required this.title});

  final String title;
  String _sheetNameForConform="conformed";
  final ValueNotifier<double> _conformedFps = ValueNotifier<double>(25.0);


  @override
  Widget build(BuildContext context) {
    _sheetNameForConform = context.read<SettingsBloc>().state.selectedSheetName!;
    var scriptSourceFile = ExcelFile(context.read<SettingsBloc>().state.scriptFilePath!);
    scriptSourceFile!.loadFile();
    ScriptList scriptList;
    List<ScriptNode>? scriptNodesTemporary = scriptSourceFile!.importSheetToList(context.read<SettingsBloc>().state.selectedSheetName!, context.read<SettingsBloc>().state.collNumber, context.read<SettingsBloc>().state.rowNumber, context.read<SettingsBloc>().state.inputFramerate);
    scriptList = ScriptList(scriptNodesTemporary!);
    return Scaffold(
      appBar: Authorisation.isLicenseActive() ? null : AppBar(
        centerTitle: true,
        title: const Text(
          "License not active. Saving disabled.",
          style: TextStyle(color: Colors.red),),
      ),
      body: ListView(
          children: [
            Text("Source framerate: ${context.read<SettingsBloc>().state.inputFramerate}"),
            const Text("Destination framerate:"),
            _fpsSelectorWidget(),
            
            const Text("Select sheet name:"),
            
            ValueListenableBuilder(
              valueListenable: _conformedFps,
              builder: (context, value, child) {
                return TextFormField(
                  key: UniqueKey(),
                  initialValue: "${_sheetNameForConform}_${_conformedFps.value}",
                  onChanged: (value) {
                    _sheetNameForConform = value;
                  },
                );
              },),
            OutlinedButton(
              onPressed: null, // TODO: code this
              child: const Text("Conform!"))
          ],
        ));
  }


Widget _fpsSelectorWidget() {
    return IntrinsicWidth(
      child: DropdownMenu(
        width: 200,
        label: const Text("set destination framerate"),
        onSelected: (value) {
          if (value != null) {
            _conformedFps.value = value;
          }
        },
        initialSelection: _conformedFps.value,
        dropdownMenuEntries: const <DropdownMenuEntry<double>>[
          DropdownMenuEntry(value: 23.976, label: "23.98 fps"),
          DropdownMenuEntry(value: 24.0, label: "24 fps"),
          DropdownMenuEntry(value: 25.0, label: "25 fps"),
          DropdownMenuEntry(value: 29.97, label: "29,97 fps NDF"),
          DropdownMenuEntry(value: 30.0, label: "30 fps / 29,97 fps DF"),
        ],
      ),
    );
  }


  int _saveFile(BuildContext context, ScriptList scriptList){
    if (!Authorisation.isLicenseActive()) {
      return 100;
    }
    try {
      var scriptSourceFile = ExcelFile(context.read<SettingsBloc>().state.scriptFilePath!);
      scriptSourceFile!.loadFile();
      scriptSourceFile!.exportListToSheet(scriptList.getList(), context.read<SettingsBloc>().state.selectedSheetName!, context.read<SettingsBloc>().state.timecodeFormatting, context.read<SettingsBloc>().state.rowNumber, context.read<SettingsBloc>().state.collNumber);
      scriptSourceFile!.saveFile();
      return 0;
    } catch (e) {
      return 100;
    }
  }

  void _saveFileWithSnackbar(BuildContext context, ScriptList scriptList){
    if (_saveFile(context, scriptList) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("file saved!"),));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("file could NOT be saved"),
            backgroundColor: Colors.red,));
    }
  }

  void _performConform(double sourceFps, double destinationFps, String sheetName, ScriptList sourceScriptList){
    ScriptList destinationScriptList = ScriptList(List<ScriptNode>.empty(growable: true));

    for (ScriptNode element in sourceScriptList.getList()) {
      // TODO: Timecode conform
      Timecode tcNew = Timecode();
      ScriptNode elementConformed = ScriptNode(tcNew, element.charName, element.dialLoc, element.dialOrg);
      destinationScriptList.addNode(elementConformed);
    }

    if (kDebugMode) {
      print(destinationScriptList);
    }
  }
}
