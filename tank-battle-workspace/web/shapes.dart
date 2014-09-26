library shapes;

import 'package:vector_math/vector_math.dart';
/**
 * This library defines mixins to be inherited
 * by game objects that want to have access to convenient
 * collision detection functions. I'll probably
 * be implementing BoxCollidable next.
 */

Vector3 _collidesTwoSphereData(Vector3 onePosition, double oneRadius, Vector3 otherPosition, double otherRadius) {
  onePosition = onePosition.clone();
  onePosition.sub(otherPosition);
  if (onePosition.length < oneRadius + otherRadius) {
    return onePosition;
  }
  return null;
}

abstract class SphereCollidable {

  Vector3 getSphereWorldPosition();
  double get sphereRadius;

  /* Sometimes, you want to use values other than a sphere's
     * canonical position and radius when computing a collision.
     * In particular, when a [Fireball] collides with a [Player],
     * you want to use the [ROLLING_PART_RADIUS] constant field of the [Player] class,
     * rather than the actual radius that can include invincible spikes.
     */
  Vector3 collidesWithSphereData(Vector3 otherPosition, double otherRadius) => _collidesTwoSphereData(getSphereWorldPosition(), sphereRadius, otherPosition, otherRadius);

  Vector3 collidesWithSphere(SphereCollidable other) => collidesWithSphereData(other.getSphereWorldPosition(), other.sphereRadius);

  Vector3 collidesWithDisk(DiskCollidable disk) {
    Vector3 currentPosition = getSphereWorldPosition();
    Vector3 otherPosition = disk.getDiskWorldPosition();
    currentPosition.y = 0.0;
    otherPosition.y = 0.0;
    return _collidesTwoSphereData(currentPosition, sphereRadius, otherPosition, disk.diskRadius);
  }
}

/**
 * [DiskCollidable] is like [SphereCollidable], but the y-value
 * returned from [getDiskWorldPosition] is to be ignored
 * for the purpose of collision calculations, even though
 * it may be relevant for other pieces of game logic. */
abstract class DiskCollidable {
  Vector3 getDiskWorldPosition();
  double get diskRadius;

  Vector3 collidesWithDisk(DiskCollidable disk) {
    Vector3 currentPosition = getDiskWorldPosition();
    Vector3 otherPosition = disk.getDiskWorldPosition();
    currentPosition.y = 0.0;
    otherPosition.y = 0.0;
    return _collidesTwoSphereData(currentPosition, diskRadius, otherPosition, disk.diskRadius);
  }

  Vector3 collidesWithSphere(SphereCollidable sphere) {
    Vector3 currentPosition = getDiskWorldPosition();
    Vector3 otherPosition = sphere.getSphereWorldPosition();
    currentPosition.y = 0.0;
    otherPosition.y = 0.0;
    return _collidesTwoSphereData(currentPosition, diskRadius, otherPosition, sphere.sphereRadius);
  }
}
