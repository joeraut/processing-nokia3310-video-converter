/*
 Processing sketch that converts videos into a custom format to be displayed on a Nokia 3310 LCD via Arduino + SD card.
 See https://joeraut.com/blog/playing-video-nokia-3310/ for more info.
 In this case, a 3D cube will be rendered and exported to data.dat.
 Processing 1.5.1 was used, changes will be required for compatibility with Processing 2+.
 */

import java.io.File;

PrintWriter file;
int val, i;

void setup() 
{
  size(84, 48, P3D);
  frameRate(30);
  noFill();
  noSmooth();

  String fileName = dataPath("file.txt");
  File f = new File(fileName);
  if (f.exists()) {
    f.delete(); // delete the video file, so every time the program runs, it starts from the beginning, otherwise it just appends to the file.
  }

  file = createWriter("data.dat");
}

void draw() {
  background(255); // white background

  rect(0, 0, width-1, height-1); // border around the screen

  translate(width/2, height/2);
  rotateX(radians(frameCount*4));
  rotateY(radians(-frameCount*4+30));
  box((int)map(sin(3.5*PI+(float)frameCount/10), -1, 1, 0, height/2)); // draw 3D Cube

  saveDataFrame(); // save the current frame to the video file.
}

void saveDataFrame() {
  loadPixels();
  file.write((char)124); // clear framebuffer
  for (int y=0; y<height; y++) {
    for (int x=0; x<width; x+=6) {

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