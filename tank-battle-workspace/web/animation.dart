library animation;

part 'animation_timeline.dart';
part 'basic_animation.dart';

typedef void CleanupFunction();
typedef void UpdateFunction(Duration);
typedef bool TestFunction();

abstract class Animation {

  bool get done;
  CleanupFunction cleanup = emptyCleanupFunction;
  void update(Duration d);
  void restart();

  static void emptyCleanupFunction() {
    return;
  }

  static void emptyUpdateFunction(Duration duration) {
    return;
  }

  static bool alwaysTrue() {
    return true;
  }

  static bool alwaysFalse() {
    return false;
  }

}