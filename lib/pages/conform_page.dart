
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
  final ValueNotifier<double> _conformedFps = ValueNotifier<double>(25.0);
  final ValueNotifier<String> _sheetNameConformed = ValueNotifier<String>("conformed");


  @override
  Widget build(BuildContext context) {
    _sheetNameConformed.value = context.read<SettingsBloc>().state.selectedSheetName!;
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
        padding: const EdgeInsets.all(8.0),
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
                initialValue: "${_sheetNameConformed.value}_${_conformedFps.value}",
                onChanged: (value) {
                  _sheetNameConformed.value = value;
                },
              );
            },),
          ValueListenableBuilder(valueListenable: _sheetNameConformed, builder: (context, value, child) {
            if (_sheetNameConformed.value == context.read<SettingsBloc>().state.selectedSheetName) {
              return const OutlinedButton(
                onPressed: null,
                child: Text("Unable to save to the same sheetname as the original!"));
            }

            return OutlinedButton(
              onPressed: () {
                ScriptList scriptListConformed = scriptList.conformToOtherFps(_conformedFps.value);
                _saveFileWithSnackbar(context, scriptListConformed, _sheetNameConformed.value);
              },
              child: const Text("Conform!"));
            },),
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



    int _saveFileToNewSheet(BuildContext context, ScriptList scriptList, String sheetName){
    if (!Authorisation.isLicenseActive()) {
      return 100;
    }
    try {
      var scriptSourceFile = ExcelFile(context.read<SettingsBloc>().state.scriptFilePath!);
      scriptSourceFile!.loadFile();
      scriptSourceFile!.exportListToSheet(scriptList.getList(), sheetName, context.read<SettingsBloc>().state.timecodeFormatting, context.read<SettingsBloc>().state.rowNumber, context.read<SettingsBloc>().state.collNumber);
      scriptSourceFile!.saveFile();
      return 0;
    } catch (e) {
      return 100;
    }
  }

  void _saveFileWithSnackbar(BuildContext context, ScriptList scriptList, String sheetName){
    if (_saveFileToNewSheet(context, scriptList, sheetName) == 0) {
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
}
