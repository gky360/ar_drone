import com.shigeodayo.ardrone.processing.*;

ARDroneForP5 ardrone;

boolean video720p = false;
boolean autoMode = false;

void setup() {
  if (video720p) {
    size(1280, 720, P3D);
  } else {
    size(640, 360, P3D);
  }

  ardrone = new ARDroneForP5("192.168.1.1");
  // connect to the AR.Drone
  ardrone.connect();
  // for getting sensor information
  ardrone.connectNav();
  // for getting video information
  ardrone.connectVideo();
  // start to control AR.Drone and get sensor and video data of it
  ardrone.start();
}

void draw() {
  background(204);

  // getting image from AR.Drone
  // true: resizing image automatically
  // false: not resizing
  PImage img = ardrone.getVideoImage(false);
  if (img == null) {
    return;
  }
  image(img, 0, 0);

  // print out AR.Drone information
  ardrone.printARDroneInfo();

  // getting sensor information of Ar.Drone
  float pitch = ardrone.getPitch();
  float roll = ardrone.getRoll();
  float yaw = ardrone.getYaw();
  float altitude = ardrone.getAltitude();
  float velocity[] = ardrone.getVelocity();
  int battery = ardrone.getBatteryPercentage();

  String attitude = "pitch: " + pitch + "\nroll: " + roll + "\nyaw: " + yaw + "\naltitude: " + altitude;
  text(attitude, 20, 85);
  String vel = "vx: " + velocity[0] + "\nvy: " + velocity[1];
  text(vel, 20, 140);
  String bat = "battery: " + battery + "%";
  text(bat, 20, 170);
}

// PC のキーに応じて AR.Drone を操作できる。
// controlling AR.Drone through key input
void keyReleased() {
  ardrone.stop(); //hovering
}

void keyPressed() {
  autoMode = false;

  if (key == CODED) {
    switch (keyCode) {
      case UP:
        ardrone.forward();
        break;
      case DOWN:
        ardrone.backward();
        break;
      case LEFT:
        ardrone.goLeft();
        break;
      case RIGHT:
        ardrone.goRight();
        break;
      case SHIFT:
        ardrone.takeOff();
        break;
      case CONTROL:
        ardrone.landing();
        break;
      case ALT:
        ardrone.reset();
        break;
    }
  } else {
    switch (key) {
      case 's':
        ardrone.stop();
        break;
      case 'r':
        ardrone.spinRight();
        break;
      case 'l':
        ardrone.spinLeft();
        break;
      case 'u':
        ardrone.up(30);
        break;
      case 'd':
        ardrone.down(30);
        break;
      case '1':
        ardrone.setHorizontalCamera();
        break;
      case '2':
        ardrone.setHorizontalCameraWithVertical();
        break;
      case '3':
        ardrone.setVerticalCamera();
        break;
      case '4':
        ardrone.setVerticalCameraWithHorizontal();
        break;
      case '5':
        ardrone.toggleCamera();
        break;
      case 'a':
        autoMode = true;
        break;
    }
  }
}
