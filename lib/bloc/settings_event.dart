part of 'settings_bloc.dart';

@immutable
sealed class SettingsEvent {
}

class SetValuesFromSharedPreferences extends SettingsEvent{}
class SetVideoPath extends SettingsEvent{
  final String videoFilePath;
  SetVideoPath(this.videoFilePath);
}

class SetScriptPath extends SettingsEvent{
  final String scriptFilePath;
  SetScriptPath(this.scriptFilePath);
}

class AddAudioFile extends SettingsEvent{
  final String audioFilePath;
  AddAudioFile(this.audioFilePath);
}

class RemoveAudioFileAtIndex extends SettingsEvent{
  final int index;
  RemoveAudioFileAtIndex(this.index);
}

class SetSheetName extends SettingsEvent{
  final String sheetName;
  SetSheetName(this.sheetName);
}

class SetStartingCollumn extends SettingsEvent{
  final int colNr;
  SetStartingCollumn(this.colNr);
}

class SetStartingRow extends SettingsEvent{
  final int rowNr;
  SetStartingRow(this.rowNr);
}

class SetInputFramerate extends SettingsEvent{
  final double inputFramerate;
  SetInputFramerate(this.inputFramerate);
}

class SetInputTcFormatting extends SettingsEvent{
  final TimecodeFormatting timecodeFormatting;
  SetInputTcFormatting(this.timecodeFormatting);
}

class SetStartingTc extends SettingsEvent{
  final Timecode startingTimecode;
  SetStartingTc(this.startingTimecode);
}

class ClearParameters extends SettingsEvent{
  final bool clearVideoFilePath;
  final bool clearScriptFilePath;
  final bool clearSelectedSheetName;
  final bool clearStartingRow;
  final bool clearStartingCol;
  final bool clearAudioFilePaths;
  ClearParameters(this.clearVideoFilePath, this.clearScriptFilePath, this.clearSelectedSheetName, this.clearStartingRow, this.clearStartingCol, this.clearAudioFilePaths);
}