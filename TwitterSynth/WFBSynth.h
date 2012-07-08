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

typedef struct {
    /** Audio Sample playback state **/
    UInt32               sampleNumber;       // the next audio sample to play
    
    /** Audio Sample Description **/
    UInt32               frameCount;         // the total number of frames in the audio data
    AudioUnitSampleType  *audioData;        // the complete left (or mono) channel of audio data read from an audio file
    
    BOOL playing;
} soundStruct, *soundStructPtr;

@interface WFBSynth : NSObject <AVAudioSessionDelegate> {
    //Audio Graph Members
    AUGraph mGraph;
    
    AudioUnit mMixer;
    
    AudioUnit soundSources[10];
    
    soundStruct pingSoundStruct;
    
    Float64 graphSampleRate;
    
    //Audio Stream Descriptions
    CAStreamBasicDescription outputCASBD;
    AudioStreamBasicDescription     monoStreamFormat;
    AudioStreamBasicDescription     stereoStreamFormat;
    
    BOOL playing;
    BOOL interruptedDuringPlayback;
    
    
}

@property (readwrite) AudioStreamBasicDescription monoStreamFormat;
@property (readwrite) AudioStreamBasicDescription stereoStreamFormat;
@property (readwrite) Float64 graphSampleRate;
@property (getter = isPlaying) BOOL playing;
@property BOOL interruptedDuringPlayback;

- (void)startAUGraph;
- (void)stopAUGraph;

@end
