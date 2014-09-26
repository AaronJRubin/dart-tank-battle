library shapes;

import 'package:vector_math/vector_math.dart';

abstract class SphereCollidable {

  Vector3 getSphereWorldPosition();
  double get sphereRadius;

  Vector3 collidesWithSphere(SphereCollidable other) {
    Vector3 currentPosition = getSphereWorldPosition();
    currentPosition.sub(other.getSphereWorldPosition());
    if (currentPosition.length < this.sphereRadius + other.sphereRadius) {
      return currentPosition;
    }
    return null;
  }

  /* Sometimes, you want to use values other than a sphere's
   * canonical position and radius when computing a collision.
   * In particular, when a fireball collides with a player,
   * you want to use the ROLLING_PART_RADIUS constant field of the Player class,
   * rather than the actual radius that can include invincible spikes.
   */
  Vector3 collidesWithSphereData(Vector3 otherPosition, double otherRadius) {
    Vector3 currentPosition = getSphereWorldPosition();
    currentPosition.sub(otherPosition);
    if (currentPosition.length < this.sphereRadius + otherRadius) {
      return currentPosition;
    }
    return null;
  }

  Vector3 collidesWithDisk(DiskCollidable disk) {
    Vector3 currentPosition = getSphereWorldPosition();
    currentPosition.sub(disk.getDiskWorldPosition());
    currentPosition.y = 0.0;
    if (currentPosition.length < this.sphereRadius + disk.diskRadius) {
      return currentPosition;
    }
    return null;
  }
}

abstract class DiskCollidable {
  Vector3 getDiskWorldPosition();
  double get diskRadius;
}
