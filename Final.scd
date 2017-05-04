/*
BEN LERUDE
CPAR 491 SENIOR PROJECT
ADVISORS: SCOTT PETERSEN AND HOLLY RUSHMEIER

"MUSIC AS MORE THAN SOUND: DEVELOPING INTERACTIVE VISUAL REPRESENTATIONS OF MUSICAL DATA"

***********************************************************************************************
*****RUN THE "SYNPIANO" SYNTHDEF BELOW BEFORE RUNNING THE PROCESSING CODE!!!*****
*THEN RUN THE "MIDI FILE CREATION" CODE BELOW AFTER RUNNING THE PROCESSING CODE*
******************BE SURE TO CHECK THE PATH FOR FILE READING/WRITING******************
***********************************************************************************************
*/


// THIS IS THE CORRECT SYNTHDEF THAT IS SYNCED WITH THE PROCESSING CODE
(
// The model for the following SynthDef was found online at:
//
//      "https://composerprogrammer.com/teaching/supercollider/sctutorial/11.1 Physical Modelling.html"
//
// We tampered with the structure to fit it to our needs, and this approach solved the major issue I faced with the
//    SynthDefs, which was that when the key or mouse was released, the sound would cut off immediately, as opposed
//    to naturally releasing and fading like an actual piano noise.

SynthDef(\synPno, { | freq = 60, gate = 1 |
	var strike, env, env2, noise, delayTime, detune, pan;
	strike = Impulse.ar(0.01);
	env = Decay2.ar(strike, 0.008, 0.14);
	env2 = EnvGen.kr(Env.adsr(releaseTime: 1), gate, doneAction: 2);

	pan = Pan2.ar(
		// array of 3 strings per note
		Mix.ar(Array.fill(3, { arg i;
			// detune strings, calculate delay time :
			detune = #[-0.05, 0, 0.04].at(i);
			delayTime = 1 / (freq + detune).midicps;
			// each string gets own exciter :
			noise = LFNoise2.ar(3000, env);   // 3000 Hz was chosen by ear..
			CombL.ar(noise,		                    // used as a string resonator
				delayTime, 		                        // used to determine pitch
				delayTime,			                    // used to determine pitch
				10) 				                            // decay time of string -- this is "duration / decay"
		})),
		(freq - 36)/27 - 1);                          // pan position: lo notes left, hi notes right
	Out.ar(0, pan * env2);
}).add;
)

// Useful for testing
x = Synth(\synPno, [\freq, 60, \amp, 0.01, \gate, 1]);
x.set(\gate, 0);

y = Synth(\synPno, [\freq, 65, \amp, 0.01, \gate, 1]);
z = Synth(\synPno, [\freq, 67, \amp, 0.01, \gate, 1]);



//                                                               MIDI FILE CREATION
// The code block reads in a text file which contains the values necessary to create MIDI events. Each value
//   (pitch, time stamp, etc.) is stored on its own line, so the code parses through each line, gathers the
//   necessary data, and adds the correctly-formatted MIDI event to the MIDI file.
(
var start, sec, pitch, onoff, vel, lineX, status;

t = File("YOURPATH/myMusic.txt", "r");

// Initialize the values of the MIDI Event
lineX = t.getLine(1024);
start = t.getLine(1024).asFloat;
start = (start / 1000);
sec = start - (start - 0.01);
pitch = t.getLine(1024).asInteger;
onoff = t.getLine(1024);
vel = t.getLine(1024).asInteger;
lineX = t.getLine(1024);

// Create our MIDI file
m = SimpleMIDIFile("YOURPATH/myMusic.mid");
m.timeMode = \seconds;

while( { lineX.notNil }, {

	// Determine whether the event is a noteOn or noteOff
	if ( onoff == "0", { status = \noteOff }, { status = \noteOn } );

	// Create event
	m.addMIDIEvent([0, sec, status, 0, pitch, vel], true);

	// Get next chunk of lines, corresponding to the next MIDI event
	sec = t.getLine(1024).asFloat;
	sec = (sec / 1000) - start;
	pitch = t.getLine(1024).asInteger;
	onoff = t.getLine(1024);
	vel = t.getLine(1024).asInteger;
	lineX = t.getLine(1024);
});

m.write;    // Write file
t.close;
)




///////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////SCRATCH WORK//////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////

// The rest of this file contain SynthDefs that I explored but ultimately did not end up using.

(
// SynthDef that I created on my own; worked except for the sustain being cut off once the key/mouse was released
SynthDef("testPiano", { |out = 0,  freq = 440, gate = 1|
	var piano;
	piano = MdaPiano.ar(freq, gate, stereo: 0.5, decay: 0.3, sustain: 0.5);
	Out.ar(out, piano);
}).add;
)

(
// Another exploration into the MdaPiano UGen, which was the source of the problems mentioned in the above def
SynthDef("testPiano2", { |out = 0,  freq = 440, amp = 0.8, egate = 1, gate = 1|
	var piano, env;
	env = EnvGen.kr(Env.asr(releaseTime:0.1), egate, doneAction: 0);
	piano = MdaPiano.ar(freq, gate, stereo: 0.5, decay: 0.3, sustain: 0.5);
	Out.ar(out, piano * env);
}).add;
)

(
// ANOTHER FAILED DEF
SynthDef(\my_piano, { |out = 0, vel = 100, freq = 100, gate = 1, amp = 0.5, sustain = 0|
    var snd;
	snd = MdaPiano.ar(freq, gate, vel, 0.08, 0.018, sustain: 0);
	// EnvGen.kr(Env.perc(releaseTime: 2), 1, doneAction:2);
	EnvGen.kr(Env.asr(0, amp, 0.1), 1, doneAction: 2);
    Out.ar(out, snd);
}).add;

// GENERAL SYNTH MODEL
SynthDef(\test, { |out = 0,  freq = 100, amp = 0.2, gate = 1|
	var env, piano;
	piano = [SinOsc.ar(freq, 0, amp), SinOsc.ar(freq + 2, 0, amp)];
	// env = Linen.kr(gate, 0.01, 0.8, 0.1, doneAction: 2);
	Out.ar(out, piano);
}).add;

// FROM HELP FILE.....
SynthDef(\help_mdapiano, { |out=0, freq = 440, gate=1|
    var piano = MdaPiano.ar(freq, gate, release: 0.9, stereo: 0.3, sustain: 0);
    DetectSilence.ar(piano, 0.01, doneAction: 2);
    Out.ar(out, piano * 0.1);
}).add;
)

(
// WEIRD PIANO EXAMPLE
x = {
    MdaPiano.ar(
        LFNoise0.kr(1).range(20, 60).round.midicps, // random note
        stereo: 0.5,
        gate: LFPulse.kr(1),
        vel: LFPar.kr(0.1).range(10, 100), // varying velocity
        mul: 0.2
    )
}.add
)