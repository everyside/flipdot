import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class flipdots extends PApplet {



int black = color(0);
int white = color(255);

static final PVector inputVideoSize = new PVector(320, 240);
static final PVector simulatorPixelSize = new PVector(8, 8);
static final PVector simulatorPixelPadding = new PVector(1, 1);


static final int frameWidth = 28 * 4;
static final int frameHeight = 7 * 8;

final PImage frame = createImage(frameWidth, frameHeight, ALPHA);

boolean dirty = true;
Capture video;

public void setup() {
  //this call cannot use variables, but should be set to simulatorPixelSize * currentFrame.size
  

  frameRate(2);

  //Set color ranages
  colorMode(HSB, 360, 100, 100, 100);

  background(0, 0, 0, 1);
  strokeWeight(0);
  ellipseMode(CORNER);

  thread("startCamera");


  noCursor();
  
}

public void startCamera() {
  // Start capturing images from the camera
  video = new Capture(this, PApplet.parseInt(inputVideoSize.x), PApplet.parseInt(inputVideoSize.y));
  video.start();
}

public void draw() {
  if (dirty) {
    drawToSimualtor();
    drawToDevice();
    dirty = false;
  }
}

public void drawToSimualtor() {
  clearSimulator();
  //loop through columns.
  for (int col=0; col<frameWidth; col++) {
    //loop through items in column
    pushMatrix();
    for (int row=0; row<frameHeight; row++) {
      //Get the color of the pixel
      int val = frame.pixels[(row * frameWidth)+col];
      //System.out.println(val);
      fill(360, 0, 100, val);

      //System.out.println(currentFrame.pixels[(row * currentFrame.width)+col]);
      //Draw a representation of the current pixel
      //System.out.println("drawing : " + col + ", "+row + " : " + (currentFrame.pixels[(row * currentFrame.width)+col]));
      ellipse(simulatorPixelPadding.x, 
        simulatorPixelPadding.y, 
        simulatorPixelSize.x - (simulatorPixelPadding.x * 2), 
        simulatorPixelSize.y - (simulatorPixelPadding.y * 2));

      translate(0, simulatorPixelSize.y);
    }
    popMatrix();
    translate(simulatorPixelSize.x, 0);
  }
}

public void clearSimulator() {
  clear();
}

public void drawToDevice() {
  //TODO - send the current frame data to a device

  StringBuilder sb = new StringBuilder();
  for (int col=0; col<frameWidth; col++) {
    //loop through items in column
    pushMatrix();
    for (int row=0; row<frameHeight; row++) {
      //Get the color of the pixel
      int val = frame.pixels[(row * frameWidth)+col];
      sb.append(val);
      sb.append(",");
    }
    popMatrix();
  }
  System.out.println(sb.toString());
}

public void processOutputPixel(Capture c, int x, int y) {

  int mappedX = PApplet.parseInt(((float)x/frameWidth) * inputVideoSize.x);
  int mappedY = PApplet.parseInt(((float)y/frameHeight) * inputVideoSize.y);

  int val = PApplet.parseInt(brightness(c.get(mappedX, mappedY)));
  val = val > 70 ? 100:0;

  frame.set(x, y, val);
}

public void captureEvent(Capture c) {
  c.read();
  if (!dirty) {
    dirty = true;
    c.loadPixels();

    //loop through columns.
    for (int col=0; col<frameWidth; col++) {
      //loop through items in column
      for (int row=0; row<frameHeight * 2; row++) {
        //Transmongel the color of the output pixel from the input
        processOutputPixel(c, col, row);
      }
    }
  }
}
  public void settings() {  size(896, 448);  smooth(); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "--present", "--window-color=#666666", "--hide-stop", "flipdots" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
