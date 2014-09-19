import 'dart:html';
import 'dart:convert';

import 'player.dart';
import 'game.dart';

Stopwatch stopwatch = new Stopwatch();
Game game;

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
        players.add(new RealisticMovementPlayer.fromMap(playerMap));
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
  if (game.done) {
    game.restart();
  }
  window.requestAnimationFrame((e) => updateLoop());
}