library items;

import 'package:three/three.dart';
import 'dart:math';

class Item extends Object3D {
  static const double collidingSphereRadius = 50.0;
  Mesh _surroundingCircle = new Mesh(new SphereGeometry(collidingSphereRadius), new MeshBasicMaterial(color: new Random().nextInt(0xffffff), wireframe: true));

  Item() {
    add(_surroundingCircle);
  }

  void update(Duration d) {
     this.rotation.y = this.rotation.y + d.inMilliseconds * 0.001;
   }
}

class SpikeBall extends Item {

  static const double _ballRadius = Item.collidingSphereRadius / 2.0;
  static const double _spikeLength = Item.collidingSphereRadius - _ballRadius;
  static const double _spikeTopRadius = _ballRadius / 40;
  static const double _spikeBottomRadius = _ballRadius / 4;
  static final Geometry _ballGeometry = new SphereGeometry(_ballRadius);
  static final Geometry _spikeGeometry = new CylinderGeometry(_spikeTopRadius, _spikeBottomRadius, _spikeLength);
  static final Material _ballMaterial = new MeshLambertMaterial(color: 0x000000);
  static final Material _spikeMaterial = new MeshLambertMaterial(color: 0xFFFFFF);

  SpikeBall() : super() {
    Mesh ball = new Mesh(_ballGeometry, _ballMaterial);
    add(ball);
    Object3D topSpike = _generateSpike();
    topSpike.rotation.z = PI / 2;
    Object3D bottomSpike = _generateSpike();
    bottomSpike.rotation.z = -PI / 2;
    Object3D northSideSpike = _generateSpike();
    Object3D eastSideSpike = _generateSpike();
    eastSideSpike.rotation.y = PI / 2;
    Object3D southSideSpike = _generateSpike();
    southSideSpike.rotation.y = PI;
    Object3D westSideSpike = _generateSpike();
    westSideSpike.rotation.y = 3 * PI / 2;
    add(bottomSpike);
    add(topSpike);
    add(northSideSpike);
    add(eastSideSpike);
    add(westSideSpike);
    add(southSideSpike);
  }

  Object3D _generateSpike() {
    Mesh spikeMesh = new Mesh(_spikeGeometry, _spikeMaterial);
    spikeMesh.rotation.z = -PI / 2;
    spikeMesh.position.x = _ballRadius + (_spikeLength / 2);
    Object3D spikeObject = new Object3D();
    spikeObject.add(spikeMesh);
    return spikeObject;
  }
}

class Shotgun extends Item {
  static const double _shaftLength = Item.collidingSphereRadius;
  static const double _shaftRadius = _shaftLength / 10.0;
  static const double _handleLength = _shaftLength / 5;
  static const double _handleRotationAngle = PI / 4;
  static const int brownHandleColor = 0xf4a460;
  static const int greyShaftColor = 0x484848;
  static final Material handleMaterial = new MeshLambertMaterial(color: brownHandleColor);
  static final Material shaftMaterial = new MeshLambertMaterial(color: greyShaftColor);
  static final Geometry shaftGeometry = new CylinderGeometry(_shaftRadius, _shaftRadius, _shaftLength);
  static final Geometry handleGeometry = new CylinderGeometry(_shaftRadius, _shaftRadius, _handleLength);
  Mesh shaft = new Mesh(shaftGeometry, shaftMaterial);
  Mesh handle = new Mesh(handleGeometry, handleMaterial);

  Shotgun() : super() {
    handle.position.x = ((_shaftLength) + (cos(_handleRotationAngle) * _handleLength)) / (2.0);
    handle.position.x = handle.position.x - 4.0;
    shaft.rotation.z = PI / 2;
    handle.rotation.z = PI / 4;
    shaft.position.y = (sin(_handleRotationAngle) * _handleLength) - _shaftRadius / 2.0;
    add(shaft);
    add(handle);
  }
  /*
  vector.Vector3 get segmentStart {
    return shaft.matrixWorld.getTranslation();
  }

  vector.Vector3 get segmentEnd {
    return tip.matrixWorld.getTranslation();
  } */



}