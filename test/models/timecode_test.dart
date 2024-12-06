import 'package:flutter_test/flutter_test.dart';
import 'package:script_editor/models/timecode.dart';

void main() {
  group('Timecode', () {
    test('Default constructor initializes to 00:00:00:00 if invalid input', () {
      Timecode tc = Timecode('value-not-valid');
      expect(tc.h, 0);
      expect(tc.m, 0);
      expect(tc.s, 0);
      expect(tc.f, 0);
    });

    test('Default constructor parses valid timecode string', () {
      Timecode tc = Timecode('12:34:56:20');
      expect(tc.h, 12);
      expect(tc.m, 34);
      expect(tc.s, 56);
      expect(tc.f, 20);
    });

    test('tcValidateCheck correctly validates valid timecode strings', () {
      expect(Timecode.tcValidateCheck('12:34:56:20'), true);
      expect(Timecode.tcValidateCheck('23:59:59:24'), true);
    });

    test('tcValidateCheck correctly invalidates invalid timecode strings', () {
      expect(Timecode.tcValidateCheck('25:00:00:00'), false);
      expect(Timecode.tcValidateCheck('12:60:00:00'), false);
      expect(Timecode.tcValidateCheck('12:34:60:00'), false);
      expect(Timecode.tcValidateCheck('12:34:56:60'), false);
      expect(Timecode.tcValidateCheck('not-a-timecode'), false);
    });

    test('showTimecode returns correctly formatted timecode string', () {
      Timecode tc = Timecode('01:02:03:04');
      expect(tc.showTimecode(), '01:02:03:04');
    });

    test('framesCount calculates total frames correctly', () {
      Timecode.framerate = 25;
      Timecode tc = Timecode.fromIntValues(1, 2, 3, 4);
      int expectedFrames = 1 * 60 * 60 * 25 + 2 * 60 * 25 + 3 * 25 + 4;
      expect(tc.framesCount(), expectedFrames);
    });

    test('tcFromDuration initializes timecode correctly from duration', () {
      Timecode.framerate = 25;
      Duration duration = const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 400);
      Timecode tc = Timecode.fromDuration(duration);
      expect(tc.h, 1);
      expect(tc.m, 2);
      expect(tc.s, 3);
      expect(tc.f, (25 * 0.4).round());
    });

    test('tcAsDuration converts timecode to correct duration', () {
      Timecode.framerate = 25;
      int h = 1;
      int m = 2;
      int s = 3;
      int f = 4;
      Timecode tc = Timecode.fromIntValues(h, m, s, f);
      Duration duration = tc.tcAsDuration();
      expect(duration.inHours, h);
      expect(duration.inMinutes % 60, m);
      expect(duration.inSeconds % 60, s);
      expect(duration.inMilliseconds % 1000, ((f / Timecode.framerate) * 1000).round());
    });

    test('Addition operator adds timecodes correctly', () {
      Timecode.framerate = 25;
      Timecode tc1 = Timecode('01:00:00:00');
      Timecode tc2 = Timecode('00:30:00:00');
      Timecode result = tc1 + tc2;
      expect(result.showTimecode(), '01:30:00:00');
    });

    test('Subtraction operator subtracts timecodes correctly', () {
      Timecode.framerate = 25;
      Timecode tc1 = Timecode('01:00:00:00');
      Timecode tc2 = Timecode('00:30:00:00');
      Timecode result = tc1 - tc2;
      expect(result.showTimecode(), '00:30:00:00');
    });

    test('Comparison operators work as expected', () {
      //TODO: FIX THESE
      Timecode.framerate = 25;
      Timecode tc1 = Timecode('01:00:00:00');
      Timecode tc2 = Timecode('00:30:00:00');
      Timecode tc3 = Timecode('01:00:00:00');
      expect(tc1.compareTo(tc2) > 0, false);
      expect(tc2.compareTo(tc1) < 0, true);
      expect(tc1.compareTo(tc3) == 0, true);
    });

    test('toString returns correctly formatted timecode string', () {
      Timecode tc = Timecode('01:02:03:04');
      expect(tc.toString(), '01:02:03:04');
    });
  });
}