import ddf.minim.*;
import ddf.minim.ugens.*;
import java.io.File;
import java.util.Arrays;
import java.util.Comparator;

Minim minim;
AudioOutput out;
ArrayList<PImage> imgs = new ArrayList<PImage>();

float[] frequencies = { 261.63, 277.18, 329.63, 349.23, 392.00, 415.30, 466.16 };
Oscil[] oscillators = new Oscil[frequencies.length];

int lastTime = 0;
int interval = 600; 
int currentIndex = 0;
float[] targetAmps = new float[frequencies.length];
float[] currentAmps = new float[frequencies.length];

void setup() {
  fullScreen();
  colorMode(HSB, 360, 100, 100);
  
  minim = new Minim(this);
  out = minim.getLineOut();
  File dataFolder = new File(sketchPath("data"));
  File[] files = dataFolder.listFiles();
  
  Arrays.sort(files, Comparator.comparingInt(f -> Integer.parseInt(f.getName().replaceAll("\\D", ""))));
 
  for (int i = 0; i < files.length; i++) {
      imgs.add(loadImage(files[i].getName()));
  }
  for (int i = files.length - 2; i >= 1; i--) {
      imgs.add(loadImage(files[i].getName()));
  }

  for (int i = 0; i < frequencies.length; i++) {
    oscillators[i] = new Oscil(frequencies[i], 0, Waves.TRIANGLE);
    currentAmps[i] = 0;
    targetAmps[i] = 0; 
    oscillators[i].patch(out);
  }
  
  if (imgs.size() > 0) {
    analyzeImage(imgs.get(currentIndex));
    lastTime = millis();
  }
}

void draw() {
  if (imgs.size() == 0) return;
  
  background(0);
  
  PImage currentImg = imgs.get(currentIndex);
  
  float scale = min((float)width / currentImg.width, (float)height / currentImg.height);
  float newW = currentImg.width * scale;
  float newH = currentImg.height * scale;
  float x = (width - newW) / 2;
  float y = (height - newH) / 2;
  
  image(currentImg, x, y, newW, newH);

  for (int i = 0; i < oscillators.length; i++) {
    currentAmps[i] = lerp(currentAmps[i], targetAmps[i], 0.15);
    oscillators[i].setAmplitude(currentAmps[i]);
  }

  if (millis() - lastTime > interval) {
    currentIndex = (currentIndex + 1) % imgs.size();
    analyzeImage(imgs.get(currentIndex));
    lastTime = millis();
  }
}

void analyzeImage(PImage img) {
  img.loadPixels();
  
  int total = img.pixels.length;
  int[] counts = new int[7]; ////Shades of black/white, Green, Blue, Light Green, Dark Blue, Dark Green, Light Blue

  for (int i = 0; i < total; i++) {
    color c = img.pixels[i];
    float h = hue(c);        
    float s = saturation(c);
    float b = brightness(c);
    float[] hueThreshold = {70, 160, 260};
    float[] brightThreshold = {5, 40, 75};
  
    if (b > brightThreshold[0]) {
      if (s < 10) { 
          counts[0]++; //Shades of black/white
      } 
      else if (h >= hueThreshold[0] && h < hueThreshold[1]) {
          if (b < brightThreshold[1]) counts[3]++; //Light Green
          else if (b < brightThreshold[2]) counts[1]++; //Green
          else counts[5]++; //Dark Green
      }
      else if (h >= hueThreshold[1] && h < hueThreshold[2]) {
          if (b < brightThreshold[1]) counts[6]++; //Dark Blue
          else if (b < brightThreshold[2]) counts[2]++; //Blue
          else counts[4]++; //Light Blue
      }
    } //Pure black is ignored
  }
  
  for (int i = 0; i < frequencies.length; i++) {
    float perc = (float)counts[i] / total;
    targetAmps[i] = constrain(map(perc, 0, 0.3, 0, 1.0 / oscillators.length), 0, 1.0 / oscillators.length); 
  }
}

void stop() {
  out.close();
  minim.stop();
  super.stop();
}
