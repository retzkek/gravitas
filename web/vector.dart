library vector;

import 'dart:math';

class Vector {
  num x, y, z;

  Vector() : x = 0.0, y = 0.0, z = 0.0;
  Vector.xy(x, y) : x = x, y = y, z = 0.0;
  Vector.xyz(x, y, z) : x = x, y = y, z = z;

  String toString() {
    return '$x, $y, $z';
  }
  
  Vector copy() {
    return new Vector.xyz(x, y, z);
  }
  
  num magnitude() {
    return sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
  }
  
  void normalize() {
    var m = magnitude();
    x = x/m;
    y = y/m;
    z = z/m;
  }

  void add(Vector d) {
    x += d.x;
    y += d.y;
    z += d.z;
  }
  
  Vector plus(Vector v) {
    Vector w = new Vector.xyz(x, y, z);
    w.add(v);
    return w;
  }

  void subtract(Vector d) {
    this.x -= d.x;
    this.y -= d.y;
    this.z -= d.z;
  }
  
  Vector minus(Vector v) {
    Vector w = new Vector.xyz(x, y, z);
    w.subtract(v);
    return w;
  }
  
  void scale(num d) {
    this.x *= d;
    this.y *= d;
    this.z *= d;
  }
  
  Vector scaled(num d) {
    Vector w = new Vector.xyz(x, y, z);
    w.scale(d);
    return w;
  }
  
  num distanceToSquared(Vector v) {
    num dx = x - v.x;
    num dy = y - v.y;
    num dz = z - v.z;
    return dx*dx + dy*dy + dz*dz;
  }
  
  num distanceTo(Vector v) {
    return sqrt(distanceToSquared(v));
  }
  
  num dot(Vector v) {
    return x*v.x + y*v.y + z*v.z;
  }
  
  Vector cross(Vector v) {
    return new Vector.xyz(y*v.z - z*v.y, z*v.x - x*v.z, x*v.y - y*v.x);
  }

}