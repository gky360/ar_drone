import com.shigeodayo.ardrone.processing.*;

import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.opengl.*;
import javax.media.opengl.*;

ARDroneForP5 ardrone;

boolean video720p = false;

Tracker tracker;
int numTargets = 4;
int numMarkersTarget = 2;
// float targetWidth = 49.0f; // [cm]
float targetWidth = 25.7f;          
String unit = "cm";
int lineCount = 20;

int targetId = 3;
int targetParam = 0;
int targetParamMax = 5;
int targetParamCounter = 0;
int targetParamCounterMax = 1;

boolean autoMode = false;

int Htimer = 0;
int HtimerUnit = 1000000;     
int start = 0;
int Ftimer = 0;
int tlim1 = 120;
int GId = 0;
boolean GG = false;
boolean Sstep = false;
int Stimer = 0;
int Slim = 50;
boolean Bstep1 = false;
int Btimer = 0;
int B1lim1 = 40;
int B1lim2 = 65 + B1lim1;
int B1lim3 = 20 + B1lim2;
boolean Bstep2 = false;
int B2lim1 = 10;
int B2lim2 = 50 + B2lim1;
int B2lim3 = 20 + B2lim2;

float pre_z = 0.0;
float pre_w = 0.0;

String ftos(float val, int left_digits, int right_digits) {
  return ((val < 0.0) ? "-" : "  ") + nf(abs(val), left_digits, right_digits);
}

boolean omottatoori(float ref_q, float ref_y, float ref_z, float ref_w) {

  // not found
  if (!tracker.IsExistTarget(targetId)) {
    text("backward (not tracking)", width/128, height / lineCount);
    // text("rotate", width/128, height / lineCount);
    if (autoMode) {
      ardrone.backward(1);
      // ardrone.spinRight(20);
    }
    return false;
  }

  // get marker position
  PVector P = tracker.GetTargetPosition(targetId);
  PVector R = tracker.GetCameraRotationYawPitchRoll(targetId);
  float q = atan(P.x / P.z) * 180 / PI;
  float y = P.y *  10; //[cm -> mm]
  float z = P.z * -10; //[cm -> mm]
  float w = sqrt(P.x * P.x * 100 + z * z) * tan(R.y + atan(P.x / P.z));
  text(nfp(q/1000,1,3) + ", " + nfp(y/1000,1,3) + ", " + nf(z/1000,2,3), width/128*50, height / lineCount);

  float th_q = 3;
  float th_y = 50;
  float th_z = 50;
  float th_w = 100;
  float gain_q = 4;
  float gain_y = 0.4;
  float gain_z = 0.05;
  float gain_dz = 1;
  float gain_w = 0.05;
  float gain_dw = 0.5;
  float input_q = min(abs(gain_q * (q - ref_q)), 40);
  float input_y = min(abs(gain_y * (y - ref_y)), 30);
  float input_z = constrain(gain_z * (z - ref_z) + gain_dz * (z - pre_z), -15, 15);
  float input_w = constrain(gain_w * (w - ref_w) + gain_dw * (w - pre_w), -30, 30);
  boolean isInRange = true;

  // display the distance to the marker
  float d = tracker.GetTargetDistance(targetId)*10; // sqrt(x * x + y * y + z * z);
  text(ftos(d, 4, 2) + ((1000 <= d && d <= 2000) ? " Happy!!" : ""), width / 128 * 50, height / lineCount * 2);
  text("q: " + ftos(q, 3, 2) + " input_q: " + ftos(input_q, 2, 2), width / 128 * 50, height / lineCount * 3);
  text("y: " + ftos(y, 3, 2) + " input_y: " + ftos(input_y, 2, 2), width / 128 * 50, height / lineCount * 4);
  text("z: " + ftos(z, 3, 2) + " input_z: " + ftos(input_z, 2, 2) + " dz: " + ftos(z - pre_z, 3, 2), width / 128 * 50, height / lineCount * 5);
  text("w: " + ftos(w, 3, 2) + " input_w: " + ftos(input_w, 2, 2) + " dw: " + ftos(w - pre_w, 3, 2), width / 128 * 50, height / lineCount * 6);
  text("R.y: " + ftos(R.y * 180/PI, 3, 2) + " atan: " + ftos(atan(P.x / P.z) * 180/PI, 3, 2) + " R.y+atan: " + ftos((R.y + atan(P.x / P.z)) * 180/PI, 3, 2), width / 128 * 50, height / lineCount * 7);
  text("sqrt_x^2+z^2: " + ftos(sqrt(P.x * P.x * 100 + z * z), 3, 2), width / 128 * 50, height / lineCount * 8);

  pre_z = z;
  pre_w = w;

  for (int i = 0; i < targetParamMax; ++i) {
    switch (targetParam) {
      case 0:
        // q
        if ((q - ref_q) > th_q) {
          text("spinLeft", width/128, height / lineCount * 3);
          if (autoMode) ardrone.spinLeft((int)input_q);
          isInRange = false;
        } else if ((q - ref_q) < -th_q) {
          text("spinRight", width/128, height / lineCount * 3);
          if (autoMode) ardrone.spinRight((int)input_q);
          isInRange = false;
        }
        break;
      case 1:
        // w
        // if (abs(q) < th_q * 2 && abs(w - ref_w) >= th_w) {
        if (abs(w - ref_w) >= th_w) {
          if (input_w >= 0.0) {
            text("goLeft", width/128, height / lineCount * 4);
            if (autoMode) ardrone.goLeft((int)abs(input_w));
            isInRange = false;
          } else {
            text("goRight", width/128, height / lineCount * 4);
            if (autoMode) ardrone.goRight((int)abs(input_w));
            isInRange = false;
          }
        }
        // }
        break;
      case 2:
        // y
        if ((y - ref_y) > th_y) {
          text("down", width/128, height / lineCount * 5);
          if (autoMode) ardrone.down((int)abs(input_y));
          isInRange = false;
        } else if ((y - ref_y) < -th_y) {
          text("up", width/128, height / lineCount * 5);
          if (autoMode) ardrone.up((int)abs(input_y));
          isInRange = false;
        }
        break;
      case 3:
      case 4:
        // z
        if (abs(z - ref_z) >= th_z) {
          if (input_z >= 0.0) {
            text("forward", width/128, height / lineCount * 6);
            if (autoMode) ardrone.forward((int)abs(input_z));
          } else {
            text("backward", width/128, height / lineCount * 6);
            if (autoMode) ardrone.backward((int)abs(input_z));
          }
          isInRange = false;
        }
        break;
    }
    if (!isInRange) {
      break;
    }
    targetParamCounter = 0;
    targetParam = (targetParam + 1) % (targetParamMax);
  }

  if (isInRange) {
    text("nothing", width/128, height / lineCount * 1);
    // if (autoMode) ardrone.stop();
  }

  text("targetParam: " + targetParam, width/128, height / lineCount * 2);
  if (targetParamCounter >= targetParamCounterMax) {
    targetParamCounter = 0;
    targetParam = (targetParam + 1) % (targetParamMax);
  } else {
    targetParamCounter++;
  }

  return (1000 <= d && d <= 2000);

}

void setup() {
  if (video720p) {
    size(1280, 720, P3D);
  }
  else {
    size(640, 360, P3D);
  }
  colorMode(RGB, 100);

  tracker = new Tracker(this, width, height, numTargets, numMarkersTarget, targetWidth, unit);

  ardrone=new ARDroneForP5("192.168.1.1");
  // connect to the AR.Drone
  ardrone.connect(video720p);
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
  // true: resizeing image automatically
  // false: not resizing
  PImage img = ardrone.getVideoImage(true);
  if (img == null)
    return;

  hint(DISABLE_DEPTH_TEST);
  image(img, 0, 0);
  hint(ENABLE_DEPTH_TEST);

  tracker.Detect(img);
  background(0);
  tracker.DrawBackground(img);

  for (int i=0; i<numTargets; i++) {
    if (!tracker.IsExistTarget(i)) {
      continue;
    }

    // draw marker contour
    int step = 360 / numTargets;
    PVector[] v = tracker.GetTargetCurrentMarkerVertex2D(i);
    colorMode(HSB, 360, 100, 100, 100);
    stroke(i*step, 100, 100, 100);
    strokeWeight(4);
    noFill();
    beginShape();
    vertex(v[0].x, v[0].y);
    vertex(v[1].x, v[1].y);
    vertex(v[2].x, v[2].y);
    vertex(v[3].x, v[3].y);
    endShape(CLOSE);

    // Target 2 camera matrix
    PMatrix3D T2C = tracker.GetTargetMatrix(i);

    // draw marker-image sized box
    tracker.BeginTransform(T2C);
    fill(i*step, 100, 100, 50);
    box(0.7 * tracker.GetTargetCurrentMarkerWidth(i));
    tracker.EndTransform();
  }

  // draw status bar
  colorMode(RGB, 256, 256, 256, 100);
  fill(0, 0, 0, 50);
  noStroke();
  rect(0, 0, width, height/9);
  fill(255, 255, 255);
  textSize(height / lineCount);

  if(!GG){
    text("Go to #" + targetId, 0, 200);
  } else {
    text("Go to #GOAL", 0,200);
  }

  // print out AR.Drone information
  ardrone.printARDroneInfo();

  // getting sensor information of AR.Drone
  int battery = ardrone.getBatteryPercentage();
  text("battery:" + battery + " %", 0, height-10);

  //Ftimer
  if(start > 0){
    Ftimer = millis() - start;
  }
  if(Ftimer/1000 < tlim1){
    text("Htime:" + Htimer/HtimerUnit +" Ftime:" + Ftimer/1000, width-400,height / lineCount * (lineCount - 1));
  }
  else if (Ftimer/1000 >= tlim1){
    ardrone.landing();
    autoMode  = false;
    text("GOAL...?", width-400,100);
    return;
  }

  if (Bstep1 == true) {
    if (Btimer < B1lim1) {
      ardrone.spinLeft(50);
      Btimer ++;
    }
    else if (Btimer >= B1lim1 && Btimer < B1lim2) {
      ardrone.backward((20));
      Btimer ++;
    }
    else if (Btimer >= B1lim2 && Btimer < B1lim3) {
      ardrone.stop();
      Btimer ++;
    }
    else {
      Btimer = 0;
      Bstep1 = false;
    }
  }
  if (Bstep2 == true) {
    if (Btimer < B2lim1) {
      ardrone.spinRight(50);
      Btimer ++;
    }
    else if (Btimer >= B2lim1 && Btimer < B2lim2) {
      ardrone.backward((20));
      Btimer ++;
    }
    else if (Btimer >= B2lim2 && Btimer < B2lim3) {
      ardrone.stop();
      Btimer ++;
    }
    else {
      Btimer = 0;
      Bstep2 = false;
    }
  }
  else if(Sstep == true) {
    if (Stimer < Slim) {
      ardrone.goRight((20));
      Stimer ++;
    }
    else {
      Stimer = 0;
      Sstep = false;
      ardrone.stop();
    }
  }
  else{
    if (omottatoori(0.0, 0.0, 1500, 0.0)) {
      if(Htimer < 10*HtimerUnit){
        Htimer ++ ; //target timer
      }
      else if(Htimer >= 10*HtimerUnit){
        Htimer = 0;
        if(targetId == 0){
          targetId = 1;
          Bstep1 = true;
        }
        else if(targetId == 1){
          targetId = 3;
          Bstep2 = true;//******************** add
        }
        else if(targetId == 3){
          targetId = 2;
          Bstep1 = true;//******************** add
        }
        else if(targetId == 2){
          targetId = GId;
          Bstep2 = true;//******************** add
          GG = true;
        }
      }
    }
  }

}

// controlling AR.Drone through key input
void keyReleased() {
  ardrone.stop(); // hovering
}

void keyPressed() {
  autoMode = false;

  if (key == CODED) {
    if (keyCode == UP) {
      ardrone.forward((20)); // go forward
    }
    else if (keyCode == DOWN) {
      ardrone.backward((20)); // go backward
    }
    else if (keyCode == LEFT) {
      ardrone.goLeft((20)); // go left
    }
    else if (keyCode == RIGHT) {
      ardrone.goRight((20)); // go right
    }
    else if (keyCode == SHIFT) {
      ardrone.takeOff(); // take off, AR.Drone cannot move while landing
      tracker.LogEvent("takeoff");
    }
    else if (keyCode == CONTROL) {
      ardrone.landing(); // landing
      tracker.LogEvent("landing");
    }
    else if (keyCode == ALT) {
      ardrone.reset(); // reset
    }
  }
  else {
    if (key == 's') {
      ardrone.stop(); // hovering
    }
    else if (key == 'r') {
      ardrone.spinRight(50); // spin right
    }
    else if (key == 'l') {
      ardrone.spinLeft(50); // spin left
    }
    else if (key == 'u') {
      ardrone.up(50); // go up
    }
    else if (key == 'd') {
      ardrone.down(50); // go down
    }
    else if (key == '1') {
      ardrone.setHorizontalCamera(); // set front camera
    }
    else if (key == '2') {
      ardrone.setHorizontalCameraWithVertical(); // set front camera with second camera (upper left)
    }
    else if (key == '3') {
      ardrone.setVerticalCamera(); // set second camera
    }
    else if (key == '4') {
      ardrone.setVerticalCameraWithHorizontal(); //set second camera with front camera (upper left)
    }
    else if (key == '5') {
      ardrone.toggleCamera(); // set next camera setting
    }
    else if (key == '0') {
      targetId++;
      if(targetId == numTargets) targetId = 0;
    }
    else if (key == 'a') {
      autoMode = true;
      start = millis();
    }
  }
}

