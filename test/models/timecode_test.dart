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

    test('Default constructor parses format MM:SS', (){
      Timecode tc = Timecode('02:15');
      expect(tc.h, 0);
      expect(tc.m, 2);
      expect(tc.s, 15);
      expect(tc.f, 0);

      Timecode tc2 = Timecode('25:36');
      expect(tc2.h, 0);
      expect(tc2.m, 25);
      expect(tc2.s, 36);
      expect(tc2.f, 0);
    });

    test('tcAsMmSsValidateCheck correctly validates valid timecode strings', () {
      expect(Timecode.tcAsMmSsValidateCheck('12:22'), true);
      expect(Timecode.tcAsMmSsValidateCheck('03:16'), true);
    });
    test('tcAsMmSsValidateCheck correctly invalidates invalid timecode strings', () {
      expect(Timecode.tcAsMmSsValidateCheck('72:22'), false);
      expect(Timecode.tcAsMmSsValidateCheck('03:16:12'), false);
    });


    test('tcValidateCheck correctly validates valid timecode strings', () {
      Timecode.framerate = 25;
      expect(Timecode.tcValidateCheck('12:34:56:20'), true);
      expect(Timecode.tcValidateCheck('23:59:59:24'), true);
      expect(Timecode.tcValidateCheck('12:34:56:28'), false);
    });

    test('tcValidateCheck correctly invalidates invalid timecode strings', () {
      expect(Timecode.tcValidateCheck('25:00:00:00'), false);
      expect(Timecode.tcValidateCheck('12:60:00:00'), false);
      expect(Timecode.tcValidateCheck('12:34:60:00'), false);
      expect(Timecode.tcValidateCheck('12:34:56:60'), false);
      expect(Timecode.tcValidateCheck('not-a-timecode'), false);
    });

    test('framesCount calculates total frames correctly', () {
      Timecode.framerate = 25;
      Timecode tc = Timecode.fromIntValues(1, 2, 3, 4);
      int expectedFrames = 1 * 60 * 60 * 25 + 2 * 60 * 25 + 3 * 25 + 4;
      expect(tc.framesCount(), expectedFrames);
    });

    test('asStringFormattedMmSs correctly formats timecode', () {
      Timecode tc = Timecode("10:00:12:22");
      expect(tc.asStringFormattedMmSs(), "00:12");
      tc = Timecode("08:02:26:13");
      expect(tc.asStringFormattedMmSs(), "02:26");
      tc = Timecode("05:01:32:12");
      expect(tc.asStringFormattedMmSs(), "01:32");
      tc = Timecode("00:00:01:22");
      expect(tc.asStringFormattedMmSs(), "00:01");
    });

    test('addFrame works correctly', () {
      Timecode.framerate = 25;
      Timecode tc = Timecode("10:00:15:22");
      tc.addFrame();
      expect(tc.toString(), Timecode("10:00:15:23").toString());

      tc = Timecode("09:11:05:24");
      tc.addFrame();
      expect(tc.toString(), Timecode("09:11:06:00").toString());

      tc = Timecode("09:15:59:24");
      tc.addFrame();
      expect(tc.toString(), Timecode("09:16:00:00").toString());

      tc = Timecode("23:59:59:24");
      tc.addFrame();
      expect(tc.toString(), Timecode("00:00:00:00").toString());
    },);

    test('substractFrame works correctly', () {
      Timecode.framerate = 25;
      Timecode tc = Timecode("10:00:15:23");
      tc.substractFrame();
      expect(tc.toString(), Timecode("10:00:15:22").toString());

      tc = Timecode("09:11:06:00");
      tc.substractFrame();
      expect(tc.toString(), Timecode("09:11:05:24").toString());

      tc = Timecode("09:16:00:00");
      tc.substractFrame();
      expect(tc.toString(), Timecode("09:15:59:24").toString());

      tc = Timecode("00:00:00:00");
      tc.substractFrame();
      expect(tc.toString(), Timecode("23:59:59:24").toString());
    },);
    

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
      expect(result.toString(), '01:30:00:00');
    });

    test('Subtraction operator subtracts timecodes correctly', () {
      Timecode.framerate = 25;
      Timecode tc1 = Timecode('01:00:00:00');
      Timecode tc2 = Timecode('00:30:00:00');
      Timecode result = tc1 - tc2;
      expect(result.toString(), '00:30:00:00');
    });

    test('Comparison operators work as expected', () {
      Timecode.framerate = 25;
      Timecode tc1 = Timecode('01:00:00:00');
      Timecode tc2 = Timecode('00:30:00:00');
      Timecode tc3 = Timecode('01:00:00:00');
      expect(tc1.compareTo(tc2) > 0, false);
      expect(tc2.compareTo(tc1) < 0, true);
      expect(tc1.compareTo(tc3) == 0, true);
    });

    test('toString returns correctly formatted timecode string', () {
      String timecodeAsText = '01:02:03:04';
      Timecode tc = Timecode(timecodeAsText);
      expect(tc.toString(), timecodeAsText);
    });
  });
}