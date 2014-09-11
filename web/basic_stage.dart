part of stage;

class BasicStage extends Stage {

  static const double _SQUARESTAGEWIDTH = 3000.0;
  static const double _SPAWNINGREGIONWIDTH = _SQUARESTAGEWIDTH * 9/10;
  static const double _ENVIRONMENTWIDTH = _SQUARESTAGEWIDTH * 2.0;

  final bool simpleGraphics;
  final Scene scene;

  List<Object3D> startingModels = [];
  DeathPillar _deathPillar;
  List<Function> updateActions = [];

  BasicStage(this.scene, {this.simpleGraphics: false}) {
    _generateStartingModelsAndDeathPillars(simpleGraphics);
  }

  Vector3 generateSpawningLocation() {
    double x = Stage.random.nextDouble() * _SPAWNINGREGIONWIDTH;
    x = x - _SPAWNINGREGIONWIDTH / 2;
    double z = Stage.random.nextDouble() * _SPAWNINGREGIONWIDTH;
    z = z - _SPAWNINGREGIONWIDTH / 2;
    return new Vector3(x, 0.0, z);
  }

  void positionPlayersAppropriately(List<RealisticMovementPlayer> players) {
    if (players.length == 0) {
      return;
    }
    players[0].position.x = _SQUARESTAGEWIDTH * .25;
    players[0].position.z = -_SQUARESTAGEWIDTH * .25;
    players[0].rotationAngleDegrees = -90.0;
    if (players.length == 1) {
      return;
    }
    players[1].position.x = -_SQUARESTAGEWIDTH * .25;
    players[1].position.z = _SQUARESTAGEWIDTH * .25;
    players[1].rotationAngleDegrees = 90.0;
    if (players.length == 2) {
      return;
    }
    players[2].position.x = _SQUARESTAGEWIDTH * .25;
    players[2].position.z = _SQUARESTAGEWIDTH * .25;
    players[2].rotationAngleDegrees = -90.0;
    if (players.length == 3) {
      return;
    }
    players[3].position.x = -_SQUARESTAGEWIDTH * .25;
    players[3].position.z = -_SQUARESTAGEWIDTH * .25;
    players[3].rotationAngleDegrees = 90.0;

  }

  void handleBulletWorldInteraction(List<Bullet> bullets) {
    List<Bullet> toRemove = bullets.where((bullet) => bullet.outOfBounds(_SQUARESTAGEWIDTH) ||
        bullet.checkDeathPillarCollision(_deathPillar)).toList(growable : false);
    for (Bullet bullet in toRemove) {
        scene.remove(bullet);
        bullets.remove(bullet);
      }
  }

  void handlePlayerWorldInteraction(List<RealisticMovementPlayer> players, Duration d) {
    for (RealisticMovementPlayer player in players) {
      player.bounceWithinBoundaryBox(_SQUARESTAGEWIDTH);
        if (player.checkDeathPillarCollisionAndBounceAppopriately(_deathPillar)) {
          player.hit();
        }
      }
    }

  void _generateStartingModelsAndDeathPillars(bool simpleGraphics) {
    for (Mesh mesh in Stage._generateWalls(_SQUARESTAGEWIDTH)) {
      startingModels.add(mesh);
    }
    for (Mesh mesh in Stage._generateSkyMeshes(_ENVIRONMENTWIDTH)) {
      startingModels.add(mesh);
    }
    startingModels.add(Stage._generateGround(_SQUARESTAGEWIDTH));
    startingModels.add(Stage._generateSea(_ENVIRONMENTWIDTH));
    DirectionalLight light = new DirectionalLight(0xFFFFFF, 0.5);
    light.position = new Vector3(0.0, 1.0, 1.0);
    startingModels.add(light);
    _deathPillar = new DeathPillar(height: _SQUARESTAGEWIDTH / 14, radius: _SQUARESTAGEWIDTH / 7, spikey: !simpleGraphics);
    startingModels.add(_deathPillar);
  }
}
