library clock;

class Clock {
  
  DateTime startTime;
  DateTime oldTime;
  Duration elapsedTime = new Duration();
  bool autoStart = false;
  bool running = false;
  
  Clock([this.autoStart]) {
  }

  void start() {
    this.startTime = new DateTime.now();
    this.oldTime = this.startTime;
    this.running = true;
  }

  void stop() {
    this.getElapsedTime();
    this.running = false;
  }

  Duration getElapsedTime() {
    this.elapsedTime += this.getDelta();
    return this.elapsedTime;
  }


  Duration getDelta () {
    Duration diff;
    if ( this.autoStart && ! this.running ) {
      this.start();
    }
    if ( this.running ) {
      DateTime newTime = new DateTime.now();
      diff = newTime.difference(oldTime); //0.001 * ( newTime - this.oldTime );
      this.oldTime = newTime;
      this.elapsedTime += diff;
    }
    return diff;
  }
}