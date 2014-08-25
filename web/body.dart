library body;

import 'dart:html';
import 'dart:math';
import 'dart:collection';

import 'vector.dart';

//const num GRAV = 6.67384e-11; // m^3/kg/s^2 - will probably fudge for gameplay, this isn't a simulation
const num GRAV = 0.01;
const num HISTORY_SIZE = 100; // number of past locations to remember for dynamic objects

class Body {
  /* Body is the base class for any object that can appear in space; it has a location, size/radius, and density.
   */
  Vector location;
  num size;
  num density;

  Body() {
    location = new Vector();
    size = 0;
    density = 1;
  }

  Body.locationAndSize(x, y, size) {
    location = new Vector.xy(x, y);
    this.size = size;
    density = 10;
  }

  num mass() {
    return density * 4/3 * PI * size * size * size; // 3D instead of 2D? eh, why not
  }
  
  void draw(CanvasRenderingContext2D context) {
    context
        ..beginPath()
        ..lineWidth = 2
        ..fillStyle = "orange"
        ..strokeStyle = "white"
        ..arc(context.canvas.width/2+location.x, context.canvas.height/2+location.y, size, 0, PI * 2, false)
        ..fill()
        ..closePath()
        ..stroke();
  }
}

class OrbitalBody extends Body {
  /* OrbitalBody rotates around a specific body in a circular orbit, which does not use gravitational mechanics.
   */
  Vector orbitCenter;
  Body primary;
  num orbitRadius = 0.0; // m
  num azimuth = 0.0; // rad
  num speed = 0.0; // m/s
  num angularSpeed = 0.0; // rad/s
  
  OrbitalBody(Body primary, num or, num az, num s, num size) {
    this.primary = primary;
    orbitCenter = new Vector.xyz(primary.location.x, primary.location.y, primary.location.z);
    orbitRadius = or;
    azimuth = az;
    speed = s;
    angularSpeed = speed / orbitRadius;
    this.size = size;
    _updateLocation();
  }
  
  void _updateLocation() {
    // Updates Cartesian location from cylindrical
    location.x = primary.location.x + orbitRadius * cos(azimuth);
    location.y = primary.location.y + orbitRadius * sin(azimuth);
    //print('$azimuth :: $location');
  }
  
  void update(num timeScale) {
    azimuth += angularSpeed*timeScale;
    if (azimuth > 2* PI) {
      azimuth = 0;
    } else if (azimuth < 0.0) {
      azimuth = 2*PI;
    }
    _updateLocation();
  }

  void draw(CanvasRenderingContext2D context) {
    context
        ..beginPath()
        ..lineWidth = 0.3
        ..strokeStyle = "blue"
        //..setLineDash([6,10])
        ..arc(context.canvas.width/2+primary.location.x, context.canvas.height/2+primary.location.y, orbitRadius, 0, PI * 2, false)
        ..closePath()
        ..stroke();
    super.draw(context);
  }
}

class GravitationalBody extends Body {
  /* GravitationalBody extends Body to allow for movement based on gravitational mechanics. It adds velocity and acceleration vectors.
   */
  Vector velocity;
  Vector acceleration;
  Queue history;
  
  GravitationalBody.xyr(x, y, size) : super.locationAndSize(x, y, size), 
    velocity = new Vector(),
    acceleration = new Vector(),
    history = new Queue<Vector>();
  
  void haveOrbit(Body b) {
    /* haveOrbit sets velocity vector such that body will be in stable orbit of b
     * - only accounts for gravity from b
     * - sets orbit in xy plane
     */
    
    // compute unit vector normal to radial vector
    Vector force = _forceFromBody(b);
    num forceMag = force.magnitude(); // save for later
    force.normalize();
    Vector normal = new Vector.xyz(0,  0,  1);
    velocity = force.cross(normal);
    velocity.normalize();
    
    // calculate speed such that centripital force = gravitational force
    // f = m * v^2 / r
    // v = sqrt(f*r/m)
    num speed = sqrt(forceMag * location.distanceTo(b.location) / mass());
    velocity.scale(speed);
  }
  
  void update(List<Body> bodies, num timeScale) {
    history.add(location.copy());
    if (history.length > HISTORY_SIZE) {
      history.removeFirst();
    }
    
    location.add(velocity.scaled(timeScale));
    location.add(acceleration.scaled(timeScale*timeScale/2));
    velocity.add(acceleration.scaled(timeScale));
    // calculate net force from bodies
    var netForce = new Vector();
    bodies.forEach((body) => netForce.add(_forceFromBody(body)));
    netForce.scale(1/mass()); // covert force to acceleration F=MA
    acceleration = netForce;
    //print('$acceleration :: $velocity');
  }
  
  Vector _forceFromBody(Body b) {
    var force = new Vector.xyz(b.location.x - location.x,
        b.location.y - location.y,
        b.location.z - location.z);
    force.normalize();
    force.scale(GRAV * b.mass() / b.location.distanceTo(location));
    return force;
  }
  
  void draw(CanvasRenderingContext2D context) {
    if (history.length > 0) {
      context
           ..beginPath()
           ..lineWidth = 0.3
           ..strokeStyle = "green"
           ..moveTo(context.canvas.width/2+history.elementAt(0).x, context.canvas.height/2+history.elementAt(0).y);
      history.forEach((l) => context.lineTo(context.canvas.width/2+l.x, context.canvas.height/2+l.y));
      context
           //..closePath()
           ..stroke();
    }
    super.draw(context);
  }
}

class LauncherBody extends OrbitalBody {
  /* LauncherBody is an orbital planet that includes functionality for firing ze missiles!
   */
  num launchAzimuth = 0.0; // rad
  num launchSpeed = 50; // m/s?
  GravitationalBody missile;
  static const num launcherLength = 15;
  
  LauncherBody(Body primary, num or, num az, num s, num size) : super(primary, or, az, s, size);
  
  GravitationalBody fireZeMissile() {
    missile = new GravitationalBody.xyr(location.x, location.y, 2)
      ..velocity.x = launchSpeed*cos(launchAzimuth)
      ..velocity.y = launchSpeed*sin(launchAzimuth);
    
    return missile;
  }
  
  void draw(CanvasRenderingContext2D context) {
    context
        ..beginPath()
        ..lineWidth = 10
        ..strokeStyle = "grey"
        ..moveTo(context.canvas.width/2+location.x, context.canvas.height/2+location.y)
        ..lineTo(context.canvas.width/2 + location.x + (size + launcherLength)*cos(launchAzimuth),
            context.canvas.height/2 + location.y + (size + launcherLength)*sin(launchAzimuth))
        ..stroke();
    super.draw(context);
  }
  
}