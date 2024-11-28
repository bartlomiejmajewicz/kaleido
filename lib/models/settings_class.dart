import 'package:script_editor/models/timecode.dart';

class SettingsClass{
  static int rowNumber = 0;
  static int collNumber = 0;
  static String sheetName = "";
  static String videoFilePath = "";
  static String scriptFilePath = "";
  static double videoWidth = 200;
  static double videoHeight = 200;
  static Timecode videoStartTc=Timecode();

  static bool isDataComplete(){
    if (sheetName != ""
    && videoFilePath != ""
    && scriptFilePath != "") {
      return true;
    } else {
      return false;
    }
  }

}

