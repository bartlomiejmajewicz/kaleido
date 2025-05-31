
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:script_editor/bloc/settings_bloc.dart';
import 'package:script_editor/models/authorisation.dart';
import 'package:script_editor/models/script_list.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:super_clipboard/super_clipboard.dart';

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
        body: BlocBuilder<ValidationCubit, ValidationState>(
          builder: (context, state) {
            return ListView(
            children: [
              _statisticsTableWidget(scriptList),
              OutlinedButton(
                onPressed: (){
                  _copyStatisticsToClipboard(scriptList);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Copy to clipboard "),
                    Icon(Icons.copy)]),),
              errorsTable(scriptList, context),
              OutlinedButton(onPressed: (){
                _saveFileWithSnackbar(context, scriptList);
                context.read<ValidationCubit>().setNewState();
              }, child: const Text("Save changes to the file")),
              OutlinedButton(
                onPressed: (){
                  _copyStatisticsErrorsToClipboard(errorsTable(scriptList, context));
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Copy to clipboard "),
                    Icon(Icons.copy)]),),
              const SizedBox(height: 50,),
            ],
          );
          },
        ),
    ));
  }

  Future<void> _copyStatisticsToClipboard(ScriptList scriptList) async {
    String htmlData = "";
    SystemClipboard? clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return;
    }
    List<_StatisticsTableNode> list = _statisticsTableList(scriptList);
    htmlData = '''<table border="1">''';
    htmlData = "$htmlData<tr><th>Character Name</th><th>Entries Count</th><th>Words Count</th></tr>";
    for (_StatisticsTableNode element in list) {
      htmlData = "$htmlData <tr>";
      htmlData = "$htmlData<td>${element.charName}</td>";
      htmlData = "$htmlData<td>${element.entriesCount}</td>";
      htmlData = "$htmlData<td>${element.wordsCount}</td>";
      htmlData = "$htmlData </tr>";
    }
    htmlData = "$htmlData </table>";
  
    DataWriterItem item = DataWriterItem();
    item.add(Formats.htmlText(htmlData));
    await clipboard.write([item]);
    }

  Future<void> _copyStatisticsErrorsToClipboard(DataTable dataTable) async {
    String htmlData = "";
    SystemClipboard? clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return;
    }
    List<DataRow> dataRows = dataTable.rows;
    htmlData = '''<table border="1">''';
    htmlData = "$htmlData<tr><th>Character Name(s)</th><th>Issue</th></tr>";
    for (DataRow dataRow in dataRows) {

      SelectableText a = dataRow.cells[0].child as SelectableText;
      SelectableText b = dataRow.cells[1].child as SelectableText;
      htmlData = "$htmlData <tr>";
      htmlData = "$htmlData<td>${a.data}</td>";
      htmlData = "$htmlData<td>${b.data}</td>";
      htmlData = "$htmlData </tr>";
    }
    htmlData = "$htmlData </table>";
  
    DataWriterItem item = DataWriterItem();
    item.add(Formats.htmlText(htmlData));
    await clipboard.write([item]);
    }

  Widget _statisticsTableWidget(ScriptList scriptList){
    List<DataRow> list = List.empty(growable: true);
    List<_StatisticsTableNode> listOfSTN = _statisticsTableList(scriptList);

    for (_StatisticsTableNode element in listOfSTN) {
      list.add(DataRow(
        cells: [
          DataCell(SelectableText(element.charName)),
          DataCell(SelectableText(element.entriesCount.toString())),
          DataCell(SelectableText(element.wordsCount.toString())),
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

  List<_StatisticsTableNode> _statisticsTableList(ScriptList scriptList){
    List<_StatisticsTableNode> list = List.empty(growable: true);

    for (String charName in scriptList.getCharactersList()) {
      int wordsCount = 0;
      for (ScriptNode element in scriptList.getList(characterName: charName)) {
        wordsCount = wordsCount + element.dialLoc.trim().split(' ').length;
      }
      _StatisticsTableNode stn = _StatisticsTableNode(charName, scriptList.getList(characterName: charName).length, wordsCount);

      list.add(stn);
    }

    return list;
  }


  DataTable errorsTable(ScriptList scriptList, BuildContext context){

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
                    context.read<ValidationCubit>().setNewState();
                  },
                    child: Text("Change all to $charName1")),
                  OutlinedButton(onPressed: () {
                    scriptList.replaceCharName(charName1, charName2);
                    context.read<ValidationCubit>().setNewState();
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
}

class ValidationCubit extends Cubit<ValidationState> {
  ValidationCubit() : super(ValidationInitialState()){
  }
  void setNewState(){
    emit(ValidationState());
  }
}

class ValidationState{
}

class ValidationInitialState extends ValidationState {
  ValidationInitialState(){
  }

}

class _StatisticsTableNode{
  String charName;
  int wordsCount;
  int entriesCount;
  _StatisticsTableNode(this.charName, this.entriesCount, this.wordsCount);
}
