part of stage;

class FallingPlayerAnimation extends BasicAnimation {

  static const double GRAVITY = 0.00098;
  RealisticMovementPlayer fallingPlayer;

  FallingPlayerAnimation(this.fallingPlayer, double floorYPosition) : super.withNothingInitialized() {
    updateFunction = (duration) {
      Vector3 oldVelocity = fallingPlayer.computeTotalVelocity();
      oldVelocity.y += GRAVITY * duration.inMilliseconds;
      /* Yes, players move equal to their negative velocity, for silly reasons */
      fallingPlayer.setVelocity(oldVelocity);
    };
    test = () => fallingPlayer.torso.getDiskWorldPosition().y + PlayerTorso.TORSO_HEIGHT < floorYPosition;
  }
}

class LavaDeathStage extends Stage {

  static const double SQUARE_STAGE_WIDTH = 5000.0;
  static const double ENVIRONMENT_WIDTH = 12800.0;
  static const double LAVA_POOL_Y_COORDINATE = -ENVIRONMENT_WIDTH / 2;
  static final Texture floorTexture = loadTexture("lava-stage-textures/Lava_texture_by_Twister10.jpg");
  static final Texture wallTexture = loadTexture("lava-stage-textures/william_wall_01_S.png");
  /* The fact that the lava pool texture is static means
   * that animating one will animate all, for every instance
   * of the LavaDeathStage class. Since there are no intentions
   * of instantiating more than one instance of this class
   * at once, I deemed that acceptable, and having this texture
   * be static makes initialization of other fields (such
   * as the starting models) more straightforward.
    */
  static final Texture lavaPoolTexture = loadTexture("lava-stage-textures/lava.jpg");
  final bool walls;
  List<FallingPlayerAnimation> fallingPlayerAnimations = new List<FallingPlayerAnimation>();
  final Scene scene;

  List<UpdateAction> updateActions = [];
  List<FireballLine> fireballLines = generateFireballLines();
  List<Object3D> _startingModelsSansFireballs = generateStartingModelsSansFireballs();

  List<Object3D> get startingModels {
    return new List.from(_startingModelsSansFireballs)..addAll(fireballLines);
  }

  LavaDeathStage(this.scene, {this.walls: false}) {
    lavaPoolTexture.needsUpdate = true;
    lavaPoolTexture.wrapS = lavaPoolTexture.wrapT = RepeatWrapping;
    wallTexture.wrapS = wallTexture.wrapT = RepeatWrapping;
    wallTexture.repeat.setValues(2.0, 2.0);
    wallTexture.needsUpdate = true;
    if (walls) {
      _startingModelsSansFireballs.addAll(Stage._makeAndPlaceWalls(makeStoneFence, SQUARE_STAGE_WIDTH));
    }
    _registerUpdateAction(_updateFireballLines);
    _registerUpdateAction(_updateLavaPool);
  }

  void positionPlayersAppropriately(List<RealisticMovementPlayer> players) {
    Stage._positionPlayersOnCornersOfSquareStage(players, SQUARE_STAGE_WIDTH);
  }

  Vector3 generateSpawningLocation() {
    return Stage._generateSpawningLocationForSimpleSquareStage(SQUARE_STAGE_WIDTH);
  }

  void _updateFireballLines(Duration duration) {
    FireballLine.update(duration);
    for (FireballLine fireballLine in fireballLines) {
      fireballLine.rotation.y += duration.inMilliseconds * 0.0005;
    }
  }

  void _updateLavaPool(Duration duration) {
    lavaPoolTexture.offset.y = lavaPoolTexture.offset.y - (duration.inMilliseconds * 0.00001);
    lavaPoolTexture.offset.x = lavaPoolTexture.offset.x - (duration.inMilliseconds * 0.00001);
  }

  Iterable<RealisticMovementPlayer> get fallingPlayers {
    return fallingPlayerAnimations.map((animation) => animation.fallingPlayer);
  }

  void handlePlayerWorldInteraction(List<RealisticMovementPlayer> players, Duration duration) {
    List<FallingPlayerAnimation> toRemove = new List<FallingPlayerAnimation>();
    for (FallingPlayerAnimation animation in fallingPlayerAnimations) {
      animation.update(duration);
      if (animation.done) {
        animation.fallingPlayer.dead = true;
        toRemove.add(animation);
      }
    }
    toRemove.forEach((animation) => fallingPlayerAnimations.remove(animation));
    for (RealisticMovementPlayer player in players) {
      if (fallingPlayers.contains(player)) {
        continue;
      }
      for (FireballLine fireballLine in fireballLines) {
        if (fireballLine.checkPlayerCollision(player)) {
          player.handleFireLineCollision();
          break;
        }
      }
      if (walls) {
        player.bounceWithinBoundaryBox(SQUARE_STAGE_WIDTH);
      } else {
        if (player.overEdgeOfSquare(SQUARE_STAGE_WIDTH)) {
          fallingPlayerAnimations.add(new FallingPlayerAnimation(player, LAVA_POOL_Y_COORDINATE));
          player.incapacitatedDueToMessingWithStage = true;
        }
      }
    }
  }

  void handleBulletWorldInteraction(List<Bullet> bullets) {
    List<Bullet> toRemove = bullets.where((bullet) => bullet.outOfBounds(SQUARE_STAGE_WIDTH)).toList(growable: false);
    for (Bullet bullet in toRemove) {
      scene.remove(bullet);
      bullets.remove(bullet);
    }
  }

  static Object3D makeVolcanoCylinder(double environmentWidth) {
    double cylinderRadius = environmentWidth / 2;
    // height is set equal to circumference so that square texture looks nice
    double cylinderHeight = cylinderRadius * 2 * PI;
    MeshBasicMaterial wallMaterial = new MeshBasicMaterial(side: DoubleSide);
    wallMaterial.map = wallTexture;
    Geometry geometry = new CylinderGeometry(cylinderRadius, cylinderRadius, cylinderHeight, 20, 4, true);
    return new Mesh(geometry, wallMaterial);
  }

  static Object3D makeStoneFence(double squareStageWidth) {
    return Stage.makeFence(squareStageWidth, wallTexture, heightWidthRatio: 40.0);
  }

  static Object3D makeLavaPool() {
    MeshBasicMaterial poolMaterial = new MeshBasicMaterial(side: DoubleSide);
    poolMaterial.map = lavaPoolTexture;
    Geometry geometry = new PlaneGeometry(ENVIRONMENT_WIDTH, ENVIRONMENT_WIDTH);
    Mesh pool = new Mesh(geometry, poolMaterial);
    pool.rotation.x = -PI / 2;
    pool.position.y = LAVA_POOL_Y_COORDINATE;
    return pool;
  }

  static List<FireballLine> generateFireballLines() {
    List<FireballLine> toReturn = new List<FireballLine>();
    int fireballCount = (SQUARE_STAGE_WIDTH ~/ 2) ~/ Fireball.radius;
    int twoEleventhsPoint = fireballCount * 2 ~/ 11;
    int fiveEleventhsPoint = fireballCount * 5 ~/ 11;
    int sevenEleventhsPoint = fireballCount * 7 ~/ 11;
    int tenEleventhsPoint = fireballCount * 10 ~/ 11;
    Iterable<int> twoToFive = new Iterable.generate(fiveEleventhsPoint - twoEleventhsPoint, (e) => twoEleventhsPoint + e);
    Iterable<int> sevenToTen = new Iterable.generate(tenEleventhsPoint - sevenEleventhsPoint, (e) => sevenEleventhsPoint + e);
    Set<int> toSkip = twoToFive.toSet().union(sevenToTen.toSet());
    for (int i = 0; i < 3; i++) {
      FireballLine myFireballLine = new FireballLine(fireballCount: fireballCount, toSkip: toSkip);
      myFireballLine.rotation.y += i * 2 * PI / 3;
      toReturn.add(myFireballLine);
    }
    return toReturn;
  }

  static List<Object3D> generateStartingModelsSansFireballs() {
    List<Object3D> toReturn = new List<Object3D>();
    toReturn.add(makeVolcanoCylinder(ENVIRONMENT_WIDTH));
    toReturn.add(Stage._generateGround(SQUARE_STAGE_WIDTH, texture: floorTexture));
    toReturn.add(makeLavaPool());
    toReturn.add(Stage._generateDefaultLight());
    return toReturn;
  }

}
