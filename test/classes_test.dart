import 'package:flutter_test/flutter_test.dart';
import 'package:script_editor/models/classes.dart';
import 'package:script_editor/models/timecode.dart';

void main(){
  group('Timecode', (){
    test('timecode to duration equivalent test', (){
      Timecode tc = Timecode("10:00:15:12");
      Duration dur = Timecode("10:00:15:12").tcAsDuration();
      expect(tc.tcAsDuration(), dur);
    });
    
  });
  group('description', (){
    test('123', (){
      expect('actual', 'actual');
    });
  });
}