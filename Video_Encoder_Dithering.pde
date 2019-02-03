
/*
 Processing sketch that converts videos into a custom format to be displayed on a Nokia 3310 LCD via Arduino + SD card.
 See https://joeraut.com/blog/playing-video-nokia-3310/ for more info.
 Utilises the Atkinson Dithering Alogrithm, with the implementation courtesy of Windell Oskay: https://www.evilmadscientist.com/2012/dithering/
 A .mov video file (data.mov) is read in, and convered & exported to data.dat.
  Processing 1.5.1 was used, changes will be required for compatibility with Processing 2+.
 */

import processing.opengl.*;


import processing.video.*;

Movie movie;

import java.io.File;

PrintWriter file;

// Number of columns and rows in our system
int cols = 84;
int rows = 48;

int rawVideoRows = round(cols*.75);


int borderWidth = 0;

// Variable for capture device
Capture video;

int mainwidth = 84;
int mainheight = 48;

int[] GrayArray;
int GrayArrayLength;
boolean toggle;

PGraphics pg;

void setup() {

  frameRate(15);
  colorMode(RGB);

  String fileName = dataPath("data.dat");
  File f = new File(fileName);
  if (f.exists()) {
    f.delete(); // delete the video file, so every time the program runs, it starts from the beginning, otherwise it just appends to the file.
  }
  file = createWriter("data.dat");
  write("cr");

  //  size(mainwidth, mainheight, P2D);  // Faster
  size(mainwidth, mainheight, JAVA2D);  // More accurate, in general


  movie = new Movie(this, "video.mov"); // the video file to play and save (better if its 84x48, with a 'good contrast', but any normal resolution 'should' work fine)
  movie.loop();
  pg = createGraphics(84, 48, JAVA2D);

  //video.start(); 
  noSmooth();
  background(0);
}


void draw() { 

  loadPixels();

  float brightTot;
  int pixelCt;
  color c2;
  int idx = 0;

  if (movie.available()) {
    movie.read();

    pg.image(movie, 0, 0, 84, 48);
    pg.loadPixels();

    GrayArrayLength = cols * rawVideoRows;
    int[] GrayArray = new int[GrayArrayLength];

    for (int n = 0; n < GrayArrayLength; n++)
    {
      GrayArray[n] = 0;
    } 

    // Black background:
    background(0);

    // White rectangle, rounded corners:
    fill(255);
    noStroke(); 
    rect(borderWidth, borderWidth, cols, rows);   // Last digit is rounded corners

      noFill(); 
    stroke(0);
    strokeWeight(1);

    int vOffset = floor ((rawVideoRows - rows) / 2);
    int lastRow = (rawVideoRows - vOffset);
    int yBorderTot = borderWidth - vOffset;

    // Begin loop for columns
    for (int i = 0; i < 84;i++) {
      // Begin loop for rows
      for (int j = 0; j < 48; j++) {


        // Where are we, pixel-wise?
        int x = i;
        int y = j;

        //int loc = x+y;

        int loc = x+y*width;

        pixelCt = 0;
        brightTot = 0;

        float brightTemp;

        c2 = pg.pixels[loc];
        brightTemp = brightness(c2);

        // Brightness correction curve:
        brightTemp =  sqrt(255) * sqrt (brightTemp);

        if (brightTemp > 255) 
          brightTemp = 255;

        if (brightTemp < 0)
          brightTemp = 0;

        int darkness = 255 - floor(brightTemp);

        idx = (j)*cols + (i);        

        darkness += GrayArray[idx];

        if ( darkness >= 128) {

          //          rect(x + borderWidth, y + borderWidth - vOffset, 1, 1);  // If using P2D
          point(x + borderWidth, y + 7 + yBorderTot);  // For use with JAVA2D only

          darkness -= 128;
        } 

        int darkn8 = round(darkness / 8);

        // Atkinson dithering algorithm:  http://verlagmartinkoch.at/software/dither/index.html          
        // Distribute error as follows:
        //     [ ]  1/8  1/8
        //1/8  1/8  1/8
        //     1/8 

          if ((idx + 1) < GrayArrayLength)
          GrayArray[idx + 1] += darkn8;
        if ((idx + 2) < GrayArrayLength)
          GrayArray[idx + 2] += darkn8;
        if ((idx + cols - 1) < GrayArrayLength)
          GrayArray[idx + cols - 1] += darkn8;
        if ((idx + cols) < GrayArrayLength)
          GrayArray[idx + cols] += darkn8;
        if ((idx + cols + 1) < GrayArrayLength)
          GrayArray[idx + cols + 1 ] += darkn8;
        if ((idx + 2 * cols) < GrayArrayLength)
          GrayArray[idx + 2 * cols] += darkn8;
      }
    }
    //if (key == 'b') {
    saveDataFrame();
    //}
  }
  else
    println("Video Err.");
}

void saveDataFrame() {
  println("rec...");
  loadPixels();
  file.write((char)124); // clear framebuffer
  for (int y=0; y<48; y++) {
    for (int x=0; x<84; x+=6) {

      int case0 = (red(pixels[x+y*width]) !=255) ? 5 : 0;
      int case1 = (red(pixels[(x+1)+y*width]) !=255) ? 4 : 0;
      int case2 = (red(pixels[(x+2)+y*width]) !=255) ? 3 : 0;
      int case3 = (red(pixels[(x+3)+y*width]) !=255) ? 2 : 0;
      int case4 = (red(pixels[(x+4)+y*width]) !=255) ? 1 : 0;
      int case5 = (red(pixels[(x+5)+y*width]) !=255) ? 1 : 0;

      file.write((char)((((case0!=0)?1:0)<<case0) | (((case1!=0)?1:0)<<case1) | (((case2!=0)?1:0)<<case2) | (((case3!=0)?1:0)<<case3) | (((case4!=0)?1:0)<<case4) | ((case5!=0)?1:0)<<0));
      //println(binary(((((case0!=0)?1:0)<<case0) | (((case1!=0)?1:0)<<case1) | (((case2!=0)?1:0)<<case2) | (((case3!=0)?1:0)<<case3) | (((case4!=0)?1:0)<<case4) | ((case5!=0)?1:0)<<0)));
      //file.write((char)0);
    }
    file.write((char)123); // next line...
  }
  file.write((char)125); // update display, show final image
  file.flush(); // save changes to the file (incase the program crashes at least it saves)
}

void keyPressed() {
  if (key == 's') { // Pressing the 's' key saves the file and stops the program.
    file.flush(); // save changes to the file
    file.close(); // safelty close the file
    println("done");
    exit(); // exits the program (we're done here!)
  }
}

void write(String textToWrite) {
  /*for (int textChars=0; textChars<textToWrite.length(); textChars++) {
   port.write(textToWrite.charAt(textChars));
   }*/
  file.write(textToWrite);
}

