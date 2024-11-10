import 'package:flutter_test/flutter_test.dart';
import 'package:script_editor/classes.dart';

void main(){
  group('description', (){
    test('duration equivalent test', (){
      Timecode tc = Timecode("10:00:15:12");
      Duration dur = Timecode("10:00:15:12").tcAsDuration();
      expect(tc.tcAsDuration(), dur);
    });
    
  });
}