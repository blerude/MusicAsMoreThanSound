/* 

BEN LERUDE
CPAR 491 SENIOR PROJECT
ADVISORS: SCOTT PETERSEN AND HOLLY RUSHMEIER
COMPUTING AND THE ARTS DUS: JULIE DORSEY

"MUSIC AS MORE THAN SOUND: DEVELOPING INTERACTIVE VISUAL REPRESENTATIONS OF MUSICAL DATA"
-----------------------------------------------------------------------------------------

***************************************************************************************
* RUN THE "SYNPIANO" SYNTHDEF IN THE SUPERCOLLIDER FILE BEFORE EXECUTING THIS CODE!!! *
****** ALSO, CHECK THAT THE NANOKEY2 MIDI KEYBOARD IS PLUGGED INTO THE HDMI JACK ******
***************************************************************************************

***************************************************************************************
*** AFTER EXECUTING THIS BLOCK, RUN THE "MIDI FILE CREATION" BLOCK IN SUPERCOLLIDER ***
*** MAKE SURE TO CHECK THE FILE PATH WHEN SAVING THE TEXT FILE IN THE FINISH METHOD ***
***************************************************************************************


Functions:
-void setup              -Called once, lays foundation for interface
-void draw               -Called repeatedly, redrawing keyboard and 2D visualization each 
                           time
-void keyPressed         -Activates synth and visual response for corresponding key
-void keyReleased        -Deactivates synth for corresponding key
-void mousePressed       -Identifies location and activates synth and visual response
                           for selected key
-void mouseReleased      -Identifies location and deactivates synth for selected key
-void model              -Called once 'DONE' is pushed; renders 3D representation of the 
                           piece
-int findColor           -Identifies which color corresponds to the current note played
-IntList chordConverter  -Identifies the scale degree of each note of the current chord
-void noteOn             -Identifies the note being played on the MIDI keyboard
-void noteOff            -Identifies the note just released from the MIDI keyboard and 
                           deactivates the corresponding synth
-void registerKey        -Activates the synth and triggers the visual response for the
                           note, as called for by noteOn
-void finish             -Once the piece has been played and 'DONE' has been pressed, 
                           this function saves the MIDI data into a file that SuperCollider
                           uses to create the MIDI file
-boolean includes        -Function for determining if a given key is contained in a 
                           given collection (not used in current code, but was used in
                           previous versions)
                   


COMPUTER KEYBOARD CONFIGURATION*:
 2 3     8 9 0
q w e   u i o p 

 s d     g h j
z x c   v b n m

*There is more functionality in using the MIDI keyboard
**One more octave is created using CAPS lock/the Shift key for the bottom level octave 
(starting with Z)

*/


// The following libraries are necessary for interacting with SuperCollider, for 
//    creating the toggle, for 3D modelling, and for interacting with the MIDI 
//    keyboard
import supercollider.*;
import oscP5.*;
import controlP5.*;
import org.quark.jasmine.*;
import peasy.*;
import themidibus.*;


Synth[] synths = new Synth[37];  // Array for logging Synth creations for each key
Bus[] delaybuss = new Bus[37];   // Array for logging Bus creations for each key


// These definitions initialize key variables used throughout the program
int width = 964;            // Width of the entire interface
int height = 700;           // Height of the entire interface
int border = 40;            // Total width of the fringe around the interface       
int hBorder = border / 2;   // Half that width, which is one side of the fringe
int top = 525;              // The coordinate of the top of the keyboard
int bottom;                 // The coordinate of the bottom of the visual window
int sep = 10;               // Height of the separator btwn the visual window and piano
int wWidth = 44;            // Width of white keys
int bWidth = 26;            // Width of black keys

int bLoc = 0;               // Location of the current black key being drawn
int wLoc = 0;               // Location of the current white key being drawn

// The array of keys that represent the piano on the keyboard
char[] keys = { 
  'z', 'x', 'c', 'v', 'b', 'n', 'm',   // White keys, Octave 1              
  'q', 'w', 'e', 'u', 'i', 'o', 'p',   // White keys, Octave 2
  'Z', 'X', 'C', 'V', 'B', 'N', 'M',   // White keys, Octave 3
  
  's', 'd', 'g', 'h', 'j',             // Black keys, Octave 1
  '2', '3', '8', '9', '0',             // Black keys, Octave 2
  'S', 'D', 'G', 'H', 'J'              // Black keys, Octave 3
};         
                
int wHeight = height - top - hBorder;     // Height of the white keys
float bHeight = wHeight * 0.6;            // Height of the black keys
int offset = 20;                          // Ensures black keys are spaced correctly
int bTally = 0;                           // How many black keys have been drawn
int wTally = 0;                           // How many white keys have been drawn
int skips = 0;                            // How many black keys have been skipped over
int pitch;                                // The pitch corresponding to the pressed key
int mousePitch;                           // The pitch corresponding to the selected key
int skipCount = 0;                        // Black keys skipped while determining pitch

ControlP5 mySwitch;                       // The keyboard on-off toggle                     
boolean pianoOn = true;                   // True when keyboard is toggled on
boolean blackKey = false;                 // True when black key is activated
 
 
// MIDI notes that correspond to the accepted keys
int[] midiSequence = { 
  48, 50, 52, 53, 55, 57, 59,   // MIDI NOTES
  60, 62, 64, 65, 67, 69, 71,   //    FOR
  72, 74, 76, 77, 79, 81, 83,   // WHITE KEYS
  
  49, 51, 54, 56, 58,           // MIDI NOTES
  61, 63, 66, 68, 70,           //    FOR
  73, 75, 78, 80, 82            // BLACK KEYS
};

// Pitch names for labelling visual nodes
String[] pitchNames = {
  "C4", "D4", "E4", "F4", "G4", "A4", "B4",
  "C5", "D5", "E5", "F5", "G5", "A5", "B5",
  "C6", "D6", "E6", "F6", "G6", "A6", "B6",
  
  "C#4", "D#4", "F#4", "G#4", "A#4",
  "C#5", "D#5", "F#5", "G#5", "A#5",
  "C#6", "D#6", "F#6", "G#6", "A#6",
};

// This array is filled with 0's or 1's indicating which keys are activated 
int[] keyPress = { 
  0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 
  0, 0, 0, 0, 0, 0, 
  0, 0, 0, 0, 0, 0, 
  0, 0, 0, 0, 0, 0, 
  0, 0, 0, 0, 0, 0
};

// Initial radii for the visual nodes
int[] circ = {
  10, 10, 10, 10, 10, 10,
  10, 10, 10, 10, 10, 10,
  10, 10, 10, 10, 10, 10,
  10, 10, 10, 10, 10, 10,
  10, 10, 10, 10, 10, 10,
  10, 10, 10, 10, 10, 10
};

// Initial radian measures for the visual nodes
float[] rad = {
  216, 216, 216, 216, 216, 216,
  216, 216, 216, 216, 216, 216,
  216, 216, 216, 216, 216, 216,
  216, 216, 216, 216, 216, 216,
  216, 216, 216, 216, 216, 216,
  216, 216, 216, 216, 216, 216
};

// The nodes are all initialized to black until their key is pressed
color[] colors = {
  color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0),
  color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0),
  color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0),
  color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0),
  color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0),
  color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0), color(0,0,0)
};

// Records which dot in the circle is currently being worked on
float[] dot = {
  1, 2, 3, 4, 5, 6,
  7, 8, 9, 10, 11, 12,
  13, 14, 15, 16, 17, 18,
  19, 20, 21, 22, 23, 24,
  25, 26, 27, 28, 29, 30,
  31, 32, 33, 34, 35, 36
};

// Array of possible pitches for the chord chart
String[] masterPitch = {
  "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
};

// Array of chords assigned to each pitch on the chord chart
color[] masterColor = {
  color(232,9,9), color(232,95,9), color(244,245,12), color(61,227,16), 
  color(16,227,158), color(2,227,237), color(2,121,237), color(72,63,178), 
  color(148,144,206), color(243,167,255), color(231,37,232), color(225,88,132)  
};


float[] xcoord = new float[36];      // Array of x coordinates for each node
float[] ycoord = new float[36];      // Array of y coordinates for each node
float theta = 0;                     // Initial theta for mapping the nodes
float circx = 482;                   // Initial x coordinate for mapping the nodes
float circy = 266;                   // Initial y coordinate for mapping the nodes
boolean track = false;               // Indicates if the track feature has been activated
boolean done = false;                // Pressed when it is time to see the 3D model 
int labelW;                          // Width of the current chord chart pitch label
int chartX = 0;                      // X coordinate of the current chord chart pitch
int chartY = 570;                    // Y coordinate of the current chord chart pitch
int chartW = 47;                     // Width of the current chord chart pitch
// These arrays show the initial y coordinates of the chord chart pitches
int[] chartChords = { 620, 620, 620, 620, 620, 620, 620, 620, 620, 620, 620, 620 };
int[] chartChords2 = { 620, 620, 620, 620, 620, 620, 620, 620, 620, 620, 620, 620 };
int chartI = 0;                      // Indicates current pitch on the chord chart 

int[] timeStampOn = { };                 // Array for storing Key On commands
int[] timeStamp = { };                   // Array for storing MIDI Event timestamps
int[] midiNotes = { };                   // Array for storing MIDI Event pitches
int[] onOff = { };                       // Array that stores Note On/Off indicators 
int[] vel = { };                         // Array for storing MIDI Event velocities
IntList chordElements = new IntList();   // List for flexibly storing chord elements
IntList newChord = new IntList();        // List for copying new chords
String[] chords = { };                   // Stores chords as strings of pitches
float[] chordTally = { };                // Tallies chord weights
color[] chordColor = { };                // Stores colors of respective chords for the chart
String sortChord = new String();         // Sorts the chord elements for entity resolution purposes
float chordTotal = 0;                    // Stores total number of chords played
int[] degrees = { };                     // Splits the chord strings into individual scale degrees 
IntList removeDups = new IntList();      // Removes duplicates from the chord representations
float prevX;                             // Indicates x coordinate of the previous note played
float prevY;                             // Indicates y coordinate of the previous note played
int prevKey;                             // Indicates the pitch of the previous note played
boolean chord;                           // Indicates if we are currently in the midst of a chord
IntList path = new IntList();            // Stores the path of most recently played notes

MidiBus myBus;                           // The bus used to gather MIDI information from the NanoKey2


// This function sets up the foundation of the interface and is called one time
void setup()
{
  size(964, 700, P3D);      // The dimensions of the interface
  frameRate(60);            // How often the interface is drawn over
  background(55,56,170);    // The background color
  
  // Create a toggle and change the default look to a (on/off) switch look
  mySwitch = new ControlP5(this);
  
  // Switch used to determine whether the piano or the chord chart is shown 
  mySwitch.addToggle("pianoOn")
     .setPosition(964 - 55, 1)
     .setSize(50, 18)
     .setValue(true)
     .setMode(ControlP5.SWITCH)
     .setCaptionLabel("Show Piano?")
     .setColorBackground(color(255, 0, 0))
     .setColorForeground(color(232, 7, 15))
     .setColorActive(color(27, 198, 6));
  ;
  
  // OFF button, kills everything
  fill(250, 0, 0);
  rect(0, 0, 20, 20);
  textSize(10);
  fill(255);
  text("OFF", 1, 13);
  
  // TRACK button, toggles pitch tracking display
  fill(15, 165, 48);
  rect(25, 0, 36, 20);
  textSize(10);
  fill(255);
  text("TRACK", 27, 13);
  
  // DONE button, allows for 3D modelling and MIDI file creation
  fill(15, 165, 48);
  rect(66, 0, 31, 20);
  textSize(10);
  fill(255);
  text("DONE", 68, 13);

  // Set initial synth to silent to offset opening synth bug
  delaybuss[36] = new Bus("audio", 2);

  synths[36] = new Synth("synPno");
  synths[36].set("gate", 0);
  synths[36].set("amp", 0.0);
  synths[36].set("freq", midiSequence[10]);
  synths[36].set("outbus", delaybuss[36].index);
  synths[36].create();
  
  // Initialize the MIDI Bus and link it to the NanoKey2
  myBus = new MidiBus(this, "KEYBOARD", "CTRL");
  myBus.sendTimestamps(true);
}


// This function is called however many times the framerate variable indicates per 
//    second. This is the bulk of the code
void draw()
{    
  // Sets up 3D modelling
  lights();
  if (done)
    model();
    
  
  fill(200);  
  if (pianoOn && !done)   // Draws a smaller visual window if the piano should be there
  {
    bottom = height - hBorder - (height - top - hBorder) - sep;
    rect(hBorder, hBorder, width - border, bottom, 5);
  }
  else if (!done)
  {
    bottom = height - border;
    rect(hBorder, hBorder, width - border, bottom, 5);
  }
  
  // Draws the 2D circular representation of the musical data
  if (!done) 
  {
    for (int i = 0; i < 36; i++)
    {
      theta = 2 * PI * (dot[i] / 36);
      xcoord[i] = circx + (rad[i] * cos(theta));
      ycoord[i] = circy + (rad[i] * sin(theta));
      fill(colors[i]);
      ellipse(xcoord[i], ycoord[i], circ[i], circ[i]);
    }
    
    // Draws the pathway linking the most recent three keys played
    for (int i = 0; i < path.size() - 1; i++)
    {
      stroke(255);
      if (i == 0)
        strokeWeight(1);
      else if (i == 1)
        strokeWeight(3);
      else
        strokeWeight(5);
      line(xcoord[path.get(i)], ycoord[path.get(i)], xcoord[path.get(i + 1)], ycoord[path.get(i + 1)]);
    }
    
    strokeWeight(1);
  }
  
  // Draws the tracking labels so that users can identify which node corresponds 
  //   to which key
  labelW = 15;
  if (track)
  {
    stroke(0);
    for (int i = 0; i < 36; i++)
    {
      if (circ[i] > 10)
      {
        if (i > 20)
          labelW = 22;
        fill(255);
        rect(xcoord[i], ycoord[i] - (circ[i] / 2) - 6, labelW, 12);
        textSize(10);
        fill(0); 
        text(pitchNames[i], xcoord[i] + 1, ycoord[i] - (circ[i] / 2) + 3);
      }
    }
  }
  
  if (pianoOn && !done)   // DRAW THE PIANO!!!
  {
    noStroke();
    fill(55,56,170);
    rect(hBorder, top - sep, width - hBorder, sep, 5);
    stroke(0);
    for (int i = 0; i < 21; i++)   // Draw the white keys
    {
      // If the current key is activated, turn the fill color to gold
      if ((keyPress[i + bTally] == 1) || 
        (mousePressed && !out && i == wLoc && keyPress[i + bTally] == 1))
          fill(211, 195, 13); 
      else
        fill (255);
      
      rect(hBorder + i * wWidth, top, wWidth, height - top - hBorder, 4, 4, 7, 7);
      wTally += 1;
    }
    for (int j = 0; j < 20; j++)   // Draw the black keys
    {      
      // If the current key is activated, turn the fill color to gold
      if ((keyPress[j + wTally - skips] == 1) || 
          (mousePressed && !out && j == bLoc && keyPress[j + wTally - skips] == 1))
        fill(211, 195, 13);
      else 
        fill(0);

      // Every 3rd and 7th black key is not drawn (that's how the piano works)
      if (j % 7 != 2 && j % 7 != 6)
      {
        rect(hBorder + j * bWidth + 30 + offset, top, bWidth, bHeight, 0, 0, 7, 7);
        offset = offset + 20;
        bTally += 1;
      }
      else 
      {
        offset = offset + 13;
        skips += 1;
      }
    }
    offset = 0;
    bTally = 0;
    wTally = 0;
    skips = 0;
  }
  else if (!done)   // If the piano should not be drawn, the chart is drawn instead
  {
    noStroke();
    fill(55,56,170);
    rect(hBorder, top - sep, width - hBorder, sep);
    chartX = hBorder + 15 + (chartW / 2);
        
    for (int i = 0; i < 12; i++)
    {
      fill(0);
      text(masterPitch[i], chartX - 5, chartY - 35);
      stroke(0);
      fill(masterColor[i]);
      if (newChord.hasValue(i))
        ellipse(chartX, chartY, chartW + 20, chartW + 20);
      else
        ellipse(chartX, chartY, chartW, chartW);
      chartX += 30 + chartW;
    }
    
    chartX = hBorder + 15 + (chartW / 2);
    for (int j = 0; j < chartChords2.length; j++)
      chartChords2[j] = chartChords[j];
    
    chordTotal = 0;
    for (int j = 0; j < chordTally.length; j++)
      chordTotal += chordTally[j];
        
    // Determines which chords are the most relevant and emphasizes them
    for (int j = 0; j < chords.length; j++)
    {
      if ((chordTally[j] / chordTotal) > 0.2)
      {
        degrees = int(split(chords[j], ' '));
        for (int k = 0; k < degrees.length; k++)
          if (removeDups.hasValue(degrees[k]));
          else 
            removeDups.append(degrees[k]);
            
        for (int k = 0; k < removeDups.size(); k++)
        {
          chartI = chartX + ((chartW + 30) * removeDups.get(k));
          stroke(0);
          fill(chordColor[j]);
          ellipse(chartI, chartChords2[removeDups.get(k)], 10, 10);
          chartChords2[removeDups.get(k)] += 15;
        }
        
        removeDups.clear();
      }
    }
  }
}


// This function is called every time a key is pressed on the keyboard
void keyPressed()
{
  // Stores the time stamp of the note for reference in compiling chords
  timeStampOn = append(timeStampOn, millis());
  
  // Search for black keys
  if (key == 's' || key == 'd' || key == 'g' || key == 'h' || key == 'j' ||
      key == '2' || key == '3' || key == '8' || key == '9' || key == '0' ||
      key == 'S' || key == 'D' || key == 'G' || key == 'H' || key == 'J')
    blackKey = true;
  else
    blackKey = false;
  
  for (int i = 0; i < keys.length; i++)
  {
     if (key == keys[i])
     {  
        registerKey(i, midiSequence[i], 0);
        keyPress[i] = 1;
     }
  }
}


// Called whenever a key is released
void keyReleased() 
{
  for (int i = 0; i < keys.length; i++)
  {
    // Search for activated synths and set them on silent
     if (key == keys[i])
      {
        delaybuss[i].free();
        synths[i].set("gate", 0);
        keyPress[i] = 0;            // Change indicator variable to show synth is off
      }
  }
}


// Similar to keyPressed, but for mouses being pressed
int ind;                // Indicates which key we are looking at
boolean out = true;     // Indicates whether the click was on or off the keyboard
void mousePressed()
{  
  // The "OFF" switch ==> close everything!
  if (mouseX < 20 && mouseY < 20)
  {
    delaybuss[36].free();
    synths[36].set("gate", 0);    
    exit();
  }
  // The "TRACK" switch ==> show pitch names!
  else if (mouseX > 24 && mouseX < 57 && mouseY < 20)
  {
    delaybuss[36].free();
    synths[36].set("gate", 0);
    if (!track)
      track = true;
    else
      track = false;
  }
  // The "DONE" switch ==> show 3D modelling and prep MIDI file
  else if (mouseX > 65 && mouseX < 98 && mouseY < 20)
  {
    delaybuss[36].free();
    synths[36].set("gate", 0);
    if (!done) 
      done = true;
    
    finish();
  }
   
  if (pianoOn && !done)
  {
    // Determines whether mouse is pressing a white key, black key, or is out of bounds
    if ((mouseX < hBorder) || (mouseX > width - hBorder) || 
        (mouseY < height - wHeight - hBorder) || (mouseY > height - hBorder)) 
      out = true;
    else if (get(mouseX, mouseY) == color(255))
    {
      blackKey = false;
      wLoc = (mouseX - hBorder) / wWidth;
      ind = wLoc;     // Determines the location of the activated key
      out = false;
    }
    else if (get(mouseX, mouseY) == color(0) && (mouseY < top + sep + bHeight))
    {
      blackKey = true;
      bLoc = (mouseX - hBorder) / wWidth;
      if ((mouseX - hBorder) % wWidth < 36)
        bLoc = bLoc - 1;
        
      if (bLoc % 7 > 2) skipCount = 1 + (bLoc / 7) * 2;
      else skipCount = (bLoc / 7) * 2;
  
      ind = 21 + bLoc - skipCount;
      out = false;
    }
    
    // If the mouse is not out of bounds of the piano, the necessary pitch 
    //   is determined, and the corresponding synth is set to the right pitch 
    //   and played
    if (!out)
    {
      path.append(ind);
      if (path.size() > 4)
        path.remove(0);
      
      mousePitch = midiSequence[ind];
      circ[ind] += 2;
      if (colors[ind] == color(0, 0, 0))
        colors[ind] = masterColor[findColor(ind)];
    
      if (keyPress[ind] == 0)
      {
        delaybuss[ind] = new Bus("audio", 2);
      
        synths[ind] = new Synth("synPno");
        synths[ind].set("gate", 1);
        synths[ind].set("amp", 0.3);
        synths[ind].set("freq", mousePitch);
        synths[ind].set("outbus", delaybuss[ind].index);
        synths[ind].create();
        
        keyPress[ind] = 1;   // Indicate that the synth is active!
      }
    }
  }
}

// This function is similar to keyReleased, but used for mouse clicks
void mouseReleased()
{
  // This function is only relevant if the mouse is placed on a key
  if (!out && pianoOn)
  {
    bLoc = -1;
    wLoc = -1;
    
    // Determine if the current key is white or black and mark that index
    if (get(mouseX, mouseY) == color(255))
    {
      wLoc = (mouseX - hBorder) / wWidth;
      ind = wLoc;
    }
    else if (get(mouseX, mouseY) == color(0))
    {
      bLoc = (mouseX - hBorder) / wWidth;
      if ((mouseX - hBorder) % wWidth < 36)
        bLoc = bLoc - 1;
        
      if (bLoc % 7 == 0 || bLoc % 7 > 3) skipCount = 1 + (bLoc / 7) * 2;
      else skipCount = (bLoc / 7) * 2;
  
      ind = 21 + bLoc - skipCount;
    }
  
    // Wipe the synth and set it back to silent until it is played again
    if (keyPress[ind] != 0)
    {
      delaybuss[ind].free();
      synths[ind].set("gate", 0);
      keyPress[ind] = 0;
    }
  }
  
  out = true;
}


// This method enables the 3D visualization feature by setting up the camera
//   in order to get a perspective and rotate around the image to see it from
//   all angles. 
PeasyCam cam;
void model()
{
  // Background change indicates the new view
  background(211, 211, 211);
  
  // Camera set up with basic parameters 
  cam = new PeasyCam(this, 420);
  cam.setMinimumDistance(0.00001);
  cam.setMaximumDistance(9999999);
  cam.setRotations(2.5, 0, PI);
  cam.lookAt(0, 0, 0);
  
  // Set up view perspectives and ability to move around with the mouse
  rotateX(map(mouseY, 0, height/2, 0, 2*PI));
  rotateY(map(mouseX, 0, width/2, 0, 2*PI));
  rotateZ(map(mouseX, 0, width, 0, PI));
  
  // Draw the first pitch node, but as a sphere not a circle
  noStroke();
  theta = 2 * PI * (dot[0] / 36);
  translate((rad[0] * cos(theta)), (rad[0] * sin(theta)), 0);
  pushMatrix();
  fill(colors[0]);
  sphere(circ[0]);
  stroke(0);
  fill(255); 
  translate(-5, 0, circ[0]);
  text(pitchNames[0], 0, 0);
  translate(0, 0, -2 * circ[0]);
  text(pitchNames[0], 0, 0);
  popMatrix();
  
  // Continue remaining spheres
  int alt = -1;                 // Indicates layer of 3D representation
  for (int i = 1; i < 36; i++)
  {
    noStroke();
    translate(xcoord[i] - xcoord[i - 1], ycoord[i] - ycoord[i - 1], alt * 40);
    pushMatrix();
    fill(colors[i]);
    sphere(circ[i]);
    stroke(0);
    fill(255);
    translate(-5, 0, circ[i]);
    text(pitchNames[i], 0, 0);
    translate(0, 0, -2 * circ[i]);
    text(pitchNames[i], 0, 0);
    popMatrix();
    
    if (alt == 1)
      alt = -1;
    else
      alt = 1;
  }
}


// This method is given an index, which it uses to identify which pitch is 
//   being handled. It returns the translation of the index into the 
//   appropriate scale degree
int findColor(int i)
{
  int index;
  
  if (i == 0 || i == 7 || i == 14)          // C
    index = 0;
  else if (i == 21 || i == 26 || i == 31)   // C#
    index = 1;
  else if (i == 1 || i == 8 || i == 15)     // D
    index = 2;
  else if (i == 22 || i == 27 || i == 32)   // D#
    index = 3;
  else if (i == 2 || i == 9 || i == 16)     // E
    index = 4;
  else if (i == 3 || i == 10 || i == 17)    // F
    index = 5;
  else if (i == 23 || i == 28 || i == 33)   // F#
    index = 6;
  else if (i == 4 || i == 11 || i == 18)    // G
    index = 7;
  else if (i == 24 || i == 29 || i == 34)   // G#
    index = 8;
  else if (i == 5 || i == 12 || i == 19)    // A
    index = 9;
  else if (i == 25 || i == 30 || i == 35)   // A#
    index = 10;
  else                                      // B
    index = 11;
  
  return index;
};


// Given a list of chord elements, this returns a list where the input keys,
//   previously on the 1-36 scale, are translated into scale degrees
IntList convertedChord = new IntList();
IntList chordConverter(IntList keys)
{
   convertedChord.clear();
   int i;
   for (int j = 0; j < keys.size(); j++)
   {
     i = keys.get(j);
     if (i == 0 || i == 7 || i == 14)          // C
       convertedChord.append(0);
     else if (i == 21 || i == 26 || i == 31)   // C#
       convertedChord.append(1);
     else if (i == 1 || i == 8 || i == 15)     // D
       convertedChord.append(2);
     else if (i == 22 || i == 27 || i == 32)   // D#
       convertedChord.append(3);
     else if (i == 2 || i == 9 || i == 16)     // E
       convertedChord.append(4);
     else if (i == 3 || i == 10 || i == 17)    // F
       convertedChord.append(5);
     else if (i == 23 || i == 28 || i == 33)   // F#
       convertedChord.append(6);
     else if (i == 4 || i == 11 || i == 18)    // G
       convertedChord.append(7);
     else if (i == 24 || i == 29 || i == 34)   // G#
       convertedChord.append(8);
     else if (i == 5 || i == 12 || i == 19)    // A
       convertedChord.append(9);
     else if (i == 25 || i == 30 || i == 35)   // A#
       convertedChord.append(10);
     else                                      // B
       convertedChord.append(11);
   }
   
   keys.clear();
   return convertedChord;
}


// Identifies the pitch information of the MIDI note and stores
//   that information for the MIDI file before calling the registerKey 
//   function, which processes the rest
void noteOn(int channel, int pitch, int velocity) {
  
  timeStampOn = append(timeStampOn, millis());
  timeStamp = append(timeStamp, millis());
  midiNotes = append(midiNotes, pitch);
  onOff = append(onOff, 1);
  vel = append(vel, velocity);
    
  for (int i = 0; i < midiSequence.length; i++)
  {
    if (midiSequence[i] == pitch)
      ind = i;
  }
      
  registerKey(ind, pitch, velocity);
}


// Identifies the pitch information of the MIDI note and stores
//   that information for the MIDI file before deactivating the
//   corresponding synth
void noteOff(int channel, int pitch, int velocity) {
  
  timeStamp = append(timeStamp, millis());
  midiNotes = append(midiNotes, pitch);
  onOff = append(onOff, 0);
  vel = append(vel, velocity);

  for (int i = 0; i < midiSequence.length; i++)
  {
    if (midiSequence[i] == pitch)
      ind = i;
  }
  
  delaybuss[ind].free();
  synths[ind].set("gate", 0);
}


// This function takes the most recent note and checks if it is part of a chord;
//   if so, the chord is recorded for the chord chart to represent by looking at 
//   its members, the velocity data, and the frequency with which it is played
void registerKey(int ind, int pitch, int velocity) {
  
  // Add the note to the path
  path.append(ind);
  if (path.size() > 4)
    path.remove(0);
  
  // Identify the color of the note if it has not been played before
  circ[ind] += 1;
  if (colors[ind] == color(0, 0, 0))
    colors[ind] = masterColor[findColor(ind)];

  // This loop identifies whether the current note is in a chord with the previous one,
  //   and if so, logs the chord information for the chart and adjusts the coordinates 
  //   of the node so that they it heads closer to it's chordal brother. If not, the 
  //   note is treated normally and sent directly towards the center of the circle of nodes
  if (timeStampOn.length == 1);
  else if ((timeStampOn[timeStampOn.length - 1] - timeStampOn[timeStampOn.length - 2]) < 50)
  {
    // Bring two chordal nodes closer together
    chord = true;
    if (prevX < xcoord[ind])
      xcoord[ind] -= 2;
    else
      xcoord[ind] += 2;
    
    if (prevY < ycoord[ind])
      ycoord[ind] -= 2;
    else
      xcoord[ind] += 2;
              
    // Adjust location in the circle
    rad[ind] = dist(circx, circy, xcoord[ind], ycoord[ind]);
    if (ind < 18)
      dot[ind] = (36 / (2 * PI)) * acos((xcoord[ind] - circx) / rad[ind]);
    else // if (i < 27)
      dot[ind] = (36 / (2 * PI)) * -1 * acos((xcoord[ind] - circx) / rad[ind]);
      
    chordElements.append(prevKey);
  }
  else          // non-chord
  {
    rad[ind] -= 3;
    // If this note terminates a chord, the chord is identified and the information
    //   is stored for the chord chart to use
    if (chord)
    {
      chord = false;
      chordElements.append(prevKey);
      newChord = chordConverter(chordElements);
      
      // Create string of chord elements
      newChord.sort();
      sortChord = "";
      for (int j = 0; j < newChord.size(); j++)
      {
        if (j == newChord.size() - 1)
          sortChord = sortChord + newChord.get(j);
        else
          sortChord = sortChord + newChord.get(j) + " ";
      }
      
      int len = chords.length;
      for (int k = 0; k <= len; k++)
      {
        if (len == 0)          // Chord has never been seen before
        {
          chords = append(chords, sortChord);
          chordTally = append(chordTally, 1);
          chordColor = append(chordColor, color(random(255), random(255), random(255)));
        }
        else if (k < len && sortChord.equals(chords[k]))
        {
          // The velocity data tells us how strongly the chord was emphasized, so that
          //   the chart can more accurately depict chord strength
          if (velocity < 50)
            chordTally[k] += 1;
          else if (velocity < 100)
            chordTally[k] += 2;
          else
            chordTally[k] += 3;
            
          k = len + 1;
        }
        else if (k == len)      // Chord has never been seen before
        {
          chords = append(chords, sortChord);
          chordTally = append(chordTally, 1);
          chordColor = append(chordColor, color(random(255), random(255), random(255)));
        }
      }
    }
    else        // Clear the chord logs
    {
      chordElements.clear();
      newChord.clear();
    }
  }

  // Update the previous note and node to be the current one
  prevX = xcoord[ind];
  prevY = ycoord[ind];
  prevKey = ind;

  // Activate a synth for the note
  delaybuss[ind] = new Bus("audio", 2);

  synths[ind] = new Synth("synPno");
  synths[ind].set("gate", 1);
  synths[ind].set("amp", 0.3);
  synths[ind].set("freq", pitch);
  synths[ind].set("outbus", delaybuss[ind].index);
  synths[ind].create();
}


// Creates a text file that contains groupings for each MIDI event. 
//   These are taken by SuperCollider in order to create a simple 
//   MIDI file that can be read by notation software to create 
//   rough sheet music for whatever was played.  
PrintWriter output;        // Class for creating files
void finish()
{
  output = createWriter("YOURPATH/myMusic.txt");

  for (int i = 0; i < onOff.length; i++)
  {
    output.println("x");
    output.println(timeStamp[i]);
    output.println(midiNotes[i]);
    output.println(onOff[i]);
    output.println(vel[i]);
  }

  output.flush();
  output.close();
}


// Used to check if a key is included in a collection (not used by
//   version of the code)
boolean includes(char key, char[] keys)
{
  for (int i = 0; i < keys.length; i++)
    if (keys[i] == key) return true;

  return false;
}