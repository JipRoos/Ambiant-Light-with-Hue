//Developed by Rajarshi Roy and James Bruce, modified by Xubin Chen + Jip Roos (Multiple Lights, different colors)
import java.awt.Robot; //java library that lets us take screenshots
import java.awt.AWTException;
import java.awt.event.InputEvent;
import java.awt.image.BufferedImage;
import java.awt.Rectangle;
import java.awt.Dimension;
import java.io.*;
//import java.util.Scanner;
//import java.awt.Color;
import processing.serial.*; //library for serial communication
 
 
Serial port; //creates object "port" of serial class
Robot robby; //creates object "robby" of robot class

// Default hue color value
final long DEFAULT_HUE = 52000; // purple   

long time = 0;

void setup()
{
  println(Serial.list());
  port = new Serial(this, Serial.list()[0],9600); //set baud rate
  size(100, 100); //window size (doesn't matter)
  try //standard Robot class error check
  {
  robby = new Robot();
  }
  catch (AWTException e)
  {
  println("Robot class not supported by your system!");
  exit();
  }

}
 
void draw()
{
  time = millis(); //<====================================================
  
  int lampCount = 3;
  int x = displayWidth; //possibly displayWidth
  int y = displayHeight; //possible displayHeight instead
  
  //get screenshot into object "screenshot" of class BufferedImage
  BufferedImage screenshot = robby.createScreenCapture(new Rectangle(new Dimension(x,y)));
  // create array for lamps
  
  String[][] colorArrays = new String [lampCount][3];
  for(int i = 0; i<lampCount; i++){
    int[] avarage = getAvarageValues(screenshot,x,y,i,lampCount);
    String[] lamp = convertToColor(avarage[0], avarage[1], avarage[2], i);
    colorArrays[i] = lamp;
  }
  
  //port.write(0xff); //write marker (0xff) for synchronization
  //port.write((byte)(r)); //write red value
  //port.write((byte)(g)); //write green value
  //port.write((byte)(b)); //write blue value
  
  
  Runtime rut = Runtime.getRuntime();


  //System.out.println(s);//This portion calls the bash file which allows Curl PUT to write the HSV values to Philips Hue
  try{
             // create a new array of 4 strings
           String[] cmdArray = new String[1 + lampCount * 3];
  
           // first argument is the program we want to open, in this case I put it within the App I created later
           cmdArray[0] = "C:\\Users\\Jip\\Documents\\HueAmbi\\start.bat";
          
           for(int i=1; i<lampCount*3+1; i=i+3){
             for(int j = 0; j<3; j++){
               if(i<3){
                 cmdArray[i+j] = colorArrays[i-1][j];
               } else {
                 //println(i);
                 cmdArray[i+j] = colorArrays[(i-1)/3][j];
               }
             }
           }
           
          //println(cmdArray[4]);
           
          Process process = rut.exec(cmdArray);
           /*Scanner scanner = new Scanner(process.getInputStream());
          while (scanner.hasNext()) {
              System.out.println(scanner.nextLine());
          }*/
    
  }catch(IOException e1){
    e1.printStackTrace();
  }
  
  
  finally{}
  
  time = 100 - (millis() - time);
  //println(time);
  if(time > 0)
    delay((int) time); //delay for safety
  //make window background average color
}

String[] convertToColor(int r, int g, int b, int i) {
  // filter values to increase saturation
  int maxColorInt;
  int minColorInt;
   
  maxColorInt = max(r,g,b);
  if(maxColorInt == r){
    // red
    if(maxColorInt < (225-20)){
      r = maxColorInt + 10;  
    }
  }
  else if (maxColorInt == g){
    //green
    if(maxColorInt < (225-20)){
      g = maxColorInt + 10;  
    }
  }
  else {
     //blue
     if(maxColorInt < (225-20)){
      b = maxColorInt + 10;  
    }  
  }
   
  //minimise smallest
  minColorInt = min(r,g,b);
  if(minColorInt == r){
    // red
    if(minColorInt > 20){
      r = minColorInt - 20;  
    }
  }
  else if (minColorInt == g){
    //green
    if(minColorInt > 20){
      g = minColorInt - 20;  
    }
  }
  else {
     //blue
     if(minColorInt > 20){
      b = minColorInt - 20;  
    }  
  }
  
  //Convert RGB values to HSV(Hue Saturation and Brightness) 
  long[] hsv = new long[3];
  RGBtoHSB(r, g, b, hsv);
  
    colorMode(HSB, 65535, 255, 255);
    if(i == 2){
      
    background(hsv[0],hsv[1],hsv[2]);
    }
  
  
  String hue = String.valueOf(hsv[0]);
  String sat = String.valueOf(hsv[1]);
  String bri = String.valueOf(hsv[2]);
  String[] colorArray = {hue, sat, bri};
  
  return colorArray;
}

int[] getAvarageValues(BufferedImage screenshot, int x, int y, int lampid, int lampCount) {
  int skipValue = 20;
  //sets of 8 bytes are: Alpha, Red, Green, Blue
  int r=0;
  int g=0;
  int b=0;
  int pixel; //ARGB variable with 32 int bytes where
  // need to be a round number
  int lampWidth = x/lampCount;
  int start = lampWidth * lampid;
  int end = lampWidth * (lampid + 1);
  int i=0;
  int j=0;
  //I skip every alternate pixel making my program 4 times faster
  for(i=start; i<end; i=i+skipValue){
    for(j=0; j<y; j=j+skipValue){
      pixel = screenshot.getRGB(i,j); //the ARGB integer has the colors of pixel (i,j)
      r = r+(int)(255&(pixel>>16)); //add up reds
      g = g+(int)(255&(pixel>>8)); //add up greens
      b = b+(int)(255&(pixel)); //add up blues
    }
  }
  
  int aX = x/skipValue;
  int aY = y/skipValue;
  r=r/(aX*aY); //average red
  g=g/(aX*aY); //average green
  b=b/(aX*aY); //average blue
  
  
  //println(r+","+g+","+b);
 int[] valueArray = {r, g, b};
 return valueArray;
}

long[] RGBtoHSB(int r, int g, int b, long[] hsbvals) {
  long hue, saturation, brightness;
  if (hsbvals == null) {
    hsbvals = new long[3];
  }
  int cmax = (r > g) ? r : g;
  if (b > cmax) cmax = b;
  int cmin = (r < g) ? r : g;
  if (b < cmin) cmin = b;
  brightness = cmax;
  if (cmax != 0)
    saturation = (cmax - cmin) * 255 / cmax;
  else
    saturation = 0;
  println(cmax);
  println(cmin);
  if (saturation == 0)
    hue = DEFAULT_HUE;
  else {
    // Need to be fixed!
    float tempHue;
    float redc = ((float) (cmax - r)) / ((float) (cmax - cmin));
    float greenc = ((float) (cmax - g)) / ((float) (cmax - cmin));
    float bluec = ((float) (cmax - b)) / ((float) (cmax - cmin));
    if (r == cmax)
      tempHue = bluec - greenc;
    else if (g == cmax)
      tempHue = 2.0f + redc - bluec;
    else
      tempHue = 4.0f + greenc - redc;
    tempHue = tempHue / 6.0f;
    if (tempHue < 0)
      tempHue = tempHue + 1.0f;
    hue = (long) (tempHue * 65535);
  }
  hsbvals[0] = hue;
  hsbvals[1] = saturation;         
  hsbvals[2] = brightness;
  //println(hsbvals);
  return hsbvals;
}
