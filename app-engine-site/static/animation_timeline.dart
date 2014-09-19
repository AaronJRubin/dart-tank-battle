part of animation;

class AnimationTimeline extends Animation {

  static const int REPEATINDEFINITELY = -1;
  List<Animation> animations;
  int currentPhaseIndex = 0;
  int repeatCount = 0;
  int maxRepeats;

  AnimationTimeline({this.animations, this.maxRepeats: 1});

  bool get done {
    return currentPhaseIndex >= animations.length;
  }

  void restart() {
    currentPhaseIndex = 0;
    for (Animation phase in animations) {
      phase.restart();
    }
  }

  void update(Duration duration) {
    if (done) {
      return;
    }
    Animation currentPhase = animations[currentPhaseIndex];
    currentPhase.update(duration);
    if (currentPhase.done) {
      currentPhaseIndex++;
      if (done) {
        repeatCount++;
        if (repeatCount < maxRepeats || maxRepeats == REPEATINDEFINITELY) {
          restart();
        } else {
          cleanup();
        }
      }
    }
  }


}
