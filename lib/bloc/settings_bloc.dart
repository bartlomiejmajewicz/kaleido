import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/timecode.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsState(null, null, List<String>.empty(growable: true), null, 0, 0, 25.0, TimecodeFormatting.formatHhMmSsFf, Timecode())) {
    // on<SettingsEvent>((event, emit) {
    // });

    on<SetValuesFromSharedPreferences>(_setInitialStateFromSharedPreferences);
    on<SetVideoPath>(_setVideoPath);
    on<SetScriptPath>(_setScriptPath);
    on<AddAudioFile>(_addAudioFile);
    on<RemoveAudioFileAtIndex>(_removeAudioFileAtIndex);
    on<SetSheetName>(_setSheetName);
    on<SetStartingCollumn>(_setStartingColumn);
    on<SetStartingRow>(_setStartingRow);
    on<SetInputFramerate>(_setInputFramerate);
    on<SetInputTcFormatting>(_setTcInputFormatting);
    on<SetStartingTc>(_setStartingTc);
    on<ClearParameters>(_clearParameters);
  }

/// values are restored from the Shared Preferences
  FutureOr<void> _setInitialStateFromSharedPreferences(event, Emitter<SettingsState> emit) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? sharedPreferencesVideoPath = sharedPreferences.getString("videoPath");
    String? sharedPreferencesSheetName = sharedPreferences.getString("sheetName");
    String? sharedPreferencesExcelPath = sharedPreferences.getString("scriptPath");
    int? sharedPreferencesRow = sharedPreferences.getInt("row");
    int? sharedPreferencesColl = sharedPreferences.getInt("coll");
    double? sharedPreferencesFramerate = sharedPreferences.getDouble("framerate");
    emit(state.copyToNewState(
      videoFilePathNew: sharedPreferencesVideoPath, 
      scriptFilePathNew: sharedPreferencesExcelPath, 
      selectedSheetNameNew: sharedPreferencesSheetName, 
      collNumberNew: sharedPreferencesColl, 
      rowNumberNew: sharedPreferencesRow,
      inputFramerateNew: sharedPreferencesFramerate
    ));
  }

  Future<void> _setVideoPath(SetVideoPath event, Emitter<SettingsState> emit) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("videoPath", event.videoFilePath);
    emit(state.copyToNewState(videoFilePathNew: event.videoFilePath));
  }

  Future<void> _setScriptPath(SetScriptPath event, Emitter<SettingsState> emit) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("scriptPath", event.scriptFilePath);
    sharedPreferences.remove("sheetName");
    emit(state.copyToNewState(scriptFilePathNew: event.scriptFilePath));
    emit(state.clearSelectedParameters(false, false, true));
  }

  Future<void> _addAudioFile(AddAudioFile event, Emitter<SettingsState> emit) async {
    emit(state.copyToNewState(newAudioFilePath: event.audioFilePath));
  }

  Future<void> _removeAudioFileAtIndex(RemoveAudioFileAtIndex event, Emitter<SettingsState> emit) async {
    emit(state.copyToNewState(removeAudioFileAtIndex: event.index));
  }

  Future<void> _setSheetName(SetSheetName event, Emitter<SettingsState> emit) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("sheetName", event.sheetName);
    emit(state.copyToNewState(selectedSheetNameNew: event.sheetName));
  }


  Future<void> _setStartingColumn(SetStartingCollumn event, Emitter<SettingsState> emit) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setInt("coll", event.colNr);
    emit(state.copyToNewState(collNumberNew: event.colNr));
  }

  Future<void> _setStartingRow(SetStartingRow event, Emitter<SettingsState> emit) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setInt("row", event.rowNr);
    emit(state.copyToNewState(rowNumberNew: event.rowNr));
  }

  Future<void> _setInputFramerate(SetInputFramerate event, Emitter<SettingsState> emit) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setDouble("framerate", event.inputFramerate);
    emit(state.copyToNewState(inputFramerateNew: event.inputFramerate));
  }

  Future<void> _setTcInputFormatting(SetInputTcFormatting event, Emitter<SettingsState> emit) async {
    emit(state.copyToNewState(timecodeFormattingNew: event.timecodeFormatting));
  }

  Future<void> _setStartingTc(SetStartingTc event, Emitter<SettingsState> emit) async {
    emit(state.copyToNewState(startingTimecodeNew: event.startingTimecode));
  }

  Future<void> _clearParameters(ClearParameters event, Emitter<SettingsState> emit) async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (event.clearVideoFilePath) {
      sharedPreferences.remove("videoPath");
    }
    if (event.clearScriptFilePath) {
      sharedPreferences.remove("scriptPath");
    }
    if (event.clearSelectedSheetName) {
      sharedPreferences.remove("sheetName");
    }
    if (event.clearStartingCol) {
      sharedPreferences.remove("coll");
    }
    if (event.clearStartingRow) {
      sharedPreferences.remove("row");
    }
    emit(state.clearSelectedParameters(event.clearVideoFilePath, event.clearScriptFilePath, event.clearSelectedSheetName, event.clearStartingRow, event.clearStartingCol, event.clearAudioFilePaths));
  }
}
