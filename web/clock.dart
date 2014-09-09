library clock;

/**
 *
 * A port of [THREE.Clock](doc/three.js/src/core/Clock.js).
 *
 * This class is well-suited for making consistent animations
 * where the extent to which objects move is real-time-dependent,
 * rather than dependent upon the rate at which window.RequestAnimationFrame
 * is called (which can vary according to various factors that are
 * outside of the programmer's control). */
class Clock {

  /// The time when this clock started.
  DateTime startTime;
  /// The time when [getDelta] was last called.
  DateTime _oldTime;
  /// The time since this clock started.
  Duration _elapsedTime = new Duration();
  /// Whether this clock should start upon the first call to [getDelta],
  /// even if [start] was never explicitly called.
  bool autoStart;
  /// Whether this clock is currently running.
  /// Should be set only by the start() and stop()
  /// methods, and so there should not be a public setter.
  bool _running = false;

  bool get running {
    return _running;
  }

  Clock({this.autoStart : true}) {
  }

  /**
   * Starts this clock */
  void start() {
    this.startTime = new DateTime.now();
    this._oldTime = this.startTime;
    this._running = true;
  }

  /**
   * Stops this clock */
  void stop() {
    this.getElapsedTime();
    this._running = false;
  }

  /**
   * Returns elapsed time since this clock started */
  Duration getElapsedTime() {
    this._elapsedTime += this.getDelta();
    return this._elapsedTime;
  }

  /**
   * Returns elapsed time since last call to [getDelta] */
  Duration getDelta () {
    Duration diff;
    if ( this.autoStart && ! this._running ) {
      this.start();
    }
    if ( this._running ) {
      DateTime newTime = new DateTime.now();
      diff = newTime.difference(_oldTime);
      this._oldTime = newTime;
      this._elapsedTime += diff;
    }
    return diff;
  }
}