import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:script_editor/bloc/settings_bloc.dart';
import 'package:script_editor/main.dart';
import 'package:script_editor/models/authorisation.dart';
import 'package:script_editor/models/utils.dart';
import 'package:script_editor/models/script_list.dart';
import 'package:script_editor/widgets/char_name_widget_with_autocomplete.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/keyboard_shortcut_node.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/settings_class.dart';
import 'package:script_editor/models/timecode.dart';
import 'package:script_editor/widgets/outlined_button_with_shortcut.dart';
import 'package:script_editor/widgets/resizable_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:path/path.dart' as path_package;

class ValidationPage extends StatelessWidget {
  const ValidationPage({super.key, required this.title});

  final String title;


  @override
  Widget build(BuildContext context) {
    var scriptSourceFile = ExcelFile(context.read<SettingsBloc>().state.scriptFilePath!);
    scriptSourceFile!.loadFile();
    ScriptList scriptList;
    List<ScriptNode>? scriptNodesTemporary = scriptSourceFile!.importSheetToList(context.read<SettingsBloc>().state.selectedSheetName!, context.read<SettingsBloc>().state.collNumber, context.read<SettingsBloc>().state.rowNumber, context.read<SettingsBloc>().state.inputFramerate);
    scriptList = ScriptList(scriptNodesTemporary!);
    return BlocProvider(
      lazy: false,
      create: (context) => ValidationCubit(),
      child: Scaffold(
        appBar: Authorisation.isLicenseActive() ? null : AppBar(
          centerTitle: true,
          title: const Text(
            "License not active. Saving disabled.",
            style: TextStyle(color: Colors.red),),
        ),
        // body: SingleChildScrollView(
        //   child: statisticsTable(scriptList))
        body: ListView(
          children: [
            statisticsTable(scriptList),
            errorsTable(scriptList)
          ],
        ),
    ));
  }

  Widget statisticsTable(ScriptList scriptList){
    List<DataRow> list = List.empty(growable: true);

    for (String charName in scriptList.getCharactersList()) {
      int wordsCount = 0;
      for (ScriptNode element in scriptList.getList(characterName: charName)) {
        wordsCount = wordsCount + element.dialLoc.trim().split(' ').length;
      }

      list.add(DataRow(
        cells: [
          DataCell(SelectableText(charName)),
          DataCell(SelectableText(scriptList.getList(characterName: charName).length.toString())),
          DataCell(SelectableText(wordsCount.toString())),
        ]
      ));
    }

    return DataTable(
      columns: const [
        DataColumn(label: Text("Char name:")),
        DataColumn(label: Text("Entries count:")),
        DataColumn(label: Text("Words count:")),
      ],
      rows: list);
  }


  Widget errorsTable(ScriptList scriptList){

    List<DataRow> list = List.empty(growable: true);

    

    for (String charName1 in scriptList.getCharactersList()) {
      for (String charName2 in scriptList.getCharactersList()) {
        // the names are the same == break
        if (charName1 == charName2) {
          break;
        }

        // one name contains the other
        if (charName1.toLowerCase().contains(charName2.toLowerCase())) {
          list.add(DataRow(
            cells: [
              DataCell(SelectableText("$charName1, $charName2")),
              const DataCell(SelectableText("character names seems to be very similar. Please check.")),
              DataCell(Row(
                children: [
                  OutlinedButton(onPressed: () {
                    scriptList.replaceCharName(charName2, charName1);
                    //TODO: SAVE AFTER THAT / move scriptList to the global BLOC to use it in all pages
                  },
                    child: Text("Change all to $charName1")),
                  OutlinedButton(onPressed: () {
                    scriptList.replaceCharName(charName1, charName2);
                  },
                    child: Text("Change all to $charName2"))
                ],
              ))
            ]
          ));
        }


      }
    }

    return DataTable(
      columns: const [
        DataColumn(label: Text("Char name(s):")),
        DataColumn(label: Text("Issue:")),
        DataColumn(label: Text("Action:")),
      ],
      rows: list);
  }
}

class ValidationCubit extends Cubit<ValidationState> {
  ValidationCubit() : super(ValidationInitialState()){
  }
}

class ValidationState{

}

class ValidationInitialState extends ValidationState {
  ValidationInitialState(){
  }

}
