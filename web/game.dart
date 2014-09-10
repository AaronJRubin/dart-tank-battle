import 'package:three/three.dart';
import 'stage.dart';
import 'keyboard.dart';
import 'player.dart';
import 'dart:html';
import 'package:vector_math/vector_math.dart' as vector;

class Game {

  int CANVASWIDTH = window.innerWidth;
  int CANVASHEIGHT = window.innerHeight;

  final Scene scene = new Scene();
  final Stopwatch stopwatch = new Stopwatch();

  final WebGLRenderer renderer = new WebGLRenderer();
  final Keyboard keyboard = new Keyboard();

  Stage stage;
  List<RealisticMovementPlayer> players;
  List<Bullet> bullets = new List<Bullet>();

  static List<RealisticMovementPlayer> generateDefaultPlayers() {
    List<RealisticMovementPlayer> toReturn = new List<RealisticMovementPlayer>();
    toReturn.add(new RealisticMovementPlayer(upKey: KeyCode.W, rightKey: KeyCode.D, downKey: KeyCode.S, leftKey: KeyCode.A, hue: 0.2, name: 'Steve'));
    toReturn.add(new RealisticMovementPlayer(upKey: KeyCode.UP, rightKey: KeyCode.RIGHT, downKey: KeyCode.DOWN, leftKey: KeyCode.LEFT, hue: 0.6));
    return toReturn;
  }

  Game(Element canvas, {this.players, int stageID: Stage.NINEPILLARSTAGE}) {
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
    stopwatch.start();
  }

  void updateBullets(Duration elapsedTime) {
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

  void updatePlayers(Duration elapsedTime) {
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
    CANVASWIDTH = window.innerWidth - 20;
    CANVASHEIGHT = window.innerHeight - 20;
    renderer.setSize(CANVASWIDTH, CANVASHEIGHT);
    // print("About to call update players!");
    updatePlayers(elapsedTime);
    // print('About to call update bullest!');
    updateBullets(elapsedTime);
    // print('About to call stage.update!');
    stage.update(elapsedTime);
    // print("About to render appropriately!");
    renderAppropriately();
  }

  void renderAppropriately() {
    if (players.length == 1) {
      renderer.setViewport(0, 0, CANVASWIDTH, CANVASHEIGHT);
      players[0].updateCameraAspectRatio(CANVASWIDTH / CANVASHEIGHT);
      renderer.render(scene, players[0].camera);
      return;
    }
    if (players.length == 2) {
      int width = CANVASWIDTH;
      int height = CANVASHEIGHT ~/ 2;
      renderer.setViewport(0, height, width, height);
      players[0].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[0].camera);
      renderer.setViewport(0, 0, width, height);
      players[1].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[1].camera);
      return;
    }
    if (players.length == 3) {
      int width = CANVASWIDTH ~/ 2;
      int height = CANVASHEIGHT ~/ 2;
      renderer.setViewport(0, height, width, height);
      players[0].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[0].camera);
      renderer.setViewport(width, height, width, height);
      players[1].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[1].camera);
      width = CANVASWIDTH;
      renderer.setViewport(0, 0, width, height);
      players[2].updateCameraAspectRatio(width / height);
      renderer.render(scene, players[2].camera);
    }
    if (players.length == 4) {
      int width = CANVASWIDTH ~/ 2;
      int height = CANVASHEIGHT ~/ 2;
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

