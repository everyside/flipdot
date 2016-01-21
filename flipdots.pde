import processing.video.*;

color black = color(0);
color white = color(255);

static final PVector inputVideoSize = new PVector(320, 240);
static final PVector simulatorPixelSize = new PVector(8, 8);
static final PVector simulatorPixelPadding = new PVector(1, 1);


static final int frameWidth = 28 * 4;
static final int frameHeight = 7 * 8;

final PImage frame = createImage(frameWidth, frameHeight, ALPHA);

boolean dirty = true;
Capture video;

void setup() {
  //this call cannot use variables, but should be set to simulatorPixelSize * currentFrame.size
  size(896, 448);

  frameRate(2);

  //Set color ranages
  colorMode(HSB, 360, 100, 100, 100);

  background(0, 0, 0, 1);
  strokeWeight(0);
  ellipseMode(CORNER);

  thread("startCamera");


  noCursor();
  smooth();
}

void startCamera() {
  // Start capturing images from the camera
  video = new Capture(this, int(inputVideoSize.x), int(inputVideoSize.y));
  video.start();
}

void draw() {
  if (dirty) {
    drawToSimualtor();
    drawToDevice();
    dirty = false;
  }
}

void drawToSimualtor() {
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

void clearSimulator() {
  clear();
}

void drawToDevice() {
  //TODO - send the current frame data to a device

    for (int col=0; col<frameWidth; col++) {
    //loop through items in column
    pushMatrix();
    for (int row=0; row<frameHeight; row++) {
      //Get the color of the pixel
      int val = frame.pixels[(row * frameWidth)+col];
    }
    popMatrix();
  }
}

void processOutputPixel(Capture c, int x, int y) {

  int mappedX = int(((float)x/frameWidth) * inputVideoSize.x);
  int mappedY = int(((float)y/frameHeight) * inputVideoSize.y);

  int val = int(brightness(c.get(mappedX, mappedY)));
  val = val > 40 ? 100:0;

  frame.set(x, y, val);
}

void captureEvent(Capture c) {
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

