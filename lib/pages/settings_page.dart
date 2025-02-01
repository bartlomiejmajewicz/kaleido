import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:script_editor/bloc/settings_bloc.dart';
import 'package:script_editor/models/authorisation.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/scriptNode.dart';
import 'package:script_editor/models/timecode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:path/path.dart' as path_package;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ExcelFile? excelFile;
  TextEditingController tecColl = TextEditingController();
  TextEditingController tecRow = TextEditingController();

  final ValueNotifier<bool> _videoFileSelectorActive = ValueNotifier(true);
  final ValueNotifier<bool> _scriptFileSelectorActive = ValueNotifier(true);
  final ValueNotifier<bool> _isFileSelectorsActive = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Authorisation.isLicenseActive()
          ? null
          : AppBar(
              title: const Text(
                "License not active. Saving disabled.",
                style: TextStyle(color: Colors.red),
              ),
            ),
      body: SizedBox(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: ListView(
            children: [
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  PaddingTableRow(children: [
                    const Text("select video file:"),
                    ValueListenableBuilder(
                      valueListenable: _isFileSelectorsActive,
                      builder: (context, value, child) {
                        return OutlinedButton(
                          onPressed: value ? () async {
                            String? response = await _selectVideoFile();
                            if (context.mounted && response != null) {
                              context
                                  .read<SettingsBloc>()
                                  .add(SetVideoPath(response));
                            }
                          } : null
                          ,
                          child: const Text("select video file..."));
                      },
                    ),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return SelectableText(
                          "selected file: ${state.videoFilePath}",
                          maxLines: 2,
                          style: const TextStyle(overflow: TextOverflow.clip),
                        );
                      },
                    ),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select additional audio files:"),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return _additionalFilesSelector(state.audioFilesPaths);
                      },
                    ),
                    Container(),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select script file:"),
                    ValueListenableBuilder(
                      valueListenable: _isFileSelectorsActive,
                      builder: (context, value, child) {
                        return OutlinedButton(
                            onPressed: value ? () async {
                              String? response = await _selectScriptFile();
                              if (response != null) {  
                              context
                                  .read<SettingsBloc>()
                                  .add(SetScriptPath(response));
                              }
                            } : null,
                            child: const Text("select script file..."));
                      },
                    ),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return SelectableText(
                          "selected file: ${state.scriptFilePath}",
                          maxLines: 2,
                          style: const TextStyle(overflow: TextOverflow.clip),
                        );
                      },
                    ),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select sheet:"),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return _sheetSelectorWidget(
                            state.listSheetsNames(), state.selectedSheetName);
                      },
                    ),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return Text(
                            'selected sheet name: ${state.selectedSheetName}');
                      },
                    )
                  ]),
                  PaddingTableRow(children: [
                    const Text("select starting column: "),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        tecColl.text = (state.collNumber + 1).toString();
                        return TextFormField(
                            controller: tecColl,
                            onChanged: (value) {
                              int newValue =
                                  (value != "") ? int.parse(value) - 1 : 0;
                              context
                                  .read<SettingsBloc>()
                                  .add(SetStartingCollumn(newValue));
                            },
                            inputFormatters: [
                              TextInputFormatter.withFunction(
                                  _columnOrRowNumberValidityCheck)
                            ]);
                      },
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            OutlinedButton(
                                onPressed: () {
                                  final int currentCollNr = context
                                      .read<SettingsBloc>()
                                      .state
                                      .collNumber;
                                  if (currentCollNr >= 0) {
                                    context.read<SettingsBloc>().add(
                                        SetStartingCollumn(currentCollNr + 1));
                                  }
                                },
                                child: const Icon(Icons.plus_one)),
                            OutlinedButton(
                                onPressed: () {
                                  final int currentCollNr = context
                                      .read<SettingsBloc>()
                                      .state
                                      .collNumber;
                                  if (currentCollNr >= 1) {
                                    context.read<SettingsBloc>().add(
                                        SetStartingCollumn(currentCollNr - 1));
                                  }
                                },
                                child: const Icon(Icons.exposure_minus_1)),
                          ],
                        ),
                        Flexible(
                            child: BlocBuilder<SettingsBloc, SettingsState>(
                          builder: (context, state) {
                            return Text(
                                'selected collumn: ${state.collNumber + 1}');
                          },
                        )),
                      ],
                    ),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select starting row: "),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        tecRow.text = (state.rowNumber + 1).toString();
                        return TextFormField(
                            controller: tecRow,
                            onChanged: (value) {
                              int newValue =
                                  (value != "") ? int.parse(value) - 1 : 0;
                              context
                                  .read<SettingsBloc>()
                                  .add(SetStartingRow(newValue));
                            },
                            inputFormatters: [
                              TextInputFormatter.withFunction(
                                  _columnOrRowNumberValidityCheck)
                            ]);
                      },
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            OutlinedButton(
                                onPressed: () {
                                  final int currentRowNr = context
                                      .read<SettingsBloc>()
                                      .state
                                      .rowNumber;
                                  if (currentRowNr >= 0) {
                                    context
                                        .read<SettingsBloc>()
                                        .add(SetStartingRow(currentRowNr + 1));
                                  }
                                },
                                child: const Icon(Icons.plus_one)),
                            OutlinedButton(
                                onPressed: () {
                                  final int currentRowNr = context
                                      .read<SettingsBloc>()
                                      .state
                                      .rowNumber;
                                  if (currentRowNr >= 1) {
                                    context
                                        .read<SettingsBloc>()
                                        .add(SetStartingRow(currentRowNr - 1));
                                  }
                                },
                                child: const Icon(Icons.exposure_minus_1)),
                          ],
                        ),
                        Flexible(
                            child: BlocBuilder<SettingsBloc, SettingsState>(
                          builder: (context, state) {
                            return Text('selected row: ${state.rowNumber + 1}');
                          },
                        )),
                      ],
                    ),
                  ]),
                  //
                  //
                  //
                  PaddingTableRow(children: [
                    const Text("select project framerate: "),
                    _fpsSelectorWidget(),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return Text('selected fps: ${state.inputFramerate}');
                      },
                    ),
                  ]),
                  PaddingTableRow(children: [
                    const Text("select timecode output formatting: "),
                    _formattingSelector(),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return Text(
                            'selected format: ${_formattingOutput(state.timecodeFormatting)}');
                      },
                    ),
                  ]),
                  PaddingTableRow(children: [
                    const Text("starting TC: "),
                    SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: context
                              .read<SettingsBloc>()
                              .state
                              .startingTimecode
                              .toString(),
                          onChanged: (value) {
                            //FIXME:
                            if (Timecode.tcValidateCheck(
                                value,
                                context
                                    .read<SettingsBloc>()
                                    .state
                                    .inputFramerate)) {
                              context.read<SettingsBloc>().add(
                                  SetStartingTc(Timecode(value.toString())));
                            }
                          },
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                                _tcValidityInputCheck)
                          ],
                          //style: TextStyle(backgroundColor: Colors.green),
                          //style: TextStyle().apply(backgroundColor: Colors.amber),
                        )),
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return Text(state.startingTimecode.toString());
                      },
                    )
                  ]),
                ],
              ),
              BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  return _sheetPreviewWidget(state.scriptFilePath, state.selectedSheetName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _additionalFilesSelector(List<String> audioFilesPaths) {
    List<TableRow> list = List.empty(growable: true);

    for (var i = 0; i < audioFilesPaths.length; i++) {
      list.add(TableRow(children: [
        SelectableText(
          path_package.basename(audioFilesPaths[i]),
          maxLines: 1,
          style: const TextStyle(overflow: TextOverflow.clip),
        ),
        OutlinedButton(
          onPressed: () {
            context.read<SettingsBloc>().add(RemoveAudioFileAtIndex(i));
          },
          child: const Icon(Icons.delete))
      ]));
    }

    list.add(TableRow(children: [
      ValueListenableBuilder(
        valueListenable: _isFileSelectorsActive,
        builder: (context, value, child) {
          return OutlinedButton(
            onPressed: value ? () async {
              String? audioFilePath = await _selectAudioFile();
              if (audioFilePath != null) {
                context.read<SettingsBloc>().add(AddAudioFile(audioFilePath));
              }
            } : null,
            child: const Icon(Icons.add_box_outlined),
          );
        },
      ),
      ValueListenableBuilder(
        valueListenable: _isFileSelectorsActive,
        builder: (context, value, child) {
          return OutlinedButton(
            onPressed: value ? () async {
              List<String> audioFilesPaths = await _selectAudioFiles();
              for (String element in audioFilesPaths) {
                context.read<SettingsBloc>().add(AddAudioFile(element));
              }
            } : null,
            child: const Icon(Icons.library_add_outlined),
          );
        },
      ),
    ]));
    return Table(children: list);
  }

  Future<void> _saveSharedPreference(String key, String value) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(key, value);
  }

  Future<String?> _selectVideoFile() async {
    _isFileSelectorsActive.value = false;
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      _saveSharedPreference('videoPath', result.files.single.path!);
      _isFileSelectorsActive.value = true;
      return result.files.single.path!;
    } else {
    }
    _isFileSelectorsActive.value = true;
  }

  Future<String?> _selectAudioFile() async {
    _isFileSelectorsActive.value = false;
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      _isFileSelectorsActive.value = true;
      return result.files.single.path;
    } else {
      // User canceled the picker
      _showPickerDialogCancelled(
          'You have to select an audio file to continue');
    }
    _isFileSelectorsActive.value = true;
  }

  Future<List<String>> _selectAudioFiles() async {
    _isFileSelectorsActive.value = false;
    List<String> filesPaths = List.empty(growable: true);
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.audio, allowMultiple: true);
    if (result != null) {
      for (String? element in result.paths) {
        if (element != null) {
          filesPaths.add(element);
        }
      }
    } else {
      // User canceled the picker
      _showPickerDialogCancelled(
          'You have to select an audio file to continue');
    }
    _isFileSelectorsActive.value = true;
    return filesPaths;
  }

  Future<String?> _selectScriptFile() async {
    _isFileSelectorsActive.value = false;
    // select the excel file, list the sheets and save the excel file to the var
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['xls', 'xlsx']);
    if (result != null) {
      try {
        _saveSharedPreference('scriptPath', result.files.single.path!);
        _isFileSelectorsActive.value = true;
        return result.files.single.path;
      } catch (e) {
        _showPickerDialogCancelled("error while opening the file: $e");
      }
    } else {
      // User canceled the picker
      _showPickerDialogCancelled(
          'You have to select a script file to continue');
    }
    _isFileSelectorsActive.value = true;
  }

  TextEditingValue _columnOrRowNumberValidityCheck(
      TextEditingValue oldValue, TextEditingValue newValue) {
    RegExp numberPattern = RegExp(r'^\d{0,2}$');
    if (numberPattern.hasMatch(newValue.text) && newValue.text != "0") {
      return newValue;
    } else {
      return oldValue;
    }
  }

  DropdownMenu<String> _sheetSelectorWidget(
      List<String>? listSheetsNames, String? selectedSheetName) {
    return DropdownMenu<String>(
      enabled: listSheetsNames != null,
      width: 200,
      label: const Text("select excel sheet"),
      initialSelection: selectedSheetName,
      onSelected: (value) {
        try {
          context.read<SettingsBloc>().add(SetSheetName(value!));
        } catch (e) {
          _showPickerDialogCancelled(
              "You have to select an existing sheet name to continue");
        }
      },
      dropdownMenuEntries: _getSheetsDropdownMenuEntries(),
    );
  }

  Widget _fpsSelectorWidget() {
    final double currentFps = context.read<SettingsBloc>().state.inputFramerate;
    return IntrinsicWidth(
      child: DropdownMenu(
        width: 200,
        label: const Text("set video framerate"),
        onSelected: (value) {
            if (value != null) {
              context.read<SettingsBloc>().add(SetInputFramerate(value));
            }
        },
        initialSelection: currentFps,
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

  Widget _formattingSelector() {
    TimecodeFormatting cirrentTimecodeFormatting =
        context.read<SettingsBloc>().state.timecodeFormatting;
    return IntrinsicWidth(
      child: DropdownMenu(
        width: 200,
        label: const Text("set output formatting"),
        onSelected: (value) {
          context.read<SettingsBloc>().add(SetInputTcFormatting(value));
        },
        initialSelection: cirrentTimecodeFormatting,
        dropdownMenuEntries: const <DropdownMenuEntry>[
          DropdownMenuEntry(
              value: TimecodeFormatting.formatHhMmSsFf, label: "HH:MM:SS:FF"),
          DropdownMenuEntry(
              value: TimecodeFormatting.formatMmSs, label: "MM:SS"),
        ],
      ),
    );
  }

  String _formattingOutput(TimecodeFormatting tcFormat) {
    switch (tcFormat) {
      case TimecodeFormatting.formatHhMmSsFf:
        return "HH:MM:SS:FF";
      case TimecodeFormatting.formatMmSs:
        return "MM:SS";
      default:
        return "HH:MM:SS:FF";
    }
  }

  List<DropdownMenuEntry<String>> _getSheetsDropdownMenuEntries() {
    var list = context.read<SettingsBloc>().state.listSheetsNames();
    if (list == null) {
      return [];
    }
    return list.map((String item) {
      return DropdownMenuEntry<String>(
        value: item,
        label: item,
      );
    }).toList();
  }

  Future<void> _showPickerDialogCancelled(String description) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selector canceled'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(description),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  TextEditingValue _tcValidityInputCheck(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String returnedValue = "";
    //var tcPattern = RegExp(buildTimecodePattern(Timecode.framerate));
    var tcInProgressPattern = RegExp(r'^\d{0,2}:?\d{0,2}:?\d{0,2}:?\d{0,2}$');
    if (tcInProgressPattern.hasMatch(newValue.text)) {
      returnedValue = newValue.text;

      if ((returnedValue.length == 2 ||
              returnedValue.length == 5 ||
              returnedValue.length == 8) &&
          oldValue.text.length < newValue.text.length) {
        returnedValue += ":";
      }
    } else {
      returnedValue = oldValue.text;
    }
    return TextEditingValue(text: returnedValue);
  }

  DataTable _sheetPreviewWidget(String? scriptFilePath, String? scriptSheetName) {
    List<ScriptNode> list = List.empty(growable: true);
    List<DataRow> datarows = List.empty(growable: true);
    if (scriptFilePath != "" && scriptSheetName != "") {
      try {
        ExcelFile excelFile = ExcelFile(scriptFilePath!);
        excelFile.loadFile();
        excelFile.importSheetToList(scriptSheetName!, list, context.read<SettingsBloc>().state.collNumber, context.read<SettingsBloc>().state.rowNumber, context.read<SettingsBloc>().state.inputFramerate);
        for (var i = 0; i < 3 && i < list.length; i++) {
          datarows.add(DataRow(cells: [
            DataCell(Text(list[i].tcIn.toString())),
            DataCell(Text(list[i].charName)),
            DataCell(Text(list[i].dial)),
          ]));
        }
        // ignore: empty_catches
      } catch (e) {}
    }

    datarows.add(const DataRow(cells: [
      DataCell(Text("...")),
      DataCell(Text("...")),
      DataCell(Text("...")),
    ]));

    return DataTable(
      columns: const [
        DataColumn(
          label: Text("TC in"),
        ),
        DataColumn(label: Text("Character")),
        DataColumn(
          label: Text("Dialogue"),
        ),
      ],
      rows: datarows,
    );
  }
}

class PaddingTableRow extends TableRow {
  PaddingTableRow({List<Widget> children = const <Widget>[]})
      : super(
            children: children
                .map((child) =>
                    Padding(padding: const EdgeInsets.all(10.0), child: child))
                .toList());
}
