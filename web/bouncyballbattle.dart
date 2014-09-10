import 'dart:html';
import 'dart:convert';

import 'player.dart';
import 'game.dart';

Stopwatch stopwatch = new Stopwatch();
Game game;

RealisticMovementPlayer playerFromPolymerMap(Map playerMap) {
  String name = playerMap['name'];
  int leftKey = playerMap['left'];
  int rightKey = playerMap['right'];
  int accelerateKey = playerMap['accelerate'];
  int reverseKey = playerMap['reverse'];
  double hue = playerMap['hue'];
  if (name == null || leftKey == null || rightKey == null || accelerateKey == null || reverseKey == null || hue == null) {
   // print("Null value found, raising an exception!");
    throw new Exception();
  } else {
   // print("Let's initialize a new player!");
    RealisticMovementPlayer toReturn = new RealisticMovementPlayer(name: name, upKey: accelerateKey, rightKey: rightKey, downKey: reverseKey, leftKey: leftKey, hue: hue);
   // print("New player initialized! About to return him.");
    return toReturn;
  }
}

main() {
  Element gameCanvas = document.getElementById("gameCanvas");
  Storage localStorage = window.localStorage;
  if (localStorage == null) {
    game = new Game(gameCanvas);
  } else {
    try {
      String jsonSettings = localStorage['settings'];
      if (jsonSettings == null) {
        throw new Exception();
      }
      Map settings = JSON.decode(jsonSettings);
      List<Map> playerMaps = settings['players'];
      if (playerMaps == null || playerMaps.length == 0) {
        throw new Exception();
      }
      List<RealisticMovementPlayer> players = new List<RealisticMovementPlayer>();
      for (Map playerMap in playerMaps) {
        players.add(playerFromPolymerMap(playerMap));
      }
      int stageID = settings['stage'];
      game = new Game(gameCanvas, players : players, stageID : stageID);
      } catch (e) {
      game = new Game(gameCanvas);
      localStorage['settings'] == null; // local storage must have been corrupted
    }
  }
  stopwatch.start();
  updateLoop();
}


void updateLoop() {
  Duration elapsedTime = stopwatch.elapsed;
  stopwatch.reset();
  game.update(elapsedTime);
  window.requestAnimationFrame((e) => updateLoop());
}