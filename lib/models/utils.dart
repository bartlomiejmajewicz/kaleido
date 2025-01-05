import 'package:flutter/foundation.dart';

class ChangeNotifierReload extends ChangeNotifier{
  void reload(){
    notifyListeners();
  }
}
