import 'dart:html';
import 'game.dart';
import 'stage.dart';

Game game;
Stopwatch stopwatch = new Stopwatch();

main() {
  Element gameCanvas = document.getElementById("gameCanvas");
  Storage localStorage = window.localStorage;
  game = new Game(gameCanvas, stageID : Stage.TESTSTAGE);
  stopwatch.start();
  updateLoop();
}


void updateLoop() {
  Duration elapsedTime = stopwatch.elapsed;
  stopwatch.reset();
  game.update(elapsedTime);
  window.requestAnimationFrame((e) => updateLoop());
}