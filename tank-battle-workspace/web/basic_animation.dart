part of animation;


class BasicAnimation extends Animation {

  UpdateFunction updateFunction = Animation.emptyUpdateFunction;
  TestFunction test = Animation.alwaysFalse;
  Duration elapsedTime = new Duration();
  bool done = false;

  BasicAnimation.withNothingInitialized() {
  }

  BasicAnimation.withTestFunction(this.updateFunction, this.test);

  BasicAnimation(this.updateFunction, Duration timeLimit) {
    this.test = (() => elapsedTime >= timeLimit);
  }

  void update(Duration d) {
    if (!done) {
      updateFunction(d);
      elapsedTime += d;
      if (test()) {
        done = true;
        cleanup();
      }
    }
  }

  void restart() {
    elapsedTime = new Duration();
    done = false;
  }

}
