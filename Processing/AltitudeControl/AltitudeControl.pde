import com.shigeodayo.ardrone.processing.*;

ARDroneForP5 ardrone;

boolean video720p = false;
boolean autoMode = false;

float REF_altitude = 850.0;
float GAIN = 0.4;
float thA = 10.0;

PrintWriter output;

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

  output = createWriter("data.txt");
}

void draw() {
  background(204);
  textSize(height / 12);

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
  float altitude = ardrone.getAltitude();
  int battery = ardrone.getBatteryPercentage();
  text("altitude: " + altitude, 0, 100);
  text("battery: " + battery + "%", 0, height - 10);

  // proportional control
  float P_INPUT = min(abs(GAIN * (REF_altitude - altitude)), 50);


  if (altitude < REF_altitude - thA) {
    text("up", width / 128, height / 12);
    if (autoMode) {
      // ardrone.up();
      ardrone.up((int)P_INPUT); // proportional control
    }
    return;
  } else if (altitude > REF_altitude + thA) {
    text("down", width / 128, height /12);
    if (autoMode) {
      // ardrone.down();
      ardrone.down((int)P_INPUT);
    }
    return;
  } else {
    text("hover", width / 128, height / 12);
    if (autoMode) {
      ardrone.stop();
    }
  }

  String data = nf(altitude, 3, 1) + ", " + nf(P_INPUT, 3, 0);
  output.println(millis() + ", " + data);
}

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
        output.flush();
        output.close();
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
        ardrone.up();
        break;
      case 'd':
        ardrone.down();
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



