import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/timecode.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsState(null, null, List<String>.empty(growable: true), null, 0, 0, 25.0, TimecodeFormatting.formatHhMmSsFf, Timecode())) {
    // on<SettingsEvent>((event, emit) {
    // });
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
  }

  void _setVideoPath(SetVideoPath event, Emitter<SettingsState> emit){
    emit(state.copyToNewState(videoFilePathNew: event.videoFilePath));
  }

  void _setScriptPath(SetScriptPath event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(scriptFilePathNew: event.scriptFilePath));
  }

  void _addAudioFile(AddAudioFile event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(newAudioFilePath: event.audioFilePath));
  }

  void _removeAudioFileAtIndex(RemoveAudioFileAtIndex event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(removeAudioFileAtIndex: event.index));
  }

  void _setSheetName(SetSheetName event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(selectedSheetNameNew: event.sheetName));
  }


  void _setStartingColumn(SetStartingCollumn event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(collNumberNew: event.colNr));
  }

  void _setStartingRow(SetStartingRow event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(rowNumberNew: event.rowNr));
  }

  FutureOr<void> _setInputFramerate(SetInputFramerate event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(inputFramerateNew: event.inputFramerate));
  }

  FutureOr<void> _setTcInputFormatting(SetInputTcFormatting event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(timecodeFormattingNew: event.timecodeFormatting));
  }

  FutureOr<void> _setStartingTc(SetStartingTc event, Emitter<SettingsState> emit) {
    emit(state.copyToNewState(startingTimecodeNew: event.startingTimecode));
  }
}
