import processing.video.*;
import processing.serial.*;
import java.nio.file.*;

import static java.nio.file.StandardWatchEventKinds.ENTRY_CREATE;
import static java.nio.file.StandardWatchEventKinds.ENTRY_DELETE;
import static java.nio.file.StandardWatchEventKinds.ENTRY_MODIFY;


// 0x80 beginning 
//___________________
// 0x81 - 112 bytes / no refresh / C+3E
// 0x82 - refresh
// 0x83 - 28 bytes of data / refresh / 2C
// 0x84 - 28 bytes of data / no refresh / 2C
// 0x85 - 56 bytes of data / refresh / C+E
// 0x86 - 56 bytes of data / no refresh / C+E
// ---------------------------------------
// address or 0xFF for all
// data ... 1 to nuber of data bytes
// 0x8F end

// panel's speed setting: 1-OFF 2-ON 3 - ON
// panel address : 1 (8 pos dip switch: 1:on 2 -8: off)

// I was sng RS485 Breakout and Duemilanova connected in the following way:
// [Panel]  [RS485]  [Arduino]
// 485+       A  
// 485-       B
//          3-5V    5V
//          RX-I    TX
//          TX-O    Not connected
//           RTS    5V
//           GND    GND



static final PVector inputVideoSize = new PVector(320, 240);
static final PVector simulatorPixelSize = new PVector(8, 8);
static final PVector simulatorPixelPadding = new PVector(1, 1);
static final PVector boardSize = new PVector(28,7);
static final PVector assemblySize = new PVector(4,8);

Serial serial;

final byte[] frame = new byte[int(32 * assemblySize.x * assemblySize.y)];

boolean dirty = false;
Capture video;

void setup() {
  //this call cannot use variables, but should be set to simulatorPixelSize * currentFrame.size
  size(896, 448);
  
  frameRate(10);

  //Set color ranages
  colorMode(HSB, 360, 100, 1, 100);

  background(0, 0, 0, 1);
  strokeWeight(0);
  ellipseMode(CORNER);

  thread("startCamera");


  noCursor();
  smooth();

  serial = new Serial(this, Serial.list()[0], 57600);
}

void startWatchingFileSystem(){
  try{
    WatchService watcher = FileSystems.getDefault().newWatchService();
    Path dir = Paths.get("images/");
    dir.register(watcher, ENTRY_CREATE);
    
    while (true) {
        WatchKey key;
        try {
            // wait for a key to be available
            key = watcher.take();
        } catch (InterruptedException ex) {
            return;
        }
     
        for (WatchEvent<?> event : key.pollEvents()) {
            // get event type
            WatchEvent.Kind<?> kind = event.kind();
     
            // get file name
            @SuppressWarnings("unchecked")
            WatchEvent<Path> ev = (WatchEvent<Path>) event;
            Path fileName = ev.context();
     
            System.out.println(kind.name() + ": " + fileName);
     
            if (kind == OVERFLOW) {
                continue;
            } else if (kind == ENTRY_CREATE) {
     
                // process create event
     
            } else if (kind == ENTRY_DELETE) {
     
                // process delete event
     
            } else if (kind == ENTRY_MODIFY) {
     
                // process modify event
     
            }
        }
     
        // IMPORTANT: The key must be reset after processed
        boolean valid = key.reset();
        if (!valid) {
            break;
        }
    }
  }catch(IOException e){
    log(e.toString());
  }
}

void startCamera() {
  // Start capturing images from the camera
  video = new Capture(this, int(inputVideoSize.x), int(inputVideoSize.y));
  video.start();
}

void draw() {
  if (dirty) {
    drawToSimulator();
    drawToDevice();
    dirty = false;
  }
}

void log(String val){
  System.out.println(val);
}

enum State {
  BEGIN,
  WAITING_FOR_FORMAT,
  WAITING_FOR_ADDRESS,
  WAITING_FOR_PIXEL
}

void drawToSimulator() {
  clearSimulator();
  
  State state = State.BEGIN;
  
  int boardAddress = 0;
  int pixelOffsetX = 0;
  int boardOffsetX = 0;
  int boardOffsetY = 0;
    
  for(int byteNumber = 0;byteNumber<frame.length;byteNumber++){
    byte b = frame[byteNumber];
    
    switch(state) {
      case BEGIN :
        if(b == (byte)0x80){
          state = State.WAITING_FOR_FORMAT;
        }
        break;
      case WAITING_FOR_FORMAT :
        assert(b == (byte)0x83);
        state = State.WAITING_FOR_ADDRESS;
        break;
      case WAITING_FOR_ADDRESS :
        boardAddress = b & 0xff;
        
        //Move to this board
        int colNum = -1;
        int i = 0;
        for(i=boardAddress;i>-1;i=i-8){
          colNum++;
        }
        int rowNum = i + 8;
        
        boardOffsetX = colNum * int(simulatorPixelSize.x) * int(boardSize.x);
        boardOffsetY = rowNum * int(simulatorPixelSize.y) * int(boardSize.y);
        pixelOffsetX = 0;
        
        state = State.WAITING_FOR_PIXEL;
        break;
      default :
      
        if(b == (byte)0x8F){
          
          boardAddress = 0;
          pixelOffsetX = 0;
          boardOffsetX = 0;
          boardOffsetY = 0;
          state = State.BEGIN;
        }else{
          //It's a column of pixels
          //log("Simulating column of pixels " + x + " = '"+toBinary(new byte[]{colByte})+"'");
       
          for (int y = 0; y < boardSize.y; y++) { // Begin a column of pixels
          
            int pixelOffsetY = y * int(simulatorPixelSize.y);
            
            boolean on = (b & (1 << y)) > 0;
            //log("Simulating pixel " + y + " with value '"+brightness+"'");
            fill(360, 0, on?1:0, 100);
            
            //log(""+(boardOffsetX + pixelOffsetX) + " , " + (boardOffsetY + pixelOffsetY));
            ellipse(boardOffsetX + pixelOffsetX + simulatorPixelPadding.x, 
              boardOffsetY + pixelOffsetY + simulatorPixelPadding.y, 
              simulatorPixelSize.x - (simulatorPixelPadding.x * 2), 
              simulatorPixelSize.y - (simulatorPixelPadding.y * 2));
             
          }  //End a column of pixels
           
          //Move beyond the column of pixels
          pixelOffsetX += int(simulatorPixelSize.x);
        }
      }
   }
}

void clearSimulator() {
  clear();
}

void drawToDevice() {
  serial.write(frame);
  //log(toHex(frame));
}

String toBinary( byte[] bytes )
{
    StringBuilder sb = new StringBuilder(bytes.length * Byte.SIZE);
    for( int i = 0; i < Byte.SIZE * bytes.length; i++ ) {
        sb.append((bytes[i / Byte.SIZE] << i % Byte.SIZE & 0x80) == 0 ? '0' : '1');
    }
    return sb.toString();
}

private static String digits = "0123456789abcdef";

public static String toHex(byte[] data){
    StringBuilder buf = new StringBuilder();
    for (int i = 0; i != data.length; i++)
    {
        int v = data[i] & 0xff;
        buf.append(i);
        buf.append(" = '");
        buf.append(digits.charAt(v >> 4));
        buf.append(digits.charAt(v & 0xf));
        
        buf.append("', ");
        
    }
    return buf.toString();
}

void processImage(PImage img) {
  
  //img.resize(int(assemblySize.x * boardSize.x), int(assemblySize.y * boardSize.y));
  
  
  //img.filter(ERODE);
  //img.filter(THRESHOLD, 0.5);
  
  
  img.filter(POSTERIZE, 2);
  img.filter(INVERT);
  img.loadPixels();
  
  int offset = 0;
  int boardNumber = 0;
  byte[] boardBytes = new byte[32];
  
  for (int bigX=0; bigX<assemblySize.x; bigX++) {
    for (int bigY=0; bigY<assemblySize.y; bigY++) {

      int boardOriginX = bigX * int(boardSize.x);
      int boardOriginY = bigY * int(boardSize.y);
      
      boardBytes[0] = (byte)0x80;
      boardBytes[1] = (byte)0x83;
      boardBytes[2] = (byte)boardNumber++;

      for (int x = 0; x < int(boardSize.x); x++) {
     
        int pixelLocationX = boardOriginX + x;
        byte b = (byte)0x00;
        for (int y = 0; y < int(boardSize.y); y++) {
          
          int pixelLocationY = boardOriginY + y;
          
          if( isOn(img, pixelLocationX, pixelLocationY)){
            b |= 1 << y;
          }
  
        }
        boardBytes[x+3] = b;
        
      }
      
      boardBytes[31] = (byte)0x8f;
      
      for(int i=0;i<boardBytes.length;i++){
        frame[offset++] = boardBytes[i];
      }
      
    }
  }
  
  //log("begin--"+toHex(frame)+"--end");
}

int blurRadius = 0;

boolean isOn(PImage img, int x, int y){
  
  float val = 0;
  int loops = 0;
  for(int i=-blurRadius;i<=blurRadius;i++){
    for(int j=-blurRadius;j<=blurRadius;j++){
      loops++;
      
      
      
      int mappedX = ((int)((img.width / (assemblySize.x * boardSize.x)) * x) + i);
      int mappedY = ((int)((img.height / (assemblySize.y * boardSize.y)) * y) + j);
      
      
      if(brightness(img.get(mappedX,mappedY)) == 1){
        val += 1;
      }
       
    }
  }
  
  val = val / loops;
  
  return val >= 1;
}

void captureEvent(Capture c) {
  c.read();
  if (!dirty) {
    dirty = true;
    c.loadPixels();
    processImage(c);
  }
}