//
//  WFBSynth.h
//  TwitterSynth
//
//  Created by William Barksdale on 6/16/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CAStreamBasicDescription.h"
#import "WFBSoundSourceManager.h"

#define kNumAudioSources 10
#define kNumFollowerSources 3

typedef struct {
    /** Audio Sample playback state **/
    UInt32               sampleNumber;  // the next audio sample to play
    BOOL                 shouldPlay;
    
    /** Audio Sample Description **/
    UInt32               frameCount;    // the total number of frames in the audio data
    AudioSampleType      *audioData;    // complete audio data
    
} soundStruct;

@interface WFBSynth : NSObject <AVAudioSessionDelegate> {
    //Audio Graph Members
    AUGraph mGraph;             // The AU Graph
    AudioUnit tdMixerUnit;      // The 3D mixer
    
    
    //highest bus
    int bleepOutBus;                        //the bus that will play the bleep
    soundStruct bleepOutStruct;             //plays when tweet contains profanities
    
    //middle busses
    int nextAvailableFollowerUnit;          //the bus that will followee tweets
    soundStruct followerSoundStructs[kNumFollowerSources];    //the 3 structs cycled
    
    //lowest busses
    int nextAvailableUnit;                  //keeps track of the next bus to render audio
    soundStruct soundSourceStructs[kNumAudioSources];     //normal tweet sound
    
    //Audio Stream Descriptions
    Float64 graphSampleRate;
    CAStreamBasicDescription outputCASBD;
    AudioStreamBasicDescription     monoStreamFormat;
    AudioStreamBasicDescription     stereoStreamFormat;
    
    //stuff for audio session
    BOOL playing;
    BOOL interruptedDuringPlayback;
    WFBSoundSourceManager *soundSourceManager;
}

@property int nextAvailableUnit;
@property int nextAvailableFollowerUnit;
@property int bleepOutBus;

@property (readwrite) AudioStreamBasicDescription monoStreamFormat;
@property (readwrite) AudioStreamBasicDescription stereoStreamFormat;
@property (readwrite) Float64 graphSampleRate;
@property (getter = isPlaying) BOOL playing;
@property BOOL interruptedDuringPlayback;

/** Interface for outside classes to fiddle with parameters **/
- (void) playSoundWithAzimuth:(float)azimuth withDistance:(float)distance;

- (void) playSoundWithAzimuth:(float)azimuth
                 withDistance:(float)distance
              withPitchChange:(Float32)pitch;

- (void) playSound:(NSString *) sound
       withAzimuth:(float) azimuth
      withDistance:(float)distance
   withPitchChange:(Float32)pitch;

- (void) turnByDegrees:(float) dHeading;
- (void) startAUGraph;
- (void) stopAUGraph;
- (void) readAudioFileIntoMemory: (NSString *)fileURL;

- (void)stopRenderForBus:(UInt32) busNumber;

/** make the compiler happy **/
- (void) setupAudioSession;
- (void) setupMonoStreamFormat;
- (void) setupStereoStreamFormat;
- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result;

@end
