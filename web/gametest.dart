import 'dart:html';
import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart';
import 'package:game_loop/game_loop_html.dart';
import 'package:three/three.dart';

CanvasElement canvas;
WebGLRenderer renderer;
GameLoopHtml gameLoop;

PerspectiveCamera camera;
Scene scene;

List bricks = [];
Ball ball;

const int windowHeight = 480;
const int windowWidth = 320;
const double fov = 70.0;

// Game size
const double screenBottom = 0.0;
const double screenTop = 1.6;
const double screenLeft = -0.5;
const double screenRight = 0.5;

const double screenWidth = screenRight - screenLeft;
const double screenHeight = screenTop - screenBottom;

const int bricksPerRow = 5;
const int brickRows = 5;


class Brick {
  
  double x;
  double y;
  bool present = true;
  
  static const double width = screenWidth / bricksPerRow;
  static const double height = width / 3;

  static const double meshWidth = width * 0.9;
  static const double meshHeight = height - (width*0.1);
  
  static Geometry geometry = new CubeGeometry( meshWidth, meshHeight, meshHeight );
  static Material material = new MeshNormalMaterial();
  Mesh mesh;
  
  
  Brick(this.x, this.y){ 
    this.mesh = new Mesh(geometry, material);
    this.mesh.position.x = this.x;
    this.mesh.position.y = this.y;
  }
  
  void destroy(){
    this.present = false;
    this.mesh.visible = false;
  }
  
}



class Ball {
  
  double x = 0.0;
  double y = 0.0;
  double speed = 0.025;
  double angle = 0.125;
  static const double radius = Brick.meshHeight / 2;
  
  static Geometry geometry = new SphereGeometry(radius);
  static Material material = new MeshBasicMaterial(color: 0xdddddd);
  Mesh mesh;
  
  Ball(){
    this.mesh = new Mesh(geometry, material);
  }
  
  void bounce(normal){
    // First  : bounce
    var newAngle = (this.angle + 0.5) % 1;
    
    // Then, deviation
    newAngle += 2 * (normal - newAngle);
    
    this.angle = newAngle % 1;
  }
  
  void update(){
    // Spinning
    // this.mesh.rotation.x += 0.1;
    // this.mesh.rotation.y += 0.2;
    // this.mesh.rotation.z += 0.3;
    
    // Move
    this.x = this.x + (this.speed * Math.cos(this.angle * 2 * Math.PI));
    this.y = this.y + (this.speed * Math.sin(this.angle * 2 * Math.PI));
    _render();
  }
  
  void _render(){
    this.mesh.position.x = this.x;
    this.mesh.position.y = this.y;
  }
  
  Vector3 directionVector(){
    return new Vector3(
          Math.cos(this.angle * 2 * Math.PI),
          Math.sin(this.angle * 2 * Math.PI),
          0.0);
  }
   
}


void init() {
  
  // Initialisation
  Element container = querySelector('#game');
  
  // Setup the renderer
  renderer = new WebGLRenderer(clearColorHex: 0x222222, clearAlpha: 1);
  renderer.setSize( windowWidth, windowHeight );
  
  canvas = renderer.domElement;
  container.children.add(canvas); 
 
  // Setup the game loop
  gameLoop = new GameLoopHtml(canvas);
  gameLoop.onUpdate = update;
  gameLoop.onRender = render;  
  
  // Initialize the scene
  scene = new Scene();
  scene.fog = new FogLinear( 0x222222 );
  
  camera = new PerspectiveCamera( fov, windowWidth / windowHeight, 1.0, 1000.0 );
  camera.position.x = (screenRight + screenLeft) / 2;  
  camera.position.y = (screenTop + screenBottom) / 2;  
  camera.position.z = 1.5;  
  
  scene.add(camera);
  

  // Initialize the scene contents

  // Rows
  for(int i=0 ; i < brickRows ; i++) {

    // Cols
    for(int j=0 ; j < bricksPerRow ; j++) {

      double brickX = screenLeft + (j*Brick.width) + (Brick.width / 2);
      double brickY = screenTop - (i*Brick.height) - (Brick.height/2); 

      Brick brick = new Brick(brickX, brickY);
      bricks.add( brick );
      scene.add(brick.mesh);
    }
  }
  
  ball = new Ball();
  scene.add( ball.mesh );
}


void handleCollisions() {
  // Ball with screen borders
  if ( ball.x > screenRight ){
    ball.bounce(0.5);    
  }

  if ( ball.x < screenLeft ){
    ball.bounce(0.0);    
  }
  
  if ( ball.y > screenTop ){
    ball.bounce(-0.25);    
  }
  
  if ( ball.y < screenBottom ){
    ball.bounce(0.25);    
  }
  
  // Ball with bricks  
  var rays = ball.mesh.geometry.vertices.map( (Vector3 vertex) => new Ray(ball.mesh.position, vertex) );
  
  for( Brick brick in bricks ){
    if( !brick.present ){
      continue;
    }
    
    int rayIndex = 0;
    for( Ray ray in rays){
      var intersects = ray.intersectObject(brick.mesh);
      if (intersects.length > 0) {
        Vector3 normal = intersects[0].face.normal;

        print('intersected with ' + intersects.length.toString() +  ' : ' + normal.x.toString() + ' ' + normal.y.toString());
        
        // Get the angle from the normal
        double angle = Math.asin(normal.y) / (2* Math.PI);
        if (normal.y < 0) {
          angle += 0.5;
        }
                
        brick.destroy();
        ball.bounce(angle);
        break;
      }
      rayIndex += 1;
    }
  }
  
}

void update(GameLoopHtml gameLoop) {
  handleCollisions();
  
  ball.update();
}


void render(GameLoopHtml gameLoop) {
  renderer.render( scene, camera );
}


void main() {
  
  init();

  // Launch!
  gameLoop.start();
}
