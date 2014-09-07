library obstacles;

import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart';
import 'dart:math';
import 'player.dart';
import 'package:vector_math/vector_math.dart';

class FireballLine extends Object3D {

  List<Fireball> fireballs = [];

  FireballLine({int fireballCount : 10, Set<int> toSkip}) {
    if (toSkip == null) {
      toSkip == new Set<int>();
    }
    fireballCount -= 1;
    while (fireballCount > 0) {
      fireballCount -= 1;
      if (toSkip.contains(fireballCount)) {
        continue;
      }
      Fireball fireball = new Fireball();
      fireball.position.z = fireballCount * Fireball.radius;
      fireballs.add(fireball);
      add(fireball);
    }
  }

  void update(Duration d) {
  //  rotation.y += d.inMilliseconds * 0.001;
    Fireball.update(d);
   /* for (Fireball fireball in fireballs) {
      fireball.update(d);
    } */
  }

  bool checkPlayerCollision(Player p) {
    for (Fireball fireball in fireballs) {
      if (fireball.checkPlayerCollision(p)) {
      //  fireball.checkPlayerCollision(p, verbose : true);
        return true;
      }
    }
    return false;
  }

}

class Fireball extends Object3D {

  static final Random random = new Random();
  static final double radius = 50.0;
  static final Texture fireTexture = generateFireTexture();

  static void update(Duration d) {
    fireTexture.offset.y = fireTexture.offset.y - (d.inMilliseconds * 0.0001);
    fireTexture.offset.x = fireTexture.offset.x - (d.inMilliseconds * 0.0001);
  }

  static Texture generateFireTexture() {
    Texture loaded = loadTexture("lava-stage-textures/lava.jpg");
    loaded.needsUpdate = true;
    loaded.wrapS = loaded.wrapT = RepeatWrapping;
    return loaded;
  }

  Fireball() {
   // fireTexture.needsUpdate = true;
   // fireTexture.wrapS = fireTexture.wrapT = RepeatWrapping;
    Geometry sphereGeometry = new SphereGeometry(radius);
    Material sphereMaterial = new MeshBasicMaterial(map : fireTexture);
    Mesh sphere = new Mesh(sphereGeometry, sphereMaterial);
    add(sphere);
  }

  bool checkPlayerCollision(Player p) {
   /* if (verbose) {
    print("Calling checkPlayerCollision!");
    } */
    Vector3 worldPosition = matrixWorld.getTranslation().clone();
   /* if (verbose) {
    print("The world position of this fireball is " + worldPosition.toString());
    } */
    worldPosition.sub(p.rollingPartWorldCoordinates);
  /*  if (verbose) {
    print("The world coordinates of the player are " + p.rollingPartWorldCoordinates.toString());
    } */
    double distance = worldPosition.length;
   /* if (verbose) {
    print("The distance computed was " + distance.toString());
    } */
    return distance <= Player.ROLLING_PART_RADIUS + radius;
  }
 }

class LightningField extends Object3D {

  static final Random random = new Random();
  static final Material material = new ParticleBasicMaterial(
      color: 0xFFFFFF,
      map: loadTexture("nine-pillar-stage-textures/particleenergyball-ss-alleffects.png"),
      side: BackSide, size: 20,
      blending: AdditiveBlending,
      depthWrite: false,
      alphaTest: 0.5, //  depthTest: false,
      transparent: true);
  Geometry particles;
  ParticleSystem particleSystem;

  final double minimumX;
  final double maximumX;
  final double minimumY;
  final double maximumY;
  final double minimumZ;
  final double maximumZ;

  LightningField({this.minimumX: -250.0, this.maximumX: 250.0, this.minimumY: -250.0, this.maximumY: 250.0, this.minimumZ: -250.0, this.maximumZ: 250.0}) {
    /*   Geometry backupCubeGeometry = new CubeGeometry(maximumX - minimumX, maximumY - minimumY,
        maximumZ - minimumZ);
    Texture texture = loadTexture('abstract_textures_11.jpg');
   // print("Texture generated : " + texture.toString());
    texture.generateMipmaps = false;
   // texture.wrapS = texture.wrapT = RepeatWrapping;
    //texture.repeat.x = 2.0;
    //texture.repeat.y = 2.0;
    MeshBasicMaterial backupCubeMaterial = new MeshBasicMaterial(side : DoubleSide);
    backupCubeMaterial.map = texture;
    Mesh backupCube = new Mesh(backupCubeGeometry, backupCubeMaterial);
    backupCube.position.x = (maximumX + minimumX) / 2;
    backupCube.position.y = (maximumY + minimumY) / 2;
    backupCube.position.z = (maximumZ + minimumZ) / 2; */
    //add(backupCube);
    int particleCount = 3600;
    particles = new Geometry();
    double xRange = maximumX - minimumX;
    double yRange = maximumY - minimumY;
    double zRange = maximumZ - minimumZ;
    for (int p = 0; p < particleCount; p++) {
      double pX = minimumX + (random.nextDouble() * xRange);
      double pY = minimumY + (random.nextDouble() * yRange);
      double pZ = minimumZ + (random.nextDouble() * zRange);
      Vector3 particle = new Vector3(pX, pY, pZ);
      particles.vertices.add(particle);
    }
    particleSystem = new ParticleSystem(particles, material);
    add(particleSystem);
  }

  void vertexRandomAdjust(Vector3 vertex) {
    vertex.x += random.nextDouble() - 0.5;
    if (vertex.x > maximumX) {
      vertex.x = maximumX;
    } else if (vertex.x < minimumX) {
      vertex.x = minimumX;
    }
    vertex.y += random.nextDouble() - 0.5;
    if (vertex.y > maximumY) {
      vertex.y = maximumY;
    } else if (vertex.y < minimumY) {
      vertex.y = minimumY;
    }
    vertex.z += random.nextDouble() - 0.5;
    if (vertex.z > maximumZ) {
      vertex.z = maximumZ;
    } else if (vertex.z < minimumZ) {
      vertex.z = minimumZ;
    }
  }

  void update(Duration d) {
    List<Vector3> newVertices = particles.vertices;
    particles = new Geometry();
    for (Vector3 vertex in newVertices) {
      vertexRandomAdjust(vertex);
      particles.vertices.add(vertex);
    }
    remove(particleSystem);
    particleSystem = new ParticleSystem(particles, material);
    add(particleSystem);
  }
}

class DeathPillar extends Object3D {
  final double spikeBodyRatio = 0.4;
  final int spikesPerLevel;
  final bool move;
  //  static final Material defaultMaterial = new MeshLambertMaterial(color: 0xFF0000);
  double bodyRadius;
  double spikeLength;
  double spikeBaseRadius;
  double radius;
  double height;
  Vector3 movementAxis;
  Vector3 movementStartingLocation = null;
  double movementSpeed;
  double movementRange;
  double distanceTraveled = 0.0;
  MeshLambertMaterial material = generateMaterial();
  CylinderGeometry spikeGeometry;

  static MeshLambertMaterial generateMaterial() {
    return new MeshLambertMaterial(color: 0x00005c);
  }

  DeathPillar({this.height: 200.0, this.radius: 400.0, bool spikey: true, this.spikesPerLevel: 80, this.move: false, this.movementAxis, this.movementSpeed: 0.5, this.movementRange}) {
    if (!move) {
      this.movementSpeed = 0.0;
    }
    if (move) {
      if (this.movementRange == null) {
        this.movementRange = this.radius * 5;
      }
      if (this.movementAxis == null) {
        this.movementAxis = new Vector3(1.0, 0.0, 0.0);
      }
    }
    if (spikey) {
      this.bodyRadius = radius * (1 - spikeBodyRatio);
      this.spikeLength = radius * spikeBodyRatio;
      this.spikeBaseRadius = (bodyRadius * 2 * PI) / spikesPerLevel;
      CylinderGeometry geometry = new CylinderGeometry(bodyRadius, bodyRadius, height, 24);
      Mesh body = new Mesh(geometry, material);
      body.position.y = height / 2;
      Object3D bodyContainer = new Object3D();
      bodyContainer.add(body);
      this.add(bodyContainer);
      double heightIndex = 0.0;
      double rotationMultiplier = 360.0 / spikesPerLevel;
      this.spikeGeometry = new CylinderGeometry(1.0, spikeBaseRadius, spikeLength, 16);
      while (heightIndex < (height - spikeBaseRadius)) {
        int rotationIndex = 0;
        while (rotationIndex < spikesPerLevel) {
          this.add(_generateSpike(heightIndex, rotationIndex * rotationMultiplier));
          rotationIndex += 1;
        }
        heightIndex += spikeBaseRadius;
      }
    } else {
      this.bodyRadius = radius;
      CylinderGeometry geometry = new CylinderGeometry(bodyRadius, bodyRadius, height, 24);
      Mesh body = new Mesh(geometry, material);
      body.position.y = height / 2;
      Object3D bodyContainer = new Object3D();
      bodyContainer.add(body);
      this.add(bodyContainer);
    }
  }


  void update(Duration d) {
    if (move) {
      if (movementStartingLocation == null) {
        movementStartingLocation = this.position.clone();
      }
      if (distanceTraveled >= movementRange) {
        movementStartingLocation.addScaled(movementAxis, movementRange);
        this.position.setFrom(movementStartingLocation);
        movementAxis.multiply(new Vector3.all(-1.0));
        distanceTraveled = 0.0;
      } else {
        double toMove = movementSpeed * d.inMilliseconds;
        position.addScaled(movementAxis, toMove);
        distanceTraveled = distanceTraveled + toMove;
      }
    }
  }

  _generateSpike(double startingHeight, double startingAngleDegrees) {
    Mesh spikeMesh = new Mesh(spikeGeometry, material);
    spikeMesh.rotation.z = -90.0 * PI / 180;
    spikeMesh.position.x = bodyRadius + spikeLength / 2;
    spikeMesh.position.y = startingHeight;
    Object3D rotatedSpike = new Object3D();
    rotatedSpike.add(spikeMesh);
    rotatedSpike.rotation.y = startingAngleDegrees;
    return rotatedSpike;
  }
}