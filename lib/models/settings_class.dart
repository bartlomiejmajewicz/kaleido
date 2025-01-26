
import 'package:flutter/material.dart';
import 'package:script_editor/models/timecode.dart';

import 'classes.dart';

abstract class SettingsClass{
  static int rowNumber = 0;
  static int collNumber = 0;
  static String sheetName = "";
  static String videoFilePath = "";
  static String scriptFilePath = "";
  static double videoWidth = 200;
  static double videoHeight = 200;
  static Timecode videoStartTc=Timecode();
  static ExcelFile? scriptFile;
  static TimecodeFormatting timecodeFormatting = TimecodeFormatting.formatHhMmSsFf;
  static List<String> audioSourcesPathsList = List.empty(growable: true);
  static double inputFramerate = 25;

  static ValueNotifier<double> videoHeightNotifier = ValueNotifier(videoHeight);

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

