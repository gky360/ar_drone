import com.shigeodayo.ardrone.processing.*;

import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.opengl.*;
import javax.media.opengl.*;

ARDroneForP5 ardrone;

boolean video720p = false;

boolean isFinal = false;

Tracker tracker;
int numTargets = 4;
int numMarkersTarget = 2;
float targetWidth = 49.0f; // [cm]
// float targetWidth = 30.0f;
String unit = "cm";
int lineCount = 20;

int NONE = numTargets;
boolean targetIdCandidates[] = { true, true, true, true, false };
int statusNum = 1;
boolean visitedSa = false;
int targetId = 0;
int lastTargetId = -1;
int targetParam = 0;
int targetParamMax = 7;
int targetParamCounter = 0;
int targetParamCounterMax = 1;
boolean happy = true;

//FINAL******************************************
int F_Ftimer = 0;
int F_start = 0;
int F_tlim_8 = 140;
int F_tlim_9 = 180;
int C_S_timer = 0;
int C_S_tlim = 5;
boolean C_status = false;
int F_Htimer = 0;
int F_HtimerUnit = 30;
//FINAL******************************************




boolean autoMode = false;

int Htimer = 0;
int HtimerUnit = 30;
int start = 0;
int Ftimer = 0;
int tlim1 = 120;
int GId = 0;
boolean GG = false;
boolean Sstep = false;
int Stimer = 0;
int Slim = 50;

int Btimer = 0;
int Wtimer = 0;
boolean hassha = false;
int spinT = 0;
int walkT = 0;
int hoverT = 0;
boolean direc = false;
int B1lim1 = 75;
int B1lim2 = 80 + B1lim1;
int B1lim3 = 20 + B1lim2;
int B2lim1 = 10;
int B2lim2 = 60 + B2lim1;
int B2lim3 = 30 + B2lim2;
int B3lim1 = 20;
int B3lim2 = 60 + B3lim1;
int B3lim3 = 20 + B3lim2;

float pre_z = 0.0;
float pre_w = 0.0;
float last_q = 0.0;

String ftos(float val, int left_digits, int right_digits) {
  return ((val < 0.0) ? "-" : "  ") + nf(abs(val), left_digits, right_digits);
}

boolean omottatoori(float ref_q, float ref_y, float ref_z, float ref_w, boolean isCenter, boolean isLanding) {

  if (targetId != lastTargetId) {
    // target has changed
    last_q = -90.0;
  }
  lastTargetId = targetId;
  float gain_rotate = 0.5;
  float input_rotate = constrain(gain_rotate * (last_q - ref_q), -20, 20);

  float th_q = 3;
  float th_y = 50;
  float th_z = 50;
  float th_w = 100;
  float gain_q = 4;
  float gain_y = 0.4;
  float gain_z = 0.04;
  float gain_dz = 1.5;
  float gain_w = 0.03;
  float gain_dw = 1.0;

  if (!targetIdCandidates[targetId]) {
    targetId = NONE;
  }
  if (targetId == NONE) {
    for (int i = 0; i < numTargets; i++) {
      if (targetIdCandidates[i] && tracker.IsExistTarget(i)) {
        targetId = i;
        break;
      }
    }
  }
  if (targetId == NONE || !tracker.IsExistTarget(targetId)) {
    if (abs(last_q - ref_q) >= th_q * 2) {
      if (input_rotate >= 0.0) {
        text("searchLeft", width/128, height / lineCount);
        if (autoMode) {
          ardrone.spinLeft((int)abs(input_rotate));
        }
      } else {
        text("searchRight", width/128, height / lineCount);
        if (autoMode) {
          ardrone.spinRight(20);
        }
      }
    } else {
      text("searchBackward", width/128, height / lineCount);
      if (autoMode) {
        ardrone.backward(5);
      }
    }
    float ReF_altitude = 1300;
    float GAIN_altitude = 0.4;
    float th_altitude = 200;
    float altitude_rotate = ardrone.getAltitude();
    float P_INPUT_rotate = min(abs(GAIN_altitude * (ReF_altitude -altitude_rotate)), 30);
    if(altitude_rotate <ReF_altitude -th_altitude){
      if(autoMode){
        ardrone.up((int)P_INPUT_rotate);
      }
    }
    else if(altitude_rotate >ReF_altitude +th_altitude){
      if(autoMode){
        ardrone.down((int)P_INPUT_rotate);
      }
    }
    return false;
  }

  // get marker position
  PVector P = tracker.GetTargetPosition(targetId);
  PVector R = tracker.GetCameraRotationYawPitchRoll(targetId);
  float q = atan(P.x / P.z) * 180 / PI;
  last_q = q;
  float x = P.x *  10; //[cm -> mm]
  float y = P.y *  10; //[cm -> mm]
  float z = P.z * -10; //[cm -> mm]
  float w = sqrt(P.x * P.x * 100 + z * z)/*z*/ * tan(R.y + atan(P.x / P.z));
  float roll = R.y * 180/PI;
  text(nfp(q/1000,1,3) + ", " + nfp(y/1000,1,3) + ", " + nf(z/1000,2,3), width/128*50, height / lineCount);

  float the = roll-q;
  float the1 = the*PI/180;
  float z1=z*cos(the1)+x*sin(the1);
  float x1=z*sin(the1)-x*cos(the1);

  float input_q = min(abs(gain_q * (q - ref_q)), 40);
  float input_y = min(abs(gain_y * (y - ref_y)), 50);
  float input_z = constrain(gain_z * (z - ref_z) + gain_dz * (z - pre_z), -25, 25);
  float input_w = constrain(gain_w * (w - ref_w) + gain_dw * (w - pre_w), -25, 25);
  boolean isInRange = true;

  // display the distance to the marker
  float d = tracker.GetTargetDistance(targetId)*10; // sqrt(x * x + y * y + z * z);
  text(ftos(d, 4, 2) + ((1000 <= d && d <= 2000 && !isCenter) ? " Happy!!" : ""), width / 128 * 50, height / lineCount * 2);
  text("q: " + ftos(q, 3, 2) + " input_q: " + ftos(input_q, 2, 2), width / 128 * 50, height / lineCount * 3);
  text("y: " + ftos(y, 3, 2) + " input_y: " + ftos(input_y, 2, 2), width / 128 * 50, height / lineCount * 4);
  text("z: " + ftos(z, 3, 2) + " input_z: " + ftos(input_z, 2, 2) + " dz: " + ftos(z - pre_z, 3, 2), width / 128 * 50, height / lineCount * 5);
  text("w: " + ftos(w, 3, 2) + " input_w: " + ftos(input_w, 2, 2) + " dw: " + ftos(w - pre_w, 3, 2), width / 128 * 50, height / lineCount * 6);
  text("R.y: " + ftos(R.y * 180/PI, 3, 2) + " atan: " + ftos(atan(P.x / P.z) * 180/PI, 3, 2) + " R.y+atan: " + ftos((R.y + atan(P.x / P.z)) * 180/PI, 3, 2), width / 128 * 50, height / lineCount * 7);
  text("input_rotate: " + ftos(input_rotate, 2, 2) + " last_q: " + ftos(last_q, 4, 2), width / 128 * 50, height / lineCount * 8);

  pre_z = z;
  pre_w = w;

  for (int i = 0; i < targetParamMax; ++i) {
    switch (targetParam) {
      case 6:
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
      case 5:
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

  if (isCenter) {
    return (abs(z - ref_z) < 150 && abs(y - ref_y) < th_y);
  }
  if (isLanding) {
    return (((-10<=q) && (q <= 10)&&(-500<=y)&&(y<=500)&&abs(z-ref_z)<=200&&abs(w-ref_w)<=200)||(abs(x1-1800)<=200&&abs(z1-3850)<=200));
  }
  return (1000 <= d && d <= 2000);

}

boolean mikiri_hassha (boolean mikiri, int spin_time, int walk_time, int hover_time, boolean direction) { //(direction = true) => spinRight
  text("Btimer: " + ftos(Btimer, 2, 2) + " Wtimer: " + ftos(Wtimer, 2, 2), width / 128 * 50, height / lineCount * 18);
  if (mikiri) {
    if (Btimer < spin_time) {
      if (direction){
        ardrone.spinRight(50);
        Btimer ++;
      }
      else {
        ardrone.spinLeft(50);
        Btimer ++;
      }
      return true;
    }
    else if(Btimer >= spin_time && Btimer < walk_time) {
      ardrone.backward(20);
      Btimer ++;
      return true;
    }
    else if (Btimer >= walk_time && Btimer < hover_time) {
      ardrone.stop();
      Btimer ++;
      return true;
    }
    else if (Btimer >= hover_time) {
      mikiri = false;
      return false;
    }
  }
  return false;
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

void kesshou() {

  float ref_q = 0.0;
  float ref_y = 0.0;
  float ref_z = 0.0;
  float ref_w = 0.0;
  boolean isCenter = false;
  boolean isLanding = false;

  isLanding = false;
  switch (statusNum) {
    case 0:
    case 1:
      targetIdCandidates[0] = true;
      targetIdCandidates[1] = false;
      targetIdCandidates[2] = false;
      targetIdCandidates[3] = false;
      ref_q = 0.0;
      ref_y = 0.0;
      ref_z = 1500.0;
      ref_w = 0.0;
      isCenter = false;
      C_status = false;
      break;
    case 2:
      targetIdCandidates[0] = true;
      targetIdCandidates[1] = false;
      targetIdCandidates[2] = false;
      targetIdCandidates[3] = false;
      ref_q = 0.0;
      ref_y = 0.0;
      ref_z = 4000.0;
      ref_w = 3000.0;
      isCenter = true;
      C_status = true;
      break;
    case 3:
      targetIdCandidates[0] = false;
      targetIdCandidates[1] = true;
      targetIdCandidates[2] = false;
      targetIdCandidates[3] = false;
      ref_q = 0.0;
      ref_y = 0.0;
      ref_z = 1500.0;
      ref_w = 0.0;
      isCenter = false;
      C_status = false;
      break;
    case 4:
      targetIdCandidates[0] = false;
      targetIdCandidates[1] = true;
      targetIdCandidates[2] = false;
      targetIdCandidates[3] = false;
      ref_q = 0.0;
      ref_y = 0.0;
      ref_z = 4000.0;
      ref_w = -3000.0;
      isCenter = true;
      C_status = true;
      break;
    case 5:
      targetIdCandidates[0] = false;
      targetIdCandidates[1] = false;
      targetIdCandidates[2] = true;
      targetIdCandidates[3] = true;
      ref_q = 0.0;
      ref_y = 0.0;
      ref_z = 1500.0;
      ref_w = 0.0;
      if (targetId == 2) {
        visitedSa = true;
      } else {
        visitedSa = false;
      }
      isCenter = false;
      C_status = false;
      break;
    case 6:
      targetIdCandidates[0] = true;
      targetIdCandidates[1] = true;
      targetIdCandidates[2] = false;
      targetIdCandidates[3] = false;
      ref_q = 0.0;
      ref_y = 0.0;
      ref_z = 4000.0;
      if (targetId == 0) {
        ref_w = 3000.0;
      } else if (targetId == 1) {
        ref_w = -3000.0;
      } else {
        ref_w = 0.0;
      }
      isCenter = true;
      C_status = true;
      break;
    case 7:
      targetIdCandidates[0] = false;
      targetIdCandidates[1] = false;
      targetIdCandidates[2] = !visitedSa;
      targetIdCandidates[3] = visitedSa;
      ref_q = 0.0;
      ref_y = 0.0;
      ref_z = 1500.0;
      ref_w = 0.0;
      isCenter = false;
      C_status = false;
      break;
    case 8:
      targetIdCandidates[0] = true;
      targetIdCandidates[1] = true;
      targetIdCandidates[2] = false;
      targetIdCandidates[3] = false;
      ref_q = 0.0;
      ref_y = -500.0;
      ref_z = 5000.0;
      if (targetId == 0) {
        ref_w = 3000.0;
      } else if (targetId == 1) {
        ref_w = -3000.0;
      } else {
        ref_w = 0.0;
      }
      isCenter = true;
      isLanding = true;
      C_status = false;
      break;
    case 9:
      // landing!!!!!
      ardrone.landing();
      return;
  }

  //F_Ftimer
  if(F_start > 0) {
    F_Ftimer = millis() - F_start;
  }

  //Hover Timer
  if(omottatoori(ref_q, ref_y, ref_z, ref_w, isCenter, isLanding)) {
    if (statusNum == 8) {
      statusNum = 9;
    }
    if (F_Htimer < 10 * F_HtimerUnit) F_Htimer ++;
    else {
      F_Htimer = 0;
      statusNum ++;
      // C_status = true;
    }
  }

  //Walk Timer
  if(C_status == true && targetId != NONE) {
    if (C_S_timer < C_S_tlim * F_HtimerUnit ) C_S_timer ++;
    else {
      C_S_timer = 0;
      C_status = false;
      statusNum ++;
    }
  }

  //Status 8 limit
  if (F_Ftimer/1000 >= F_tlim_8) {
    statusNum = 8;
  }
  //Status 9 limt
  if (F_Ftimer/1000 >= F_tlim_9) {
    statusNum = 9;
  }

  return;

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


  if (isFinal) {
    if(!GG){
      if (targetId == NONE) {
        String str = "[@" + statusNum + "] Searching";
        for (int i = 0; i < numTargets; i++) {
          if (targetIdCandidates[i]) {
            str += " #" + i;
          }
        }
        text(str, 0, 200);
      } else {
        text("[@" + statusNum + "], Go to #" + targetId, 0, 200);
      }
    } else {
      text("[@" + statusNum + "], Go to #GOAL", 0, 200);
    }
  } else {
    if (!GG) {
      text("Go to #" + targetId, 0, 200);
    } else {
      text("Go to #GOAL", 0,200);
    }
  }
  text("isFinal: " + (isFinal ? "true" : "false"), 0, 200 + height / lineCount);

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

  if (isFinal) {
    text("F_Htime:" + F_Htimer/F_HtimerUnit +" F_Ftime:" + F_Ftimer/1000 +" C_S_time:" + C_S_timer/F_HtimerUnit, width-400,height / lineCount * (lineCount - 3));
    kesshou();
    return;
  }

  if(hassha){
    if(targetId == 0){
      spinT = B1lim1;
      walkT  = B1lim2;
      hoverT = B1lim3;
      direc  = false;
      if (Btimer >= hoverT){
        Btimer = 0;
        targetId = 1;
        hassha = false;
      }
    }
    else if(targetId == 1){
      spinT = B2lim1;
      walkT  = B2lim2;
      hoverT = B2lim3;
      direc  = true;
      if (Btimer >= hoverT) {
        Btimer = 0;
        targetId = 3;
        hassha = false;
      }
    }
    else if(targetId == 3){
      spinT = B1lim1;
      walkT  = B1lim2;
      hoverT = B1lim3;
      direc  = false;
      if (Btimer >= hoverT) {
        Btimer = 0;
        targetId = 2;
        hassha = false;
      }
    }
    else if(targetId == 2){
      spinT = B3lim1;
      walkT  = B3lim2;
      hoverT = B3lim3;
      direc  = true;
      if (Btimer >= hoverT) {
        Btimer = 0;
        targetId = GId;
        hassha = false;
        GG = true;
      }
    }
  }

  if (mikiri_hassha(hassha, spinT, walkT, hoverT, direc)) {
    text("mikiri now",width/128, height/12);
  }
  else {
    if (omottatoori(0.0, 0.0, 1500, 0.0, false, false)) {
      if(Htimer < 10*HtimerUnit){
        Htimer ++ ; //target timer
      }
      else if(Htimer >= 10*HtimerUnit){
        Htimer = 0;
        hassha = true;
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
      if(targetId >= numTargets) targetId = 0;
    }
    else if (key == 'a') {
      autoMode = true;
      start = millis();
      F_start = millis(); //********************************************************FINAL
    }
    else if (key == 'n') {
      statusNum = (statusNum + 1) % 9;
    }
    else if (key == 'f') {
      if (isFinal) {
        isFinal = false;
        targetIdCandidates[0] = true;
        targetIdCandidates[1] = true;
        targetIdCandidates[2] = true;
        targetIdCandidates[3] = true;
      } else {
        isFinal = true;
        statusNum = 1;
        targetId = NONE;
      }
    }
  }
}

