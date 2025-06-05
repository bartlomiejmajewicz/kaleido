

class Timecode implements Comparable<Timecode> {

  late double framerate;
  
  

  int h=0;
  int m=0;
  int s=0;
  int f=0;


  Timecode([String timecodeAsText="00:00:00:00", this.framerate = 25]) {
    if (tcValidateCheck(timecodeAsText, framerate)) {
      List<String> splittedTc = timecodeAsText.split(':');
      h = int.parse(splittedTc[0]);
      m = int.parse(splittedTc[1]);
      s = int.parse(splittedTc[2]);
      f = int.parse(splittedTc[3]);
      return;
    }
    if (tcAsMmSsValidateCheck(timecodeAsText)) {
      List<String> splittedTc = timecodeAsText.split(':');
      h = 0;
      m = int.parse(splittedTc[0]);
      s = int.parse(splittedTc[1]);
      f = 0;
      return;
    }

    timecodeAsText="00:00:00:00";
    List<String> splittedTc = timecodeAsText.split(':');
    h = int.parse(splittedTc[0]);
    m = int.parse(splittedTc[1]);
    s = int.parse(splittedTc[2]);
    f = int.parse(splittedTc[3]);
    
  }

  Timecode.fromDuration(Duration duration, this.framerate){
    framerate = framerate;
    tcFromDuration(duration);
  }

  Timecode.fromIntValues(int hour, int min, int sec, int fr, this.framerate){
    h = hour;
    m = min;
    s = sec;
    f = fr;
  }

  Timecode.fromFramesCount(int framesCount, this.framerate){
    framerate = framerate;
    _tcFromFramesCount(framesCount);
  }


  static bool tcValidateCheck(String timecodeAsText, double framerate) {
  // check if the TC is a valid value
    var tcValidateCheck = RegExp(r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d):([0-5]\d)$');
    if (!tcValidateCheck.hasMatch(timecodeAsText)) {
      return false;
    }
    try {
      if (int.parse(timecodeAsText.split(':')[3]) >= framerate) {
      return false;
    }
    // ignore: empty_catches
    } catch (e) {
    }
    
    return true;
  }

  static bool tcAsMmSsValidateCheck(String timecodeAsText){
    var tcValidateCheck = RegExp(r'^([0-5]?[0-9]):[0-5][0-9]$');
    if(tcValidateCheck.hasMatch(timecodeAsText)){
      return true;
    } else{
      return false;
    }
  }

  String _asString(){
    String output="";
    output += h.toString().padLeft(2, '0');
    output += ":";
    output += m.toString().padLeft(2, '0');
    output += ":";
    output += s.toString().padLeft(2, '0');
    output += ":";
    output += f.toString().padLeft(2,'0');

    return output;
  }

  String asStringFormattedMmSs(){
    return "${_asString().split(':')[1]}:${_asString().split(':')[2]}";
  }

  int framesCount(){
    int frCount=0;
    frCount += f;
    frCount += (s*framerate).toInt();
    frCount += (m*60*framerate).toInt();
    frCount += (h*60*60*framerate).toInt();

    return frCount;

  }

  void addFrame(){
    f++;
    if (f >= framerate) {
      f=0;
      s++;
      if (s==60) {
        s=0;
        m++;
        if (m==60) {
          m=0;
          h++;
          if (h==24) {
            h=0;
          }
        }
      }
    }
  }

  void substractFrame(){
    f--;
    if (f == -1) {
      f=framerate.toInt()-1;
      s--;
      if (s==-1) {
        s=59;
        m--;
        if (m==-1) {
          m=59;
          h--;
          if (h==-1) {
            h=23;
          }
        }
      }
    }
  }

  void tcFromDuration(Duration duration){
    int millis = duration.inMilliseconds;
    h = millis ~/ (1000*3600);
    millis = millis - (h*1000*3600);
    m = millis ~/ (1000*60);
    millis = millis - (m*1000*60);
    s = millis ~/ (1000);
    millis = millis - s*1000;
    f = ((framerate * millis) / 1000).round();
  }

  static int countFrames(Duration duration, double framerate){
    return (duration.inMilliseconds ~/ (1000 / framerate));
  }

  void _tcFromFramesCount(int framesCount){
    for (var i = 0; i < framesCount; i++) {
      addFrame();
    }
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
    return Timecode.fromDuration(tcAsDuration()+other.tcAsDuration(), framerate);
  }

  Timecode operator - (Timecode other){
    return Timecode.fromDuration(tcAsDuration()-other.tcAsDuration(), framerate);
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
    return _asString();
  }

  Timecode conformToOtherFps(double destinationFps){
    return Timecode.fromFramesCount(framesCount(), destinationFps);
  }


}
