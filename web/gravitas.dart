import 'dart:html';
import 'dart:math';

import 'body.dart';

final DivElement game = (querySelector('#game') as DivElement);
final CanvasRenderingContext2D context = (querySelector("#canvas") as CanvasElement).context2D;
final InputElement simulationSpeedSlider = querySelector("#simulationSpeedSlider");
final Element simulationSpeedSpan = querySelector("#simulationSpeedSpan");
final InputElement speedSlider = querySelector("#speedSlider");
final Element speedSpan = querySelector("#speedSpan");
final InputElement angleSlider = querySelector("#angleSlider");
final Element angleSpan = querySelector("#angleSpan");
final ButtonElement fireButton = querySelector("#fireButton");
final ButtonElement resetButton = querySelector("#resetButton");

Board board;

class Board {
  /* Board contains and controls the state of a single game board.
   */
  Body sun = new Body();
  var planets = new List<OrbitalBody>(); // planets react ony to the sun, but not each other
  var projectiles = new List<GravitationalBody>(); // projectiles react to the sun and planets
  LauncherBody player;
  
  num simulationSpeed = 1.0;

  Board() {
    sun.size = 40;
    sun.density = 5;
    
    player = new LauncherBody(sun, 100, 0,      1, 10);
    
    planets.add(new OrbitalBody(sun, 150, 0.8*PI, 1, 10));
    planets.add(new OrbitalBody(sun, 200, 1.4*PI, 3, 15));
    OrbitalBody b = new OrbitalBody(sun, 300, 1.4*PI, 1, 10);
    planets.add(b);
    planets.add(new OrbitalBody(b, 25, 0.0, 0.5, 2));
    planets.add(new OrbitalBody(b, 40, PI, 1.0, 3));
    
    GravitationalBody comet = new GravitationalBody.xyr(150, -150, 2)
      ..haveOrbit(sun);
    projectiles.add(comet);
    comet = new GravitationalBody.xyr(-150, 150, 2)
      ..haveOrbit(sun);
    projectiles.add(comet);
    
    fireButton.onClick.listen(onFire);
    resetButton.onClick.listen(onReset);
  }

  void render() {
    // get client inputs
    simulationSpeed = simulationSpeedSlider.valueAsNumber;
    num speed = speedSlider.valueAsNumber;
    player.launchSpeed = speed;
    num angleDeg = angleSlider.valueAsNumber;
    player.launchAzimuth = angleDeg * PI / 180.0;
    
    // draw board
    context.fillStyle = "black";
    context.fillRect(0,  0,  context.canvas.width,  context.canvas.height);
    
    // draw bodies
    sun.draw(context);
    
    player.update(simulationSpeed);
    player.draw(context);
    
    planets.forEach((b) {
      b.update(simulationSpeed);
      b.draw(context);
    });
    
    var sunAndPlanets = new List<Body>()
      ..add(sun)
      ..add(player)
      ..addAll(planets);
    projectiles.forEach((b) {
      b.update(sunAndPlanets, simulationSpeed);
      b.draw(context);
    });
    
    // update client text
    simulationSpeedSpan.text = '$simulationSpeed';
    speedSpan.text = '$speed';
    angleSpan.text = '$angleDeg';

  }
  
  void onFire(Event e) {
    projectiles.add(player.fireZeMissile());
  }
  
  void onReset(Event e) {
    projectiles.clear();
  }
}

void animate(num time) {
  window.requestAnimationFrame( animate );
  board.render();
}

void reshape() {
  context.canvas.width = game.clientWidth;
  context.canvas.height = game.clientWidth;
}

void main() {
  board = new Board();
  window.onResize.listen( onWindowResize );
  reshape();
  animate(0);
}

void onWindowResize(Event e) {
  reshape();
}

