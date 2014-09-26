part of stage;

class LightningFieldManager extends AnimationTimeline {

  static final Duration lightningCallLength = new Duration(seconds: 10);

  Scene scene;
  DeathPillar firstTessla;
  DeathPillar secondTessla;
  LightningField lightningField;

  Animation generateFlickerAnimation() {
    Animation flickerUpAnimation = new BasicAnimation.withTestFunction(flickerUp, maxLightness);
    Animation flickerDownAnimation = new BasicAnimation.withTestFunction(flickerDown, minLightness);
    AnimationTimeline flickerAnimation = new AnimationTimeline(animations: [flickerUpAnimation, flickerDownAnimation], maxRepeats: 3);
    flickerAnimation.cleanup = cleanupFlickerPhase;
    return flickerAnimation;
  }

  bool maxLightness() {
    return firstTessla.material.color.HSL[2] >= 1.0;
  }

  bool minLightness() {
    return firstTessla.material.color.HSL[2] <= 0.0;
  }

  void adjustLightness(double offset) {
    List<double> hsl = firstTessla.material.color.HSL;
    double newLightness = hsl[2] + offset;
    firstTessla.material.color.setHSL(hsl[0], hsl[1], newLightness);
    secondTessla.material.color.setHSL(hsl[0], hsl[1], newLightness);
  }

  void flickerUp(Duration duration) {
    adjustLightness(duration.inMilliseconds * .001);
  }

  void flickerDown(Duration duration) {
    adjustLightness(duration.inMilliseconds * -.001);
  }

  void cleanupFlickerPhase() {
    firstTessla.material.color = DeathPillar.generateMaterial().color;
    secondTessla.material.color = DeathPillar.generateMaterial().color;
    lightningField = new LightningField(minimumX: min(firstTessla.position.x, secondTessla.position.x),
        maximumX: max(firstTessla.position.x, secondTessla.position.x),
        minimumY: firstTessla.getDiskWorldPosition().y - firstTessla.height / 2,
        maximumY: firstTessla.getDiskWorldPosition().y + firstTessla.height / 2,
        minimumZ: min(firstTessla.position.z, secondTessla.position.z),
        maximumZ: max(firstTessla.position.z, secondTessla.position.z));
    scene.add(lightningField);
  }

  void cleanupLightningCallPhase() {
    scene.remove(lightningField);
    lightningField = null;
    firstTessla = null;
    secondTessla = null;
  }

  LightningFieldManager(this.firstTessla, this.secondTessla, this.scene) {
    Animation flickerAnimation = generateFlickerAnimation();
    Animation callingLightning = new BasicAnimation((duration) => lightningField.update(duration), lightningCallLength);
    callingLightning.cleanup = cleanupLightningCallPhase;
    animations = [flickerAnimation, callingLightning];
  }
}

class NinePillarStage extends Stage {

  static const double _SQUARESTAGEWIDTH = 8000.0;
  static const double _SPAWNINGREGIONWIDTH = _SQUARESTAGEWIDTH * 19.0 / 20.0;
  static const double _ENVIRONMENTWIDTH = _SQUARESTAGEWIDTH * 1.5;
  static final Texture cloudTexture = generateCloudTexture();

  static final Duration timeBetweenLightningCalls = new Duration(seconds: 5);

  final bool simpleGraphics;
  final bool pillarsMove;
  final Scene scene;

  AnimationTimeline callLightningAnimation;
  List<LightningFieldManager> lightningFieldManagers = [];

  List<Object3D> startingModels = [];
  List<DeathPillar> _deathPillars = [];
  List<Function> updateActions = [];

  List<LightningField> get lightningFields {
    return lightningFieldManagers.where((manager) => manager.lightningField != null).map((manager) => manager.lightningField).toList(growable: false);
  }

  NinePillarStage(this.scene, {this.simpleGraphics: false, this.pillarsMove: false}) {
    _generateStartingModelsAndDeathPillars(pillarsMove: pillarsMove);
    if (pillarsMove) {
      _registerUpdateAction(_updatePillars);
    } else {
      callLightningAnimation = generateCallLightningAnimation();
      _registerUpdateAction(callLightningAnimation.update);
    }
  }

  static Texture generateCloudTexture() {
    Texture toReturn = loadTexture("nine-pillar-stage-textures/rsz_1cloud--texture-3.jpg");
    toReturn.wrapS = toReturn.wrapT = MirroredRepeatWrapping;
    toReturn.repeat.setValues(10.0, 10.0);
    return toReturn;
  }

  void setupLightningFieldManagers() {
    List<int> tesslaIndexes = new Iterable.generate(_deathPillars.length).toList(growable: true);
    for (int i in new Iterable.generate(7)) {
      int currentTesslaIndex = tesslaIndexes[Stage.random.nextInt(tesslaIndexes.length - 1)];
      tesslaIndexes.remove(currentTesslaIndex);
      DeathPillar firstTessla = _deathPillars[currentTesslaIndex];
      DeathPillar secondTessla = _deathPillars[getRandomNeighboringPillar(currentTesslaIndex)];
      lightningFieldManagers.add(new LightningFieldManager(firstTessla, secondTessla, scene));
    }
  }

  void callingLightning(Duration duration) {
    List<LightningFieldManager> toRemove = new List<LightningFieldManager>();
    for (LightningFieldManager manager in lightningFieldManagers) {
      manager.update(duration);
      if (manager.done) {
        toRemove.add(manager);
      }
    }
    for (LightningFieldManager manager in toRemove) {
      lightningFieldManagers.remove(manager);
    }
  }

  bool lightningOver() {
    return lightningFieldManagers.length == 0;
  }

  AnimationTimeline generateCallLightningAnimation() {
    BasicAnimation pause = new BasicAnimation(Animation.emptyUpdateFunction, timeBetweenLightningCalls);
    pause.cleanup = setupLightningFieldManagers;
    BasicAnimation callingLightningPhase = new BasicAnimation.withTestFunction(callingLightning, lightningOver);
    AnimationTimeline callLightningAnimation = new AnimationTimeline(animations: [pause, callingLightningPhase], maxRepeats: AnimationTimeline.REPEATINDEFINITELY);
    return callLightningAnimation;
  }

  int getRandomNeighboringPillar(int pillarIndex) {
    if (pillarIndex >= _deathPillars.length) {
      throw new Exception("Give me a pillar that is not the last!");
    }
    if (pillarIndex % 3 == 2) {
      return pillarIndex + 3;
    }
    if (pillarIndex > 5) {
      return pillarIndex + 1;
    }
    if (Stage.random.nextBool()) {
      return pillarIndex + 3;
    }
    return pillarIndex + 1;
  }


  Vector3 generateSpawningLocation() {
    return Stage._generateSpawningLocationForSimpleSquareStage(_SQUARESTAGEWIDTH);
  }


  void positionPlayersAppropriately(List<RealisticMovementPlayer> players) {
    Stage._positionPlayersOnCornersOfSquareStage(players, _SQUARESTAGEWIDTH);

  }

  void _updatePillars(Duration duration) {
    for (DeathPillar deathPillar in _deathPillars) {
      deathPillar.update(duration);
    }
  }

  void handleBulletWorldInteraction(List<Bullet> bullets) {
    List<Bullet> toRemove = bullets.where((bullet) => bullet.outOfBounds(_SQUARESTAGEWIDTH) || bullet.checkMultipleDeathPillarCollision(_deathPillars)).toList(growable: false);
    for (Bullet bullet in toRemove) {
      scene.remove(bullet);
      bullets.remove(bullet);
    }
  }

  void handlePlayerWorldInteraction(List<RealisticMovementPlayer> players, Duration duration) {
    for (RealisticMovementPlayer player in players) {
      player.bounceWithinBoundaryBox(_SQUARESTAGEWIDTH);
      for (DeathPillar deathPillar in _deathPillars) {
        if (player.checkDeathPillarCollisionAndBounceAppopriately(deathPillar)) {
          if (!player.spikey) {
            player.hit();
          }
        }
      }
      bool contactingLightningField = false;
      for (LightningField lightningField in lightningFields) {
        if (player.checkLightningFieldCollision(lightningField)) {
          player.handleLightningFieldCollision();
          contactingLightningField = true;
        }
      }
      if (!contactingLightningField) {
        player.freeFromLightningField();
      }
    }
  }

  static Object3D makeCloudFence(double squareStageWidth) {
    return Stage.makeFence(squareStageWidth, cloudTexture, heightWidthRatio: 60.0);
  }

  void _generateStartingModelsAndDeathPillars({bool pillarsMove: false}) {
    List<Mesh> skyboxMeshes = (Stage._generateSkybox(_ENVIRONMENTWIDTH * 2, "night-sky/nightsky"));
    for (Mesh mesh in skyboxMeshes) {
      mesh.position.y -= _ENVIRONMENTWIDTH / 4;
    }
    startingModels.addAll(skyboxMeshes);
    startingModels.addAll(Stage._makeAndPlaceWalls(makeCloudFence, _SQUARESTAGEWIDTH));
    startingModels.add(Stage._generateGround(_SQUARESTAGEWIDTH, texture: cloudTexture));
    DirectionalLight light = new DirectionalLight(0xFFFFFF, 0.5);
    light.position = new Vector3(0.0, 1.0, 1.0);
    startingModels.add(light);
    double pillarInterval = _SQUARESTAGEWIDTH / 4.0;
    for (int x = 0; x < 3; x += 1) {
      double xCoordinate = pillarInterval * (1 + x) - _SQUARESTAGEWIDTH / 2;
      for (int z = 0; z < 3; z += 1) {
        double zCoordinate = pillarInterval * (1 + z) - _SQUARESTAGEWIDTH / 2;
        DeathPillar toAdd;
        if (!pillarsMove) {
          toAdd = new DeathPillar(height: PlayerTorso.TORSO_RADIUS * 5, radius: PlayerTorso.TORSO_RADIUS * 5, spikesPerLevel: 10, spikey: true);
        } else {
          toAdd = new DeathPillar(height: PlayerTorso.TORSO_RADIUS * 5, radius: PlayerTorso.TORSO_RADIUS * 5, spikesPerLevel: 10, spikey: true, move: true);
        }
        toAdd.position.x = xCoordinate;
        toAdd.position.z = zCoordinate;
        _deathPillars.add(toAdd);
        startingModels.add(toAdd);
      }
    }
  }

}
