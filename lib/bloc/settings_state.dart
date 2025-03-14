part of 'settings_bloc.dart';

@immutable
class SettingsState {
  String? videoFilePath;
  String? scriptFilePath;
  List<String> audioFilesPaths = List.empty(growable: true);
  String? selectedSheetName;
  int rowNumber = 0;
  int collNumber = 0;
  double inputFramerate = 25;
  TimecodeFormatting timecodeFormatting = TimecodeFormatting.formatHhMmSsFf;
  final Timecode startingTimecode;

  SettingsState(this.videoFilePath, this.scriptFilePath, this.audioFilesPaths, this.selectedSheetName, this.rowNumber, this.collNumber, this.inputFramerate, this.timecodeFormatting, this.startingTimecode);

  SettingsState copyToNewState({
    String? videoFilePathNew,
    String? scriptFilePathNew,
    String? newAudioFilePath,
    int? removeAudioFileAtIndex,
    String? selectedSheetNameNew,
    int? rowNumberNew,
    int? collNumberNew,
    double? inputFramerateNew,
    TimecodeFormatting? timecodeFormattingNew,
    Timecode? startingTimecodeNew,
    }) {
    if (newAudioFilePath != null) {
      audioFilesPaths.add(newAudioFilePath);
    }
    if (removeAudioFileAtIndex != null) {
      audioFilesPaths.removeAt(removeAudioFileAtIndex);
    }
    return SettingsState(
      videoFilePathNew ?? videoFilePath,
      scriptFilePathNew ?? scriptFilePath,
      audioFilesPaths,
      selectedSheetNameNew ?? selectedSheetName,
      rowNumberNew ?? rowNumber,
      collNumberNew ?? collNumber,
      inputFramerateNew ?? inputFramerate,
      timecodeFormattingNew ?? timecodeFormatting,
      startingTimecodeNew ?? startingTimecode
    );
  }

  List<String>? listSheetsNames(){
    try {
      ExcelFile excelFile = ExcelFile(scriptFilePath!);
      excelFile.loadFile();
      return excelFile.sheetsList;
    } catch (e) {
      return null;
    }
  }

  bool isDataComplete(){
    if (videoFilePath == null
    || scriptFilePath == null
    || selectedSheetName == null) {
      return false;
    }
    if (videoFilePath!.isEmpty
    || scriptFilePath!.isEmpty
    || selectedSheetName!.isEmpty) {
      return false;
    }
    return true;
  }

  SettingsState clearSelectedParameters(
    [
      bool clearVideoFilePath = false,
      bool clearScriptFilePath = false,
      bool clearSelectedSheetName = false,
      bool clearStartingRow = false,
      bool clearStartingCol = false,
      bool clearAudioFilePaths = false,
      ]
    ){
      if (clearVideoFilePath) {
        videoFilePath = null;
      }
      if (clearScriptFilePath) {
        scriptFilePath = null;
      }
      if (clearSelectedSheetName) {
        selectedSheetName = null;
      }
      if (clearStartingRow) {
        rowNumber = 0;
      }
      if (clearStartingCol) {
        collNumber = 0;
      }
      if (clearAudioFilePaths) {
        audioFilesPaths.clear();
      }

      return copyToNewState();
    }
}

// final class SettingsInitial extends SettingsState {}
