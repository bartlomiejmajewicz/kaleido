part of 'settings_bloc.dart';

@immutable
class SettingsState {
  final String? videoFilePath;
  final String? scriptFilePath;
  List<String> audioFilesPaths = List.empty(growable: true);
  final String? selectedSheetName;
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
}

// final class SettingsInitial extends SettingsState {}
