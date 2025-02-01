
import 'package:flutter/material.dart';

// TODO: replace whole class with the SettingsBloc

abstract class SettingsClass{
  static double videoWidth = 200;
  static double videoHeight = 200;

  static ValueNotifier<double> videoHeightNotifier = ValueNotifier(videoHeight);

}

