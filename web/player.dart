library player;

import 'dart:html';
import 'package:vector_math/vector_math.dart';
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart';

import 'dart:math';

import 'items.dart';
import 'keyboard.dart';
import 'obstacles.dart';
import 'animation.dart' as animation;

class RealisticMovementPlayer extends Player {
  static const TOP_SPEED = 1.0;

  final String name;
  final int leftKey;
  final int rightKey;
  final int downKey;
  final int upKey;

  double _voluntarySpeed = 0.0;
  double _rotationAngleDegrees = 0.0;
  double _involuntarySpeed = 0.0;
  Vector3 _involuntaryDirection = new Vector3(0.0, 0.0, 0.0);

  PerspectiveCamera camera;

  RealisticMovementPlayer({this.upKey: KeyCode.UP, this.rightKey: KeyCode.RIGHT, this.downKey: KeyCode.DOWN, this.leftKey: KeyCode.LEFT, this.name: 'Bob', double hue: 0.5}) : super(hue: hue) {
    this.camera = new PerspectiveCamera(65.0, 1.0, 1.0, 25000.0);
    this.add(camera);
    camera.position = new Vector3(0.0, 200.0, 300.0);
    camera.lookAt(new Vector3(0.0, 0.0, 0.0));
    _registerUpdateAction(updateActions);
  }

  factory RealisticMovementPlayer.fromMap(Map playerMap) {
    String name = playerMap['name'];
    int leftKey = playerMap['left'];
    int rightKey = playerMap['right'];
    int accelerateKey = playerMap['accelerate'];
    int reverseKey = playerMap['reverse'];
    double hue = playerMap['hue'];
    if (name == null || leftKey == null || rightKey == null || accelerateKey == null || reverseKey == null || hue == null) {
      // print("Null value found, raising an exception!");
      throw "Null value in player map";
    } else {
      // print("Let's initialize a new player!");
      RealisticMovementPlayer toReturn = new RealisticMovementPlayer(name: name, upKey: accelerateKey, rightKey: rightKey, downKey: reverseKey, leftKey: leftKey, hue: hue);
      // print("New player initialized! About to return him.");
      return toReturn;
    }
  }

  Map get startingConfigurationMap => {'name' : name, 'left' : leftKey, 'right' : rightKey, 'reverse' : downKey, 'accelerate' : upKey, 'hue' : material.color.HSL[0]};

  /**
   * The rotation angle occasionally needs to be set or read from outside,
   * so it is not private. For instance, the stage may need to
   * change the player orientation when placing the player
   * in his or her starting position
   */
  void set rotationAngleDegrees(double newRotationAngleDegrees) {
    rotation.y = newRotationAngleDegrees * PI / 180.0;
    _rotationAngleDegrees = newRotationAngleDegrees;
  }

  double get rotationAngleDegrees {
    return _rotationAngleDegrees;
  }

  Vector3 computeDirectionVector() {
    double movementZ = cos(rotationAngleDegrees * PI / 180.0);
    double movementX = sin(rotationAngleDegrees * PI / 180.0);
    return new Vector3(movementX, 0.0, movementZ);
  }

  Vector3 computeInvoluntaryVelocity() {
    Vector3 involuntaryDirectionCopy = new Vector3.copy(_involuntaryDirection);
    involuntaryDirectionCopy.multiply(new Vector3.all(_involuntarySpeed));
    return involuntaryDirectionCopy;
  }

  Vector3 computeVoluntaryVelocity() {
    Vector3 voluntaryDirection = computeDirectionVector();
    voluntaryDirection.multiply(new Vector3.all(_voluntarySpeed));
    return voluntaryDirection;
  }

  Vector3 computeTotalVelocity() {
    Vector3 involuntaryVelocity = computeInvoluntaryVelocity();
    Vector3 voluntaryVelocity = computeVoluntaryVelocity();
    voluntaryVelocity.add(involuntaryVelocity);
    return voluntaryVelocity;
  }

  double computeTotalSpeed() {
    return computeTotalVelocity().length;
  }

  void setVelocity(Vector3 newVelocity) {
    this._voluntarySpeed = 0.0;
    this._involuntarySpeed = newVelocity.length;
    this._involuntaryDirection = newVelocity.normalized();
  }

  void bounceWithinBoundaryBox(final double boxSideLength) {
    bool bounceX = false;
    bool bounceZ = false;
    if (position.x + Player.ROLLING_PART_RADIUS >= boxSideLength / 2) {
      position.x = boxSideLength / 2 - Player.ROLLING_PART_RADIUS;
      bounceX = true;
    } else if (position.x - Player.ROLLING_PART_RADIUS <= -boxSideLength / 2) {
      position.x = -boxSideLength / 2 + Player.ROLLING_PART_RADIUS;
      bounceX = true;
    }
    if (position.z + Player.ROLLING_PART_RADIUS >= boxSideLength / 2) {
      position.z = boxSideLength / 2 - Player.ROLLING_PART_RADIUS;
      bounceZ = true;
    } else if (position.z - Player.ROLLING_PART_RADIUS <= -boxSideLength / 2) {
      position.z = -boxSideLength / 2 + Player.ROLLING_PART_RADIUS;
      bounceZ = true;
    }
    if (bounceX || bounceZ) {
      Vector3 totalVelocity = computeTotalVelocity();
      if (bounceX) {
        totalVelocity.x = -totalVelocity.x;
      }
      if (bounceZ) {
        totalVelocity.z = -totalVelocity.z;
      }
      setVelocity(totalVelocity);
    }
  }

  /**
   * Updates involuntary component of velocity following
   * collision with an object of a particular velocity
   * and mass. */
  void impact(Vector3 colliderVelocity, double colliderMass) {
    double massRatio = colliderMass / Player.MASS;
    Vector3 currentInvoluntaryVelocity = computeInvoluntaryVelocity();
    currentInvoluntaryVelocity.add(colliderVelocity * massRatio);
    _involuntaryDirection = currentInvoluntaryVelocity.normalized();
    _involuntarySpeed = currentInvoluntaryVelocity.length;
  }

  /**
   * Handles contact with a [LightningField] object.
   *
   * Damages this player, freezes it, and
   * sets an internal flag to indicate
   * that it is trapped by lightning.
   * If that flag is already set,
   * this function does nothing.
   * While the flag is set, the player
   * will not be able to move, and
   * will spin helplessly instead.
   * Call [freeFromLightningField]
   * to restore freedom of movement
   * to the player when the player
   * is no longer in contact with
   * the lightning field. Both of
   * these methods will probably
   * be called by an implementation
   * of the [handlePlayerWorldInteraction]
   * method of the abstract [Stage] class.
     */
  void handleLightningFieldCollision() {
    if (!_entrappedByLightning) {
      hit();
      _freeze();
      _entrappedByLightning = true;
    }
  }

  /**
   * Tells this player that it is no longer in contact with a [LightningField].
   *
   * This function will probably be called by an implementation of the [handlePlayerWorldInteraction]
   * method of the abstract [Stage] class. */
  void freeFromLightningField() {
    _entrappedByLightning = false;
  }

  /**
   * Returns true and changes velocity and position appropriately if this player is in contact with [pillar].
   *
   * The voluntary component of this player's velocity is set to 0,
   * and it is given a new involuntary velocity with a speed
   * equal to its previous total speed and a direction corresponding
   * to the orientation of the spike of [pillar] with which it collided.
   *
   * If [pillar] was not in motion, this player's new speed
   * is given a slight boost to make sure that a situation
   * never arises in which a stationary player comes to be in contact
   * with a stationary [DeathPillar] and the looped call to [budge]
   * used to extricate the player from this contact never terminates.
   *
   * If [pillar] was in motion, the velocity of [pillar] is added
   * to the new involuntary velocity, with no regard for the mass
   * of the pillar (so the [impact] method does not need to be called here).
   */
  bool checkDeathPillarCollisionAndBounceAppopriately(DeathPillar pillar) {
    if (_touchingPillar(pillar)) {
      Vector3 currentPosition = new Vector3.copy(this.position);
      currentPosition.sub(pillar.position);
      double totalSpeed = computeTotalSpeed();
      if (!pillar.move) {
        totalSpeed += 0.1;
      }
      Vector3 normalizedImpactVector = currentPosition.normalized();
      normalizedImpactVector.multiply(new Vector3.all(-totalSpeed));
      if (pillar.move) {
        normalizedImpactVector.addScaled(pillar.movementAxis, -pillar.movementSpeed);
      }
      setVelocity(normalizedImpactVector);
      while (_touchingPillar(pillar)) {
        budge();
      }
      return true;
    }
    return false;
  }


  void updateCameraAspectRatio(double aspectRatio) {
    camera.aspect = aspectRatio;
    camera.updateProjectionMatrix();
  }

  void updateActions(Keyboard board, Duration elapsedTime) {
    if (_entrappedByLightning) {
      rotationAngleDegrees += 0.05 * elapsedTime.inMilliseconds;
    } else if (!incapacitatedDueToMessingWithStage && !_swellingDueToImminentDeath) {
      _processKeyboardInputs(board, elapsedTime);
    }
    // this.rotation.y = rotationAngleDegrees * PI / 180.0;
    _handleFriction(elapsedTime);
    _move(elapsedTime);
  }

  void _processKeyboardInputs(Keyboard board, Duration elapsedTime) {
    if (board.isDown(upKey)) {
      _voluntarySpeed += 0.001 * elapsedTime.inMilliseconds;
      if (_voluntarySpeed > TOP_SPEED) {
        _voluntarySpeed = TOP_SPEED;
      }
    }
    if (board.isDown(downKey)) {
      _voluntarySpeed -= 0.001 * elapsedTime.inMilliseconds;
      if (_voluntarySpeed < -TOP_SPEED) {
        _voluntarySpeed = -TOP_SPEED;
      }
    }
    if (board.isDown(leftKey)) {
      rotationAngleDegrees += 0.1 * elapsedTime.inMilliseconds;
    }
    if (board.isDown(rightKey)) {
      rotationAngleDegrees -= 0.1 * elapsedTime.inMilliseconds;
    }
  }

  void _move(Duration elapsedTime) {
    Vector3 totalVelocity = computeTotalVelocity();
    this.position.addScaled(totalVelocity, -elapsedTime.inMilliseconds.toDouble());
    /*
    Vector3 directionVector = computeDirectionVector();
    double multiple = _voluntarySpeed * elapsedTime.inMilliseconds;
    this.position.addScaled(directionVector, -multiple);
    double involuntaryMultiple = _involuntarySpeed * elapsedTime.inMilliseconds;
    this.position.addScaled(_involuntaryDirection, -involuntaryMultiple); */
  }

  /**
   * Moves this player very slightly, according to current velocity.
   *
   * This function should be called in a loop when this player
   * is in contact with some object with which it cannot share space.
   * The condition for the termination of the loop should be the
   * ceasing of contact. Before entering such a loop, this player's
   * velocity should be set so that it is moving away from the object
   * with which it is in contact, rather than towards it */
  void budge() {
    _move(new Duration(milliseconds: 1));
  }

  void _handleFriction(Duration elapsedTime) {
    /* if (_voluntarySpeed == 0.0 && _involuntarySpeed == 0) {
      return;
    } */
    _voluntarySpeed = _computeFriction(_voluntarySpeed, elapsedTime);//, frictionConstant: 0.0001);
    _involuntarySpeed = _computeFriction(_involuntarySpeed, elapsedTime);//, frictionConstant: 0.0005);
  }

  double _computeFriction(double speedParameter, Duration elapsedTime, {double frictionConstant: 0.0003}) {
    if (speedParameter > 0.0) {
      return max(speedParameter - frictionConstant * elapsedTime.inMilliseconds, 0.0);
    }
    if (speedParameter < 0.0) {
      return min(speedParameter + frictionConstant * elapsedTime.inMilliseconds, 0.0);
    }
    return speedParameter;
  }

  void _freeze() {
    this._voluntarySpeed = 0.0;
    this._involuntarySpeed = 0.0;
  }

}

class GunTurret extends Object3D {

  static const double length = Player.ROLLING_PART_RADIUS * 2.0;
  static final Material material = new MeshLambertMaterial(color: 0xFFFFFF);
  static final Geometry geometry = new CylinderGeometry(Player.ROLLING_PART_RADIUS / 5.0, Player.ROLLING_PART_RADIUS / 5.0, length);
  static final Geometry sightGeometry = new SphereGeometry();
  final Player owner;
  final Mesh mesh = new Mesh(geometry, material);
  final Mesh sight = new Mesh(sightGeometry, new MeshBasicMaterial(visible: false));

  GunTurret({this.owner: null, double radiusOfCircularObjectOnWhichPlaced: 0.0}) {
    sight.position.y = -length;
    Object3D intermediateObject3D = new Object3D();
    intermediateObject3D.add(mesh);
    intermediateObject3D.add(sight);
    intermediateObject3D.rotation.x = 90 * PI / 180;
    intermediateObject3D.position.z = -radiusOfCircularObjectOnWhichPlaced - length / 2;
    add(intermediateObject3D);
  }

  Bullet fire() {
    return new Bullet(this);
  }

  Vector3 get directionVector {
    return mesh.matrixWorld.getTranslation().sub(sight.matrixWorld.getTranslation()).normalize();
  }

  Vector3 get tipPosition {
    return sight.matrixWorld.getTranslation().clone();
  }

}

class Bullet extends Object3D {
  static const double radius = Player.ROLLING_PART_RADIUS / 2.0;
  static const double minimumSpeed = 1.0;
  static const double mass = Player.MASS / 3.0;

  final Player owner;
  Vector3 _velocity;

  Bullet(GunTurret turret) : this.owner = turret.owner {
    Material material = owner.material;
    Geometry body = new SphereGeometry(radius);
    this.add(new Mesh(body, material));
    Matrix4 matrixWorld = turret.matrixWorld;
    Vector4 rightColumn = matrixWorld.getColumn(3);
    this.position.setFrom(turret.tipPosition);
    this._velocity = turret.directionVector.clone();
    if (owner != null) {
      if (owner is RealisticMovementPlayer) {
        RealisticMovementPlayer castOwner = owner;
        _velocity.add(castOwner.computeTotalVelocity());
        if (_velocity.length < minimumSpeed) {
          _velocity.normalize();
          _velocity.multiply(new Vector3.all(minimumSpeed));
        }
      }
    }
  }

  @override
  String toString() {
    return {
      'owner': owner.toString(),
      'velocity': _velocity.toString()
    }.toString();
  }

  bool outOfBounds(double boundingBoxSideLength) {
    if (position.x.abs() > boundingBoxSideLength / 2.0) {
      return true;
    }
    if (position.z.abs() > boundingBoxSideLength / 2.0) {
      return true;
    }
    return false;
  }

  /**
   * Returns the velocity of this bullet.
   *
   * Because modifying the fields of the [Vector3] obtained this way
   * does not actually affect this bullet, I use a function
   * with "compute" in the name rather than a getter,
   * making it clear that a field of the object is not being
   * directly accessed. */
  Vector3 computeVelocity() {
    return _velocity.clone();
  }

  bool checkPlayerCollision(Player target) {
    Vector3 currentPosition = new Vector3.copy(this.position);
    Matrix4 matrixWorld = target.torso.matrixWorld;
    Vector4 rightColumn = matrixWorld.getColumn(3);
    Vector3 torsoPosition = new Vector3(rightColumn.x, rightColumn.y, rightColumn.z);
    double distance = currentPosition.sub(torsoPosition).length;
    if (distance < radius + Player.TORSO_RADIUS) {
      return true;
    }
    return false;
  }

  bool checkDeathPillarCollision(DeathPillar pillar) {
    Vector3 currentPosition = new Vector3.copy(this.position);
    currentPosition.sub(pillar.position);
    if (currentPosition.length < radius + pillar.radius) {
      return true;
    }
    return false;
  }

  bool checkMultipleDeathPillarCollision(List<DeathPillar> deathPillars) {
    for (DeathPillar deathPillar in deathPillars) {
      if (checkDeathPillarCollision(deathPillar)) {
        return true;
      }
    }
    return false;
  }

  bool checkOtherBulletCollision(Bullet other) {
    Vector3 currentPosition = new Vector3.copy(this.position);
    currentPosition.sub(other.position);
    if (currentPosition.length < radius * 2) {
      return true;
    }
    return false;
  }

  void update(Duration elapsedTime) {
    this.position.sub(computeVelocity().multiply(new Vector3.all(elapsedTime.inMilliseconds.toDouble())));
  }
}

typedef void PlayerUpdateAction(Keyboard board, Duration d);

class Player extends Object3D {
  static const ROLLING_PART_RADIUS = 50.0;
  static const SPIKE_LENGTH = ROLLING_PART_RADIUS;
  static const SPIKE_BOTTOM_RADIUS = ROLLING_PART_RADIUS / 4;
  static const SPIKE_TOP_RADIUS = ROLLING_PART_RADIUS / 40;
  static const TORSO_RADIUS = ROLLING_PART_RADIUS / 2.0;
  static const TORSO_HEIGHT = ROLLING_PART_RADIUS * 2.0;
  static const ARM_HEIGHT = ROLLING_PART_RADIUS * 1.5;
  static const MASS = 100.0;
  static const STARTING_SATURATION = 0.3;
  static const STARTING_HP = 7;
  static const TOP_SWELLING_SCALE = 3.0;

  static final Duration _tripleShootDuration = new Duration(seconds: 10);
  static final Duration _spikeyDuration = new Duration(seconds: 10);
  static final Duration _invulnerableToFireDuration = new Duration(seconds: 2);

  bool incapacitatedDueToMessingWithStage = false;
  bool _swellingDueToImminentDeath = false;
  animation.Animation swellingAnimation = null;
  bool dead = false;

  bool _entrappedByLightning = false;
  bool _tripleShoot = false;
  bool spikey = false;
  bool invulnerableToFire = false;
  int _hits = 0;
  Duration _sinceLastShot = new Duration();
  List<GunTurret> gunTurrets = [];
  List<Object3D> spikes = _generateSpikes();

  Mesh torso;
  Mesh rollingPart;
  List<PlayerUpdateAction> _updateActions = [];
  /// This material is for the torso and rolling part
  MeshLambertMaterial material;
  static final Texture burnedTexture = loadTexture("lava-stage-textures/boiled_flesh.jpg");

  /** The plain white texture deserves comment. It is completely invisible,
   * but necessary due to a quirk of how Three.dart (and Three.js) handles textures.
   * When an Object3D is first rendered with a texture, its UVs are "baked in," and
   * if it is first rendered without a texture, it becomes impossible for one to be
   * added at a later time. Because it is occasionally useful to change the texture
   * of the player after creation, as when the player is burned, it is necessary
   * to create a plain invisible texture to use for the default material
   * that is the material of the Player when it is first rendered */
  static final Texture plainWhiteTexture = _generatePlainWhiteTexture();
  /** The material of the torso and rolling part is changed to this burned material
   * temporarily when the player has touched something fiery, in order to visually
   * indicate to the player that they will be temporarily impervious to future
   * fire damage */
  static final MeshBasicMaterial burnedMaterial = new MeshBasicMaterial(map: burnedTexture);

  animation.BasicAnimation invulnerabilityToFireClock;
  animation.BasicAnimation spikinessClock;
  animation.BasicAnimation tripleShootClock;

  _registerUpdateAction(PlayerUpdateAction newAction) {
    _updateActions.add(newAction);
  }

  animation.BasicAnimation generateInvulnerabilityToFireClock() {
    animation.BasicAnimation toReturn = new animation.BasicAnimation(animation.Animation.emptyUpdateFunction, _invulnerableToFireDuration);
    toReturn.cleanup = () {
      _setMaterial(material);
      invulnerableToFire = false;
    };
    return toReturn;
  }

  animation.BasicAnimation generateSpikinessClock() {
    animation.BasicAnimation toReturn = new animation.BasicAnimation(animation.Animation.emptyUpdateFunction, _spikeyDuration);
    toReturn.cleanup = () {
      spikey = false;
      _makeNotSpikey();
    };
    return toReturn;
  }

  void grow(Duration elapsedTime) {
    double scaleFactor = 0.001 * elapsedTime.inMilliseconds;
    this.scale.setFrom(new Vector3(this.scale.x + scaleFactor, this.scale.y + scaleFactor, this.scale.z + scaleFactor));
  }

  void shrink(Duration elapsedTime) {
    double scaleFactor = 0.001 * elapsedTime.inMilliseconds;
    this.scale.setFrom(new Vector3(this.scale.x - scaleFactor, this.scale.y - scaleFactor, this.scale.z - scaleFactor));
  }

  animation.AnimationTimeline generateSwellingAnimation() {
    animation.BasicAnimation growAnimation = new animation.BasicAnimation.withTestFunction(grow, () => this.scale.x >= TOP_SWELLING_SCALE);
    animation.BasicAnimation shrinkAnimation = new animation.BasicAnimation.withTestFunction(shrink, () => this.scale.x <= 0.01);
    shrinkAnimation.cleanup = () {
      this.dead = true;
    };
    return new animation.AnimationTimeline(animations: [growAnimation, shrinkAnimation]);
  }

  animation.BasicAnimation generateTripleShootClock() {
    animation.BasicAnimation toReturn = new animation.BasicAnimation(animation.Animation.emptyUpdateFunction, _tripleShootDuration);
    toReturn.cleanup = () {
      _tripleShoot = false;
      _makeSingleShoot();
    };
    return toReturn;
  }

  /** Plain white textures (i.e., textures that do not
     * render at all and are visually equivalent to the
     * absence of a texture) presented surprising problems.
     * In particular, using a plain white texture
     * that was actually a power of two by a power of
     * two resulted in the object being black
     * (with a bunch of nasty error messages printed to
     * the console saying that the texture is not renderable).
     * Using a texture with other dimensions achieved
     * the goal of not showing up visually, but it still
     * printed the annoying error messages. That is
     * what I ended up doing */
  static Texture _generatePlainWhiteTexture() {
    Texture toReturn = loadTexture("plain_white.jpg");
    toReturn.generateMipmaps = false;
    return toReturn;
  }

  List<Bullet> update(Keyboard board, Duration elapsedTime) {
    for (PlayerUpdateAction updateAction in _updateActions) {
      updateAction(board, elapsedTime);
    }
    invulnerabilityToFireClock.update(elapsedTime);
    spikinessClock.update(elapsedTime);
    tripleShootClock.update(elapsedTime);
    if (!_swellingDueToImminentDeath && !_entrappedByLightning && !incapacitatedDueToMessingWithStage) {
      List<Bullet> returnedBullets = _maybeFire(elapsedTime);
      return returnedBullets;
    }
    if (_swellingDueToImminentDeath) {
      swellingAnimation.update(elapsedTime);
    }
    return [];
  }

  void handleFireLineCollision() {
    if (invulnerableToFire) {
      return;
    } else {
      _setMaterial(burnedMaterial);
      invulnerableToFire = true;
      invulnerabilityToFireClock.restart();
      hit();
    }
  }

  Player({double hue: 0.5}) {
    invulnerabilityToFireClock = generateInvulnerabilityToFireClock();
    spikinessClock = generateSpikinessClock();
    tripleShootClock = generateTripleShootClock();
    material = _generateMaterial(hue);
    rollingPart = generateRollingPart(material);
    torso = generateTorso(material);
    torso.position.y = ROLLING_PART_RADIUS;
    _makeSingleShoot();
    this.add(rollingPart);
    this.add(torso);
    for (GunTurret turret in gunTurrets) {
      this.add(turret);
    }
  }

  void _setMaterial(Material m) {
    torso.material = m;
    rollingPart.material = m;
  }

  Vector3 get rollingPartWorldCoordinates {
    return rollingPart.matrixWorld.getTranslation().clone();
  }

  Vector3 get torsoWorldCoordinates {
    return torso.matrixWorld.getTranslation().clone();
  }

  void handleShotgunPickup() {
    if (!_tripleShoot) {
      _makeTripleShoot();
      _tripleShoot = true;
    }
    tripleShootClock.restart();
  }

  void handleSpikeBallPickup() {
    if (!spikey) {
      _makeSpikey();
      spikey = true;
    }
    spikinessClock.restart();
  }

  double get horizontalRadiusAroundBall {
    if (spikey) {
      return ROLLING_PART_RADIUS + SPIKE_LENGTH;
    } else {
      return ROLLING_PART_RADIUS;
    }
  }

  bool _touchingPillar(DeathPillar pillar) {
    Vector3 currentPosition = new Vector3.copy(this.position);
    currentPosition.sub(pillar.position);
    return currentPosition.length < this.horizontalRadiusAroundBall + pillar.radius;
  }

  static List<Object3D> _generateSpikes() {
    List<Object3D> spikeList = [];

    final Geometry spikeGeometry = new CylinderGeometry(SPIKE_TOP_RADIUS, SPIKE_BOTTOM_RADIUS, SPIKE_LENGTH);
    final Material spikeMaterial = new MeshLambertMaterial();
    final int numSpikes = 10;
    for (int i = 0; i < numSpikes; i++) {
      Mesh spikeMesh = new Mesh(spikeGeometry, spikeMaterial);
      spikeMesh.rotation.z = -PI / 2;
      spikeMesh.position.x = ROLLING_PART_RADIUS + (SPIKE_LENGTH / 2);
      Object3D spikeObject = new Object3D();
      spikeObject.add(spikeMesh);
      double rotationRadians = (2 * PI * i) / numSpikes;
      spikeObject.rotation.y = rotationRadians;
      spikeList.add(spikeObject);
    }
    return spikeList;
  }

  bool overEdgeOfSquare(double squareSideLength) {
    Vector3 whereIAm = rollingPartWorldCoordinates;
    squareSideLength = squareSideLength / 2;
    if (whereIAm.x + ROLLING_PART_RADIUS < -squareSideLength) {
      return true;
    }
    if (whereIAm.z + ROLLING_PART_RADIUS < -squareSideLength) {
      return true;
    }
    if (whereIAm.x - ROLLING_PART_RADIUS > squareSideLength) {
      return true;
    }
    if (whereIAm.z - ROLLING_PART_RADIUS > squareSideLength) {
      return true;
    }
    return false;
  }

  bool checkPlayerCollision(RealisticMovementPlayer other) {
    Vector3 currentPosition = new Vector3.copy(this.position);
    currentPosition.sub(other.position);
    if (currentPosition.length < this.horizontalRadiusAroundBall + other.horizontalRadiusAroundBall) {
      return true;
    }
    return false;
  }

  void _makeSpikey() {
    for (Object3D spike in spikes) {
      add(spike);
    }
  }

  void _makeNotSpikey() {
    for (Object3D spike in spikes) {
      remove(spike);
    }
  }

  GunTurret generateTurret() {
    GunTurret toReturn = new GunTurret(owner: this, radiusOfCircularObjectOnWhichPlaced: TORSO_RADIUS);
    toReturn.position.y = Player.ARM_HEIGHT;
    return toReturn;
  }
  /*
  double pointToSegment(vector.Vector3 point, vector.Vector3 segmentStart, vector.Vector3 segmentEnd) {
    /* http://geomalgorithms.com/a02-_lines.html */
    vector.Vector3 v = segmentEnd.clone().sub(segmentStart);
    vector.Vector3 w = point.clone().sub(segmentStart);
    double c1 = w.dot(v);
    if (c1 <= 0) {
      return w.length;// point.distanceTo(segmentStart)
    }
    double c2 = v.dot(v);
    if (c2 <= c1) {
      return point.distanceTo(segmentEnd);
    }
    double b = c1 / c2;
    vector.Vector3 Pb = segmentStart.clone().addScaled(v, b);
    return point.distanceTo(Pb);
  } */

  bool checkLightningFieldCollision(LightningField lightningField) {
    if (position.x > lightningField.minimumX - Player.ROLLING_PART_RADIUS) {
      if (position.x < lightningField.maximumX + Player.ROLLING_PART_RADIUS) {
        if (position.y > lightningField.minimumY - Player.ROLLING_PART_RADIUS) {
          if (position.y < lightningField.maximumY + Player.ROLLING_PART_RADIUS) {
            if (position.z > lightningField.minimumZ - Player.ROLLING_PART_RADIUS) {
              if (position.z < lightningField.maximumZ + Player.ROLLING_PART_RADIUS) {
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  bool checkItemCollision(Item item) {
    Vector3 positionForCollision = position.clone();
    return positionForCollision.sub(item.position).length < horizontalRadiusAroundBall + Item.collidingSphereRadius;
  }

  void _makeTripleShoot() {
    for (GunTurret turret in gunTurrets) {
      remove(turret);
    }
    gunTurrets.clear();
    GunTurret frontTurret = generateTurret();
    GunTurret leftTurret = generateTurret();
    leftTurret.rotation.y = PI / 6;
    GunTurret rightTurret = generateTurret();
    rightTurret.rotation.y = -PI / 6;
    gunTurrets.add(frontTurret);
    gunTurrets.add(leftTurret);
    gunTurrets.add(rightTurret);
    for (GunTurret gunTurret in gunTurrets) {
      add(gunTurret);
    }
  }

  void _makeSingleShoot() {
    for (GunTurret turret in gunTurrets) {
      remove(turret);
    }
    gunTurrets.clear();
    gunTurrets.add(generateTurret());
    for (GunTurret gunTurret in gunTurrets) {
      add(gunTurret);
    }
  }

  bool hit() {
    _hits += 1;
    /* With a lambert material, setting saturation above 1.0 creates an interesting effect,
      and a more subtle increase would not be very noticeable */
    material.color.offsetHSL(0.0, 1.0, 0.0);
    if (_hits >= STARTING_HP) {
      _swellingDueToImminentDeath = true;
      if (swellingAnimation == null) {
        swellingAnimation = generateSwellingAnimation();
      }
      return true;
    } else {
      return false;
    }
  }

  List<Bullet> _maybeFire(Duration elapsedTime) {
    List<Bullet> toReturn = [];
    if (_sinceLastShot.inMilliseconds > 1000) {
      for (GunTurret turret in gunTurrets) {
        toReturn.add(turret.fire());
      }
      _sinceLastShot = new Duration();
    } else {
      _sinceLastShot = _sinceLastShot + elapsedTime;
    }
    return toReturn;
  }


  static Material _generateMaterial(double hue) {
    MeshLambertMaterial toReturn = new MeshLambertMaterial();
    toReturn.color = new Color().setHSL(hue, STARTING_SATURATION, 0.5);
    toReturn.map = plainWhiteTexture;
    return toReturn;
  }

  Mesh generateRollingPart(Material material) {
    return new Mesh(new SphereGeometry(ROLLING_PART_RADIUS), material);
  }

  Mesh generateTorso(Material material) {
    return new Mesh(new CylinderGeometry(TORSO_RADIUS, TORSO_RADIUS, TORSO_HEIGHT), material);
  }
}


class StaccatoMovementPlayer extends Player {

  final int leftKey;
  final int rightKey;
  final int downKey;
  final int upKey;

  Vector3 orientation = new Vector3(0.0, 0.0, -1.0);

  StaccatoMovementPlayer(this.upKey, this.rightKey, this.downKey, this.leftKey) {
    _registerUpdateAction(updateActions);
  }

  void updateActions(Keyboard board, Duration elapsedTime) {
    double SQUARESTAGEWIDTH = 1000.0;
    Vector3 toMove = new Vector3(0.0, 0.0, 0.0);
    if (board.isDown(upKey)) {
      toMove.z -= 1.0;
    }
    if (board.isDown(downKey)) {
      toMove.z += 1.0;
    }
    if (board.isDown(leftKey)) {
      toMove.x -= 1.0;
    }
    if (board.isDown(rightKey)) {
      toMove.x += 1.0;
    }
    if (toMove.length == 0) {
      return;
    }
    toMove.normalize();
    orientation = new Vector3(toMove.x, toMove.y, toMove.z);
    Vector3 startingVector = new Vector3(0.0, 0.0, -1.0);
    double dotProduct = toMove.dot(startingVector);
    double angle = acos(dotProduct);
    if (toMove.x > 0) {
      angle = -angle;
    }
    this.rotation.y = angle;
    toMove.x = toMove.x * elapsedTime.inMilliseconds / 2;
    toMove.z = toMove.z * elapsedTime.inMilliseconds / 2;
    this.position.add(toMove);
    if (this.position.x >= SQUARESTAGEWIDTH / 2) {
      this.position.x = SQUARESTAGEWIDTH / 2;
    }
    if (this.position.x <= -SQUARESTAGEWIDTH / 2) {
      this.position.x = -SQUARESTAGEWIDTH / 2;
    }
    if (this.position.z >= SQUARESTAGEWIDTH / 2) {
      this.position.z = SQUARESTAGEWIDTH / 2;
    }
    if (this.position.z <= -SQUARESTAGEWIDTH / 2) {
      this.position.z = -SQUARESTAGEWIDTH / 2;
    }
  }
}
