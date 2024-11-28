class Timecode implements Comparable<Timecode> {

  static int framerate = 25; // TODO FRAMERATE SET

  

  int h=0;
  int m=0;
  int s=0;
  int f=0;


  Timecode([String timecodeAsText="00:00:00:00"]) {
    if (!tcValidateCheck(timecodeAsText)) {
      timecodeAsText = "00:00:00:00";
    }
    List<String> splittedTc = timecodeAsText.split(':');
    h = int.parse(splittedTc[0]);
    m = int.parse(splittedTc[1]);
    s = int.parse(splittedTc[2]);
    f = int.parse(splittedTc[3]);
  }

  Timecode.fromDuration(Duration duration){
    tcFromDuration(duration);
  }

  Timecode.fromIntValues(int hour, int min, int sec, int fr){
    h = hour;
    m = min;
    s = sec;
    f = fr;
  }


  static bool tcValidateCheck(String timecodeAsText) {
  // check if the TC is a valid value
  var tcValidateCheck = RegExp(r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d):([0-5]\d)$');
    if(tcValidateCheck.hasMatch(timecodeAsText)){
      return true;
    } else{
      return false;
    }
  }

  String showTimecode(){
    String output="";
    if(h<10){
      output = "0";
    }
    output += h.toString();

    output += ":";

    if (m<10) {
      output += "0";
    }
    output += m.toString();

    output += ":";

    if (s<10) {
      output += "0";
    }
    output += s.toString();
    
    output += ":";

    if (f<10) {
      output += "0";
    }
    output += f.toString();


    return output;

  }

  int framesCount(){
    int frCount=0;
    frCount += f;
    frCount += s*framerate;
    frCount += m*60*framerate;
    frCount += h*60*60*framerate;

    return frCount;

  }

  tcFromDuration(Duration duration){
    int millis = duration.inMilliseconds;
    h = millis ~/ (1000*3600);
    millis = millis - (h*1000*3600);
    m = millis ~/ (1000*60);
    millis = millis - (m*1000*60);
    s = millis ~/ (1000);
    millis = millis - s*1000;
    f = (framerate * millis / 1000).round();
  }

  Duration tcAsDuration(){
    return Duration(
      hours: h,
      minutes: m,
      seconds: s,
      milliseconds:  ((f/framerate)*1000).round()
      );
  }

  Timecode operator + (Timecode other){
    return Timecode.fromDuration(tcAsDuration()+other.tcAsDuration());
  }

  Timecode operator - (Timecode other){
    return Timecode.fromDuration(tcAsDuration()-other.tcAsDuration());
  }
  
  @override
  int compareTo(Timecode other) {
    if (framesCount() < other.framesCount()) {
      return -1;
    } else if (framesCount() < other.framesCount()) {
      return 1;
    } else {
      return 0;
    }
  }
  
  @override
  String toString() {
    return showTimecode();
  }


}
