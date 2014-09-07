part of stage;

class TestStage extends Stage {

  static final double _SQUARESTAGEWIDTH = 10000.0;
  static final double _SPAWNINGREGIONWIDTH = _SQUARESTAGEWIDTH * 9 / 10;
  static final double _ENVIRONMENTWIDTH = _SQUARESTAGEWIDTH * 2.0;

  List<Object3D> startingModels = [];
  List<Function> updateActions = [];
  List<LightningField> lightningFields = [];
  List<FireballLine> fireballLines = [];

  Scene scene;

  TestStage(this.scene) {
    _generateStartingModels();
    _registerUpdateAction(updateLightningFields);
  }

  Vector3 generateSpawningLocation() {
    double x = Stage.random.nextDouble() * _SPAWNINGREGIONWIDTH;
    x = x - _SPAWNINGREGIONWIDTH / 2;
    double z = Stage.random.nextDouble() * _SPAWNINGREGIONWIDTH;
    z = z - _SPAWNINGREGIONWIDTH / 2;
    return new Vector3(x, 0.0, z);
  }

  updateLightningFields(Duration d) {
    for (LightningField lightningField in lightningFields) {
      lightningField.update(d);
    }
    for (FireballLine fireball in fireballLines) {
      fireball.update(d);
    }
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
    List<Bullet> toRemove = bullets.where((bullet) => bullet.outOfBounds(_SQUARESTAGEWIDTH)).toList(growable: false);
    for (Bullet bullet in toRemove) {
      scene.remove(bullet);
      bullets.remove(bullet);
    }
  }

  void handlePlayerWorldInteraction(List<RealisticMovementPlayer> players, Duration d) {
    for (RealisticMovementPlayer player in players) {
        player.bounceWithinBoundaryBox(_SQUARESTAGEWIDTH);
        for (FireballLine fireballLine in fireballLines) {
          if (fireballLine.checkPlayerCollision(player)) {
            player.handleFireLineCollision();
          }
        }
    }
  }

  void handlePlayerLightningFieldInteraction(List<RealisticMovementPlayer> players) {
    for (RealisticMovementPlayer player in players) {
      for (LightningField lightningField in lightningFields) {
        print(player.checkLightningFieldCollision(lightningField).toString());
      }
    }
  }

  void _generateStartingModels() {
    for (Mesh mesh in Stage._generateBubblyWalls(_SQUARESTAGEWIDTH)) {
      startingModels.add(mesh);
    }
    for (Mesh mesh in Stage._generateSkyMeshes(_ENVIRONMENTWIDTH)) {
      startingModels.add(mesh);
    }
    for (int i = 0; i < 3; i++) {
      FireballLine myFireballLine = new FireballLine();
      myFireballLine.rotation.y += i * 2 * PI / 3;
      fireballLines.add(myFireballLine);
      startingModels.add(myFireballLine);
    }
    startingModels.add(Stage._generateGround(_SQUARESTAGEWIDTH));
    startingModels.add(Stage._generateSea(_ENVIRONMENTWIDTH));
    DirectionalLight light = new DirectionalLight(0xFFFFFF, 0.5);
    light.position = new Vector3(0.0, 1.0, 1.0);
    startingModels.add(light);
  /*  LightningField lightningField = new LightningField(minimumY : 0.0,
        minimumX : -1.0, maximumX : 1.0, maximumY: 150.0);
    startingModels.add(lightningField);
    lightningFields.add(lightningField); */
  }
}
