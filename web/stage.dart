library stage;

import 'package:three/three.dart';
import 'player.dart';
import 'items.dart';
import 'obstacles.dart';
import 'package:three/extras/image_utils.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:math';
import 'animation.dart';

part 'basic_stage.dart';
part 'nine_pillar_stage.dart';
part 'lava_death_stage.dart';
part 'test_stage.dart';

typedef void UpdateAction(Duration duration);
typedef Object3D MakePlaneFunction(double squareWidth);

abstract class Stage {

  static const int BASICSTAGE = 0;
  static const int NINEPILLARSTAGE = 1;
  static const int MOVINGNINEPILLARSTAGE = 2;
  static const int LAVADEATHSTAGE = 3;
  static const int LAVADEATHSTAGENOWALLS = 4;
  static final Duration spawnInterval = new Duration(seconds: 1);
  static final Random random = new Random();

  AnimationTimeline spawnAnimation;

  List<Shotgun> shotguns = [];
  List<SpikeBall> spikeBalls = [];

  List<Object3D> get startingModels;
  List<UpdateAction> get updateActions;
  Scene get scene;

  void positionPlayersAppropriately(List<RealisticMovementPlayer> players);
  void handlePlayerWorldInteraction(List<RealisticMovementPlayer> players, Duration d);
  void handleBulletWorldInteraction(List<Bullet> bullets);
  Vector3 generateSpawningLocation();

  Stage() {
    spawnAnimation = generateSpawnAnimation();
  }

  void _registerUpdateAction(UpdateAction updateAction) {
    updateActions.add(updateAction);
  }

  void _addShotgun(Shotgun shotgun) {
    shotguns.add(shotgun);
  }

  void update(Duration duration) {
    spawnAnimation.update(duration);
    for (Shotgun shotgun in shotguns) {
      shotgun.update(duration);
    }
    for (SpikeBall spikeBall in spikeBalls) {
      spikeBall.update(duration);
    }
    for (UpdateAction updateAction in updateActions) {
      updateAction(duration);
    }
  }

  void handlePlayerItemInteraction(List<RealisticMovementPlayer> players) {
    Set<Shotgun> shotgunsToRemove = new Set<Shotgun>();
    Set<SpikeBall> spikeBallsToRemove = new Set<SpikeBall>();
    for (RealisticMovementPlayer player in players) {
      for (Shotgun shotgun in shotguns) {
        if (player.checkItemCollision(shotgun)) {
          shotgunsToRemove.add(shotgun);
          player.handleShotgunPickup();
        }
      }
      for (SpikeBall spikeBall in spikeBalls) {
        if (player.checkItemCollision(spikeBall)) {
          spikeBallsToRemove.add(spikeBall);
          player.handleSpikeBallPickup();
        }
      }
    }
    for (Shotgun shotgun in shotgunsToRemove) {
      shotguns.remove(shotgun);
      scene.remove(shotgun);
    }
    for (SpikeBall spikeBall in spikeBallsToRemove) {
      spikeBalls.remove(spikeBall);
      scene.remove(spikeBall);
    }
  }

  void spawnItem() {
    int randomInt = random.nextInt(10);
    if (randomInt == 0) {
      Shotgun shotgun = new Shotgun();
      Vector3 spawningLocation = generateSpawningLocation();
      shotgun.position.x = spawningLocation.x;
      shotgun.position.z = spawningLocation.z;
      scene.add(shotgun);
      shotguns.add(shotgun);
    }
    if (randomInt == 1) {
      SpikeBall ball = new SpikeBall();
      Vector3 spawningLocation = generateSpawningLocation();
      ball.position.x = spawningLocation.x;
      ball.position.z = spawningLocation.z;
      scene.add(ball);
      spikeBalls.add(ball);
    }
  }

  AnimationTimeline generateSpawnAnimation() {
    BasicAnimation pause = new BasicAnimation(Animation.emptyUpdateFunction, spawnInterval);
    pause.cleanup = spawnItem;
    AnimationTimeline spawnAnimation = new AnimationTimeline(animations : [pause], maxRepeats : AnimationTimeline.REPEATINDEFINITELY);
    return spawnAnimation;
  }

  static Mesh _generateGround(double squareSideLength, {Texture texture}) {
    if (texture == null) {
      texture = loadTexture('mulch-tiled.jpg');
      texture.wrapS = texture.wrapT = RepeatWrapping;
      texture.repeat.setValues(8.0, 8.0);
      texture.generateMipmaps = true;
    }
    MeshBasicMaterial groundMaterial = new MeshBasicMaterial();
    groundMaterial.map = texture;
    Mesh ground = new Mesh(new PlaneGeometry(squareSideLength, squareSideLength), groundMaterial);
    ground.position.y = -50.0;
    ground.rotation.x = -90.0 * PI / 180;
    return ground;
  }

  static Mesh makeSkyboxMesh(double squareSideLength, Texture texture) {
    Material material = new MeshBasicMaterial(map: texture);
    return new Mesh(new PlaneGeometry(squareSideLength, squareSideLength), material);
  }

  static List<Mesh> _generateSkybox(double squareSideLength, String path, {int bottomColor: 0x000000}) {
    Texture backTexture = loadTexture(path + "_back.jpg");
    Mesh wallBack = makeSkyboxMesh(squareSideLength, backTexture);
    wallBack.position.z = squareSideLength / 2;
    wallBack.rotation.x = PI;
    Texture frontTexture = loadTexture(path + "_front.jpg");
    Mesh wallFront = makeSkyboxMesh(squareSideLength, frontTexture);
    wallFront.position.z = -squareSideLength / 2;
    wallFront.rotation.z = PI;
    Texture leftTexture = loadTexture(path + "_left.jpg");
    Mesh wallLeft = makeSkyboxMesh(squareSideLength, leftTexture);
    wallLeft.rotation.y = 3 * PI / 2;
    wallLeft.position.x = squareSideLength / 2;
    wallLeft.rotation.x = PI;
    Texture rightTexture = loadTexture(path + "_right.jpg");
    Mesh wallRight = makeSkyboxMesh(squareSideLength, rightTexture);
    wallRight.rotation.y = PI / 2;
    wallRight.position.x = -squareSideLength / 2;
    wallRight.rotation.x = PI;
    Material bottomMaterial = new MeshBasicMaterial(color: bottomColor);
    Mesh wallBottom = new Mesh(new PlaneGeometry(squareSideLength, squareSideLength), bottomMaterial);
    //  Texture topTexture = loadTexture(path + "_top.jpg");
    //  Mesh wallTop = makeSkyboxMesh(squareSideLength, topTexture);
    wallBottom.rotation.x = -PI / 2;
    wallBottom.position.y = -squareSideLength / 2;
    return [wallBack, wallFront, wallLeft, wallRight, wallBottom];
  }

  static Mesh _generateSea(double squareSideLength) {
    Texture texture = loadTexture('water.jpg');
    //texture.wrapS = texture.wrapT = RepeatWrapping;
    MeshBasicMaterial groundMaterial = new MeshBasicMaterial();
    groundMaterial.map = texture;//map : texture);
    Mesh ground = new Mesh(new PlaneGeometry(squareSideLength, squareSideLength), groundMaterial);
    ground.position.y = -55.0;
    ground.rotation.x = -90.0 * PI / 180;
    return ground;
  }

  static List<Mesh> _generateBubblyWalls(double squareSideLength) {
    return _makeAndPlaceWalls(_generateBubblyWall, squareSideLength);
  }

  static Mesh _generateBubblyWall(double squareSideLength) {
    Texture texture = loadTexture('bubbles.jpg');
    /*   Texture texture = loadTexture('blue_coal.png');
    texture.wrapS = texture.wrapT = RepeatWrapping;
    texture.repeat.setValues(8.0,  8.0); */
    texture.generateMipmaps = false;
    MeshBasicMaterial wallMaterial = new MeshBasicMaterial();
    //  MeshBasicMaterial wallMaterial = new MeshBasicMaterial(side: DoubleSide);
    wallMaterial.map = texture;
    Mesh wall = new Mesh(new PlaneGeometry(squareSideLength, squareSideLength), wallMaterial);
    return wall;
  }

  static Vector3 _generateSpawningLocationForSimpleSquareStage(double SQUARESTAGEWIDTH) {
    double x = Stage.random.nextDouble() * SQUARESTAGEWIDTH;
    x = x - SQUARESTAGEWIDTH / 2;
    double z = Stage.random.nextDouble() * SQUARESTAGEWIDTH;
    z = z - SQUARESTAGEWIDTH / 2;
    return new Vector3(x, 0.0, z);
  }

  static void _positionPlayersOnCornersOfSquareStage(List<RealisticMovementPlayer> players, double SQUARESTAGEWIDTH) {
    if (players.length == 0) {
      return;
    }
    players[0].position.x = SQUARESTAGEWIDTH * .125;
    players[0].position.z = -SQUARESTAGEWIDTH * .125;
    players[0].rotationAngleDegrees = -90.0;
    if (players.length == 1) {
      return;
    }
    players[1].position.x = -SQUARESTAGEWIDTH * .125;
    players[1].position.z = SQUARESTAGEWIDTH * .125;
    players[1].rotationAngleDegrees = 90.0;
    if (players.length == 2) {
      return;
    }
    players[2].position.x = SQUARESTAGEWIDTH * .125;
    players[2].position.z = SQUARESTAGEWIDTH * .125;
    players[2].rotationAngleDegrees = -90.0;
    if (players.length == 3) {
      return;
    }
    players[3].position.x = -SQUARESTAGEWIDTH * .125;
    players[3].position.z = -SQUARESTAGEWIDTH * .125;
    players[3].rotationAngleDegrees = 90.0;
  }

  static List<Mesh> _makeAndPlaceWalls(MakePlaneFunction makePlane, double squareSideLength) {
    Mesh wallBack = makePlane(squareSideLength);
    wallBack.position.z = squareSideLength / 2;
    //wallBack.rotation.x = PI;
    Mesh wallFront = makePlane(squareSideLength);
    wallFront.position.z = -squareSideLength / 2;
    // wallFront.rotation.x = PI;
    Mesh wallLeft = makePlane(squareSideLength);
    wallLeft.rotation.y = 3 * PI / 2;
    wallLeft.position.x = squareSideLength / 2;
    Mesh wallRight = makePlane(squareSideLength);
    wallRight.rotation.y = PI / 2;
    wallRight.position.x = -squareSideLength / 2;
    return [wallBack, wallFront, wallLeft, wallRight];
  }

  static Object3D makeFence(double squareStageWidth, Texture squareTexture, {double heightWidthRatio: 40.0}) {
    MeshBasicMaterial fenceMaterial = new MeshBasicMaterial(side: DoubleSide);
    fenceMaterial.map = squareTexture;
    Geometry fenceGeometry = new PlaneGeometry(squareStageWidth, squareStageWidth / heightWidthRatio);
    fenceGeometry.faceVertexUvs[0][0] = [new UV(0.0, 0.0), new UV(0.0, 1.0 / heightWidthRatio), new UV(1.0, 1.0 / heightWidthRatio), new UV(1.0, 0.0)];
    Mesh fence = new Mesh(fenceGeometry, fenceMaterial);
    return fence;
  }

  static Light _generateDefaultLight() {
    DirectionalLight light = new DirectionalLight(0xFFFFFF, 0.5);
    light.position = new Vector3(0.0, 1.0, 1.0);
    return light;
  }

  static Mesh _generateSky(double squareSideLength) {
    Texture texture = loadTexture('clouds.jpg');
    texture.generateMipmaps = false;
    MeshBasicMaterial skyMaterial = new MeshBasicMaterial(side: DoubleSide);
    skyMaterial.map = texture;
    Mesh sky = new Mesh(new PlaneGeometry(squareSideLength, squareSideLength), skyMaterial);
    return sky;
  }

  static List<Mesh> _generateSkyMeshes(squareSideLength) {
    return _makeAndPlaceWalls(_generateSky, squareSideLength);
  }

}
