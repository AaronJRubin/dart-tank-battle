import 'package:three/three.dart';
import 'stage.dart';
import 'keyboard.dart';
import 'player.dart';
import 'dart:html';
import 'animation.dart' as animation;
import 'package:vector_math/vector_math.dart' as vector;

class Game extends animation.Animation {

  /// _CANVASWIDTH resizes dynamically on each render.
  /// Hence, it should not be set from outside.
  int _CANVASWIDTH = window.innerWidth;
  /// _CANVASHEIGHT resizes dynamically on each render.
  /// Hence, it should not be set from outside.
  int _CANVASHEIGHT = window.innerHeight;

  int get CANVASWIDTH {
    return _CANVASWIDTH;
  }

  int get CANVASHEIGHT {
    return _CANVASHEIGHT;
  }

  bool get done => players.length == 0;

  Scene scene = new Scene();

  final WebGLRenderer renderer = new WebGLRenderer();
  final Keyboard keyboard = new Keyboard();

  Stage stage;
  List<RealisticMovementPlayer> players;
  List<Bullet> bullets = new List<Bullet>();

  /// playerMaps are remembered to restart the game with fresh players
  final List<Map> playerMaps = new List<Map>();
  /// stageID is remembered to restart the game with a clean stage
  final int stageID;

  static List<RealisticMovementPlayer> generateDefaultPlayers() {
    List<RealisticMovementPlayer> toReturn = new List<RealisticMovementPlayer>();
    toReturn.add(new RealisticMovementPlayer(upKey: KeyCode.W, rightKey: KeyCode.D, downKey: KeyCode.S, leftKey: KeyCode.A, hue: 0.2, name: 'Steve'));
    toReturn.add(new RealisticMovementPlayer(upKey: KeyCode.UP, rightKey: KeyCode.RIGHT, downKey: KeyCode.DOWN, leftKey: KeyCode.LEFT, hue: 0.6));
    return toReturn;
  }

  Game(Element canvas, {this.players, this.stageID: Stage.NINEPILLARSTAGE, bool debug: false}) {
    if (players == null) {
      players = generateDefaultPlayers();
    }
    switch (stageID) {
      case (Stage.BASICSTAGE):
        stage = new BasicStage(scene);
        break;
      case (Stage.NINEPILLARSTAGE):
        stage = new NinePillarStage(scene, pillarsMove: false);
        break;
      case (Stage.MOVINGNINEPILLARSTAGE):
        stage = new NinePillarStage(scene, pillarsMove: true);
        break;
      case (Stage.LAVADEATHSTAGE):
        stage = new LavaDeathStage(scene, walls: true);
        break;
      case (Stage.LAVADEATHSTAGENOWALLS):
        stage = new LavaDeathStage(scene, walls: false);
        break;
      case (Stage.TESTSTAGE):
        stage = new TestStage(scene);
        break;
      default:
        throw "Unrecognized stage ID";
    }
    Element element = renderer.canvas;
    canvas.append(element);
    window.addEventListener('click', (Event e) => element.requestFullscreen());
    renderer.autoClear = false;
    stage.positionPlayersAppropriately(players);
    for (RealisticMovementPlayer player in players) {
      scene.add(player);
      playerMaps.add(player.startingConfigurationMap);
      /* If you don't update the matrix world as below,
         * the lag in the automatic update will result in
         * spurious collisions when those collisions are calculated
         * on the basis of the matrix world translation (which is the most
         * robust way to perform collision calculations, due to the
         * nature of object hierarchies). Those spurious collisions seem to stop
         * after only three or so animation loop iterations, but that's obviously
         * too late */
      player.updateMatrixWorld(force: true);
    }
    for (Object3D model in stage.startingModels) {
      scene.add(model);
    }
    keyboard.bindToWindow();
    if (debug) {
      window.addEventListener('keydown', (KeyboardEvent e) {
        if (e.keyCode == KeyCode.B) {
          log();
        }
      });
    }
  }

  void log() {
    print("***************");
    for (RealisticMovementPlayer player in players) {
     print("************");
     player.log();
    }
    print("***************");
    print("***************");
  }

  void restart() {
    scene = new Scene();
    bullets.clear();
    players.clear();
    switch (stageID) {
      case (Stage.BASICSTAGE):
        stage = new BasicStage(scene);
        break;
      case (Stage.NINEPILLARSTAGE):
        stage = new NinePillarStage(scene, pillarsMove: false);
        break;
      case (Stage.MOVINGNINEPILLARSTAGE):
        stage = new NinePillarStage(scene, pillarsMove: true);
        break;
      case (Stage.LAVADEATHSTAGE):
        stage = new LavaDeathStage(scene, walls: true);
        break;
      case (Stage.LAVADEATHSTAGENOWALLS):
        stage = new LavaDeathStage(scene, walls: false);
        break;
      case (Stage.TESTSTAGE):
        stage = new TestStage(scene);
        break;
      default:
        throw "Unrecognized stage ID";
    }
    for (Map playerMap in playerMaps) {
      RealisticMovementPlayer player = new RealisticMovementPlayer.fromMap(playerMap);
      players.add(player);
    }
    stage.positionPlayersAppropriately(players);
    for (RealisticMovementPlayer player in players) {
      scene.add(player);
      player.updateMatrixWorld(force: true);
    }
    for (Object3D model in stage.startingModels) {
      scene.add(model);
    }
  }

  void _updateBullets(Duration elapsedTime) {
    // print("About to call stage.handleBulletWorldInteraction!");
    stage.handleBulletWorldInteraction(bullets);
    // print("Successfully exited stage.handleBulletWorldInteraction!");
    Set<Bullet> toDestroy = new Set<Bullet>();
    int i = 0;
    int q;
    for (Bullet bullet in bullets) {
      bullet.update(elapsedTime);
      i++;
      if (i < bullets.length) {
        for (q = i; q < bullets.length; q++) {
          if (bullet.checkOtherBulletCollision(bullets[q])) {
            if (!toDestroy.contains(bullet)) {
              toDestroy.add(bullet);
            }
            if (!toDestroy.contains(bullets[q])) {
              toDestroy.add(bullets[q]);
            }
          }
        }
      }
      for (RealisticMovementPlayer player in players) {
        if (player == bullet.owner) {
          continue;
        }
        if (bullet.checkPlayerCollision(player)) {
          player.hit();
          player.impact(bullet.computeVelocity(), Bullet.mass);
          toDestroy.add(bullet);
        }
      }
    }
    for (Bullet bullet in toDestroy) {
      bullets.remove(bullet);
      scene.remove(bullet);
    }
  }

  void _updatePlayers(Duration elapsedTime) {
    stage.handlePlayerWorldInteraction(players, elapsedTime);
    stage.handlePlayerItemInteraction(players);
    List<RealisticMovementPlayer> toRemove = new List<RealisticMovementPlayer>();
    int i = 0;
    int q = 0;
    for (RealisticMovementPlayer player in players) {
      i++;
      if (!player.dead) {
        for (Bullet b in player.update(keyboard, elapsedTime)) {
          scene.add(b);
          bullets.add(b);
        }
      } else {
        toRemove.add(player);
      }
      if (i < players.length) {
        for (q = i; q < players.length; q++) {
          if (player.checkPlayerCollision(players[q])) {
            if (player.spikey) {
              if (!players[q].spikey) {
                players[q].hit();
              }
            }
            if (players[q].spikey) {
              if (!player.spikey) {
                player.hit();
              }
            }
            vector.Vector3 iVelocity = player.computeTotalVelocity();
            vector.Vector3 qVelocity = players[q].computeTotalVelocity();
            players[q].setVelocity(iVelocity);
            player.setVelocity(qVelocity);
            while (player.checkPlayerCollision(players[q])) {
              player.budge();
              players[q].budge();
            }
          }
        }
      }
    }
    for (RealisticMovementPlayer p in toRemove) {
      players.remove(p);
      scene.remove(p);
    }
  }

  void update(Duration elapsedTime) {
    if (!done) {
      _CANVASWIDTH = window.innerWidth - 20;
      _CANVASHEIGHT = window.innerHeight - 20;
      renderer.setSize(_CANVASWIDTH, _CANVASHEIGHT);
      // print("About to call update players!");
      _updatePlayers(elapsedTime);
      // print('About to call update bullest!');
      _updateBullets(elapsedTime);
      // print('About to call stage.update!');
      stage.update(elapsedTime);
      // print("About to render appropriately!");
      _renderAppropriately();
    }
  }

  void _renderAppropriately() {
    if (players.length == 1) {
      renderer.setViewport(0, 0, _CANVASWIDTH, _CANVASHEIGHT);
      players[0].updateCameraAspectRatio(_CANVASWIDTH / _CANVASHEIGHT);
      renderer.render(scene, players[0].camera);
      return;
    }
    if (players.length == 2) {
      int width = _CANVASWIDTH;
      int height = _CANVASHEIGHT ~/ 2;
      renderer.setViewport(0, height, width, height);
      players[0].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[0].camera);
      renderer.setViewport(0, 0, width, height);
      players[1].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[1].camera);
      return;
    }
    if (players.length == 3) {
      int width = _CANVASWIDTH ~/ 2;
      int height = _CANVASHEIGHT ~/ 2;
      renderer.setViewport(0, height, width, height);
      players[0].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[0].camera);
      renderer.setViewport(width, height, width, height);
      players[1].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[1].camera);
      width = _CANVASWIDTH;
      renderer.setViewport(0, 0, width, height);
      players[2].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[2].camera);
    }
    if (players.length == 4) {
      int width = _CANVASWIDTH ~/ 2;
      int height = _CANVASHEIGHT ~/ 2;
      renderer.setViewport(0, height, width, height);
      players[0].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[0].camera);
      renderer.setViewport(width, height, width, height);
      players[1].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[1].camera);
      renderer.setViewport(0, 0, width, height);
      players[2].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[2].camera);
      renderer.setViewport(width, 0, width, height);
      players[3].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[3].camera);
    }
  }

}
