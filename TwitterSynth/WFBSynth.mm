//
//  WFBSynth.m
//  TwitterSynth
//
//  Created by William Barksdale on 6/16/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBSynth.h"

#define kNumAudioSources 10

id myself; //reference to self for use in C functions

/*************************************************************
 * Audio session callback function for responding to audio route changes. If playing back audio and
 *   the user unplugs a headset or headphones, or removes the device from a dock connector for hardware  
 *   that supports audio playback, this callback detects that and stops playback. 
 *
 * Refer to AudioSessionPropertyListener in Audio Session Services Reference.
 */
void audioRouteChangeListenerCallback ( void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue ) {
    
    // Ensure that this callback was invoked because of an audio route change
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
    
    // This callback, being outside the implementation block, needs a reference to the MixerHostAudio
    //   object, which it receives in the inUserData parameter. You provide this reference when
    //   registering this callback (see the call to AudioSessionAddPropertyListener).
    // WFBSynth *synth = (__bridge WFBSynth *) inUserData;
    
    // if application sound is not playing, there's nothing to do, so return.
    if (NO == [myself isPlaying]) {
        NSLog (@"Audio route change while application audio is stopped.");
        return;
    } else {
        // Determine the specific type of audio route change that occurred.
        CFDictionaryRef routeChangeDictionary = (CFDictionaryRef) inPropertyValue;
        
        CFNumberRef routeChangeReasonRef =
        (CFNumberRef) CFDictionaryGetValue (
                              routeChangeDictionary,
                              CFSTR (kAudioSession_AudioRouteChangeKey_Reason)
                              );
        
        SInt32 routeChangeReason;
        CFNumberGetValue (
                          routeChangeReasonRef,
                          kCFNumberSInt32Type,
                          &routeChangeReason
                          );
        
        // "Old device unavailable" indicates that a headset or headphones were unplugged, or that 
        //    the device was removed from a dock connector that supports audio output. In such a case,
        //    pause or stop audio (as advised by the iOS Human Interface Guidelines).
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            
            NSLog (@"Audio output device was removed; stopping audio playback.");
            NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
            [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: myself]; 
            
        } else {
            
            NSLog (@"A route change occurred that does not require stopping application audio.");
        }
    }
}

/*************************************************************
 * audio render procedure, don't allocate memory, don't take any locks, don't waste time
 */
static OSStatus renderInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData){   
    
    soundStruct *context = (soundStruct *) inRefCon;
    UInt32 frameTotalForSound = context->frameCount;
    
    AudioSampleType *data = context->audioData;
    AudioSampleType *outSamplesChannel = (AudioSampleType *) ioData->mBuffers[0].mData;
    UInt32 sampleNumber = context->sampleNumber;
    
    UInt32 bufferPosition = inTimeStamp->mSampleTime;
    // Fill buffers
    for (UInt32 frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
        if (sampleNumber >= frameTotalForSound || !context->shouldPlay){ 
            //*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
            memset(&ioData, 0, sizeof(ioData));
            context->shouldPlay = false;
            context->sampleNumber = 0;
            [myself stopRenderForBus:inBusNumber];
            return noErr;
        }
        outSamplesChannel[frameNumber] = data[sampleNumber];
        sampleNumber++;
    }
    context->sampleNumber = sampleNumber;
    //*ioActionFlags &= ~kAudioUnitRenderAction_OutputIsSilence;
    return noErr;
}

@implementation WFBSynth

@synthesize playing;
@synthesize graphSampleRate;
@synthesize interruptedDuringPlayback;
@synthesize monoStreamFormat;
@synthesize stereoStreamFormat;
@synthesize nextAvailableUnit;

- (id) init{
    if(self = [super init]){
        myself = self;
        [self setupAudioSession];
        [self setupMonoStreamFormat];
        [self setupStereoStreamFormat];
        [self readAudioFilesIntoMemory];
        [self initializeAUGraph];
    }
    return self;
}

- (void)startAUGraph {
    
	// Start the AUGraph
	OSStatus result = AUGraphStart(mGraph);
    playing = true; //flag for audio session callback;
	// Print the result
	if (result) { 
        printf("AUGraphStart result %d %08X %4.4s\n", (int)result, (int)result, (char*)&result);
        return; 
    }
}   

- (void)stopAUGraph {
    Boolean isRunning = false;
    // Check to see if the graph is running.
    OSStatus result = AUGraphIsRunning(mGraph, &isRunning);
    // If the graph is running, stop it.
    if (isRunning) {
        result = AUGraphStop(mGraph);
        playing = false; //flag for audio session callback
    }
}

- (void)stopRenderForBus: (UInt32) busNumber{
    AudioUnitSetParameter(
                          tdMixerUnit,
                          k3DMixerParam_Enable,
                          kAudioUnitScope_Input,
                          busNumber,
                          (AudioUnitParameterValue) false,
                          0);
}

- (void)readAudioFilesIntoMemory {
    
    NSURL *pingUrl = [[NSBundle mainBundle] URLForResource:@"dino" withExtension:@"caf"];
    CFURLRef audioFile = (__bridge CFURLRef) pingUrl;
    NSLog (@"readAudioFilesIntoMemory - file: %@", pingUrl);
    
    // Instantiate an extended audio file object
    // and open the audio file and associate it with the extended audio file object.
    ExtAudioFileRef audioFileObject = 0;
    OSStatus result = ExtAudioFileOpenURL (audioFile, &audioFileObject);
    
    if (noErr != result || NULL == audioFileObject) {
        [self printErrorMessage: @"ExtAudioFileOpenURL" withStatus: result]; return;}
    
    // Get the audio file's length in frames.
    UInt64 totalFramesInFile = 0;
    UInt32 frameLengthPropertySize = sizeof (totalFramesInFile);
    
    result =    ExtAudioFileGetProperty (
                                         audioFileObject, //resulting audio file object
                                         kExtAudioFileProperty_FileLengthFrames, 
                                         &frameLengthPropertySize,
                                         &totalFramesInFile //pops the total frames of the audio into here
                                         );
    
    if (noErr != result) {[self printErrorMessage: @"ExtAudioFileGetProperty (audio file length in frames)" withStatus: result]; return;}
    
    for(int i = 0; i<kNumAudioSources; i++){
        soundSourceStructs[i].frameCount = totalFramesInFile;
    }
    
    // Assign the frame count to the soundStructArray instance variable
    AudioStreamBasicDescription fileAudioFormat = {0};
    UInt32 formatPropertySize = sizeof (fileAudioFormat);
    result =    ExtAudioFileGetProperty (
                                         audioFileObject,
                                         kExtAudioFileProperty_FileDataFormat,
                                         &formatPropertySize,
                                         &fileAudioFormat
                                         );
    
    if (noErr != result) {[self printErrorMessage: @"ExtAudioFileGetProperty (file audio format)" withStatus: result]; return;}
    
    UInt32 channelCount = fileAudioFormat.mChannelsPerFrame;
    
    // Allocate memory in each soundStruct to hold the audio data
    // in this case I am letting all of the structs point to the same buffer
    AudioSampleType *audioData = (AudioSampleType *) calloc (totalFramesInFile, sizeof (AudioSampleType));
    for(int i = 0; i<kNumAudioSources; i++){
        soundSourceStructs[i].audioData = audioData;
    }
    
    AudioStreamBasicDescription importFormat = monoStreamFormat;
    
    // Assign the appropriate mixer input bus stream data format to the extended audio 
    //        file object. This is the format used for the audio data placed into the audio 
    //        buffer in the SoundStruct data structure, which is in turn used in the 
    //        inputRenderCallback callback function.
    
    result =    ExtAudioFileSetProperty (
                                         audioFileObject,
                                         kExtAudioFileProperty_ClientDataFormat,
                                         sizeof (importFormat),
                                         &importFormat
                                         );
    
    if (noErr != result) {[self printErrorMessage: @"ExtAudioFileSetProperty (client data format)" withStatus: result]; return;}
    
    // Set up an AudioBufferList struct, which has two roles:
    //        1. It gives the ExtAudioFileRead function the configuration it 
    //            needs to correctly provide the data to the buffer.
    //        2. It points to the soundStructArray[audioFile].audioDataLeft buffer, so 
    //            that audio data obtained from disk using the ExtAudioFileRead function
    //            goes to that buffer
    
    // Allocate memory for the buffer list struct according to the number of 
    //    channels it represents.
    AudioBufferList *bufferList;
    
    bufferList = (AudioBufferList *) malloc(sizeof (AudioBufferList));
    
    if (NULL == bufferList) {NSLog (@"*** malloc failure for allocating bufferList memory"); return;}
    
    // initialize the mNumberBuffers member
    bufferList->mNumberBuffers = 1;
    
    // initialize the mBuffers member to 0
    AudioBuffer emptyBuffer = {0};
    size_t arrayIndex;
    bufferList->mBuffers[0] = emptyBuffer;
    
    // set up the AudioBuffer structs in the buffer list
    bufferList->mBuffers[0].mNumberChannels  = 1;
    bufferList->mBuffers[0].mDataByteSize    = totalFramesInFile * sizeof (AudioSampleType);
    bufferList->mBuffers[0].mData            = soundSourceStructs[0].audioData;
    
    // Perform a synchronous, sequential read of the audio data out of the file and
    //    into the soundStructArray[audioFile].audioDataLeft and (if stereo) .audioDataRight members.
    UInt32 numberOfPacketsToRead = (UInt32) totalFramesInFile;
    
    result = ExtAudioFileRead (audioFileObject, &numberOfPacketsToRead, bufferList);
    
    free (bufferList);
    
    if (noErr != result) {
        [self printErrorMessage: @"ExtAudioFileRead failure - " withStatus: result];
        free (soundSourceStructs[0].audioData);
        ExtAudioFileDispose (audioFileObject);            
        return;
    }
    
    NSLog (@"Finished reading file into memory");
    
    // Initialize all soundStructs to start at sample zero, and not be playing
    for(int i = 0; i<kNumAudioSources; i++){
        soundSourceStructs[i].sampleNumber = 0;
        soundSourceStructs[i].shouldPlay = false;
    }
    
    // Dispose of the extended audio file object, which also
    //    closes the associated file.
    ExtAudioFileDispose (audioFileObject);
}

- (void)initializeAUGraph {
    
    NSLog (@"Configuring and then initializing audio processing graph");
    OSStatus result = noErr;
    
    //............................................................................
    // Create a new audio processing graph.
    result = NewAUGraph (&mGraph);
    if (noErr != result) {[self printErrorMessage: @"NewAUGraph" withStatus: result]; return;}
    
    
    //............................................................................
    // Specify the audio unit component descriptions for the audio units to be
    //    added to the graph.
    
    // I/O unit
    AudioComponentDescription iOUnitDescription;
    iOUnitDescription.componentType          = kAudioUnitType_Output;
    iOUnitDescription.componentSubType       = kAudioUnitSubType_RemoteIO;
    iOUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    iOUnitDescription.componentFlags         = 0;
    iOUnitDescription.componentFlagsMask     = 0;
    
    // 3D Mixer unit
    AudioComponentDescription sourceUnitDescription;
    sourceUnitDescription.componentType         = kAudioUnitType_Mixer;
    sourceUnitDescription.componentSubType      = kAudioUnitSubType_AU3DMixerEmbedded;
    sourceUnitDescription.componentFlags        = 0;
    sourceUnitDescription.componentFlagsMask    = 0;
    sourceUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
//............................................................................
// Add nodes to the audio processing graph.
    NSLog (@"Adding nodes to audio processing graph");
    
    AUNode iONode;          // node for I/O unit
    AUNode tdMixerNode;       // node for Multichannel Mixer unit
    
    result = AUGraphAddNode (mGraph, &iOUnitDescription, &iONode);
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for I/O unit" withStatus: result]; return;}
    
    result = AUGraphAddNode (mGraph, &sourceUnitDescription, &tdMixerNode);
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for 3D Mixer unit" withStatus: result]; return;}
    
    
//............................................................................
// Open the audio processing graph

    // Following this call, the audio units are instantiated but not initialized
    //    (no resource allocation occurs and the audio units are not in a state to
    //    process audio).
    result = AUGraphOpen (mGraph);
    if (noErr != result) {[self printErrorMessage: @"AUGraphOpen" withStatus: result]; return;}
    
    
//............................................................................
// Load audio units into ivars
    
    result= AUGraphNodeInfo(mGraph, tdMixerNode, NULL, &tdMixerUnit);
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo (3D Mixer)" withStatus: result]; return;}
    
//............................................................................
// 3DMixer unit Setup
    UInt32 busCount = kNumAudioSources;      // bus count for mixer unit input
    NSLog (@"Setting mixer unit input bus count to: %lu", busCount);
    result = AudioUnitSetProperty (
                                   tdMixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit bus count)" withStatus: result]; return;}
    
    
//............................................................................
// Setup Callbacks for the 3D mixer units
    for (UInt16 i = 0; i < kNumAudioSources; i++) {
        AURenderCallbackStruct inputCallbackStruct;
        inputCallbackStruct.inputProc        = &renderInput;
        inputCallbackStruct.inputProcRefCon  = &soundSourceStructs[i];
        
        NSLog (@"Setting callback for 3D Mixer #%u", i);
        result = AUGraphSetNodeInputCallback (
                                              mGraph,
                                              tdMixerNode,
                                              i,
                                              &inputCallbackStruct
                                              );
        if (noErr != result) {[self printErrorMessage: @"AUGraphSetNodeInputCallback" withStatus: result]; return;}
    }
    
//............................................................................
// Set audio Stream formats
    for (UInt16 i = 0; i < kNumAudioSources; i++) {
        result = AudioUnitSetProperty (
                                       tdMixerUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       i,
                                       &monoStreamFormat,
                                       sizeof (monoStreamFormat)
                                       );
        if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty(tdMixerUnit stream format)" withStatus: result]; return;}
    }
     
    
    NSLog (@"Setting sample rate for mixer unit output scope");
    result = AudioUnitSetProperty (
                                   tdMixerUnit,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit output stream format)" withStatus: result]; return;}
    
//...........................................................................
// Customize 3DMixer properties
    UInt32 attenCurve = k3DMixerAttenuationCurve_Exponential;
    UInt32 spatialization = kSpatializationAlgorithm_HRTF;
    for(UInt32 i = 0; i < kNumAudioSources; i++){
        AudioUnitSetProperty(
                         tdMixerUnit, 
                         kAudioUnitProperty_3DMixerAttenuationCurve, 
                         kAudioUnitScope_Input, 
                         i, 
                         &attenCurve, 
                         sizeof(attenCurve));
        AudioUnitSetProperty(
                          tdMixerUnit,
                          kAudioUnitProperty_SpatializationAlgorithm,
                          kAudioUnitScope_Input,
                          i,
                          &spatialization,
                          sizeof(spatialization));
    }
    
//............................................................................
// Connect the nodes of the audio processing graph
    NSLog (@"Connecting the mixer output to the input of the I/O unit output element");
    result = AUGraphConnectNodeInput (
                                      mGraph,
                                      tdMixerNode,       // source node
                                      0,                 // source node output bus number
                                      iONode,            // destination node
                                      0                  // desintation node input bus number
                                      );
    if (noErr != result) {[self printErrorMessage: @"AUGraphConnectNodeInput" withStatus: result]; return;}
    
    
//............................................................................
// Initialize audio processing graph
    // Diagnostic code
    // Call CAShow if you want to look at the state of the audio processing 
    //    graph.
    NSLog (@"Audio processing graph state immediately before initializing it:");
    CAShow (mGraph);
    
    NSLog (@"Initializing the audio processing graph");
    // Initialize the audio processing graph, configure audio data stream formats for
    //    each input and output, and validate the connections between audio units.
    result = AUGraphInitialize (mGraph);
    if (noErr != result) {[self printErrorMessage: @"AUGraphInitialize" withStatus: result]; return;}
    
    self.nextAvailableUnit = 0; //this is basically a pointer to the next unit to use
}

- (void)playSoundWithAzimuth:(float) azimuth withDistance:(float) distance{
    OSStatus result;
    @synchronized(self){
        result = AudioUnitSetParameter(tdMixerUnit, 
                              k3DMixerParam_Azimuth, 
                              kAudioUnitScope_Input, 
                              nextAvailableUnit, 
                              azimuth, 
                              0);
        result = AudioUnitSetParameter(
                              tdMixerUnit,
                              k3DMixerParam_Distance, 
                              kAudioUnitScope_Input,
                              nextAvailableUnit,
                              (distance  / 200.0f), 
                                       0);
        result = AudioUnitSetParameter(
                                       tdMixerUnit,
                                       k3DMixerParam_Enable,
                                       kAudioUnitScope_Input,
                                       nextAvailableUnit,
                                       (AudioUnitParameterValue) true,
                                       0);
        NSLog(@"Ping: \
              \ndistance = %f\
              \nazimuth  = %f\
              \nchannel  = %d", 
              (distance / 200.0f), azimuth, nextAvailableUnit);
        AUGraphUpdate(mGraph, NULL);
        soundSourceStructs[nextAvailableUnit].sampleNumber = 0;
        soundSourceStructs[nextAvailableUnit].shouldPlay = true;
        nextAvailableUnit = ( nextAvailableUnit + 1 )% kNumAudioSources;
    }
}

- (void) turnByDegrees:(float) dHeading{
    for(UInt32 i = 0; i<kNumAudioSources; i++){
        
        //Get the current azimuth for the channel
        AudioUnitParameterValue currentAzimuth;
        AudioUnitGetParameter(
                              tdMixerUnit, 
                              k3DMixerParam_Azimuth, 
                              kAudioUnitScope_Input, 
                              i, 
                              &currentAzimuth);
        
        float currentAzimuthFloat = (float) currentAzimuth;
        float newAzimuth = currentAzimuthFloat + dHeading;
        if(newAzimuth < -180.0){
            newAzimuth = newAzimuth + 360.0;
        }
        if(newAzimuth > 180.0){
            newAzimuth = newAzimuth - 360.0;
        }
        AudioUnitSetParameter(
                              tdMixerUnit, 
                              k3DMixerParam_Azimuth, 
                              kAudioUnitScope_Input, 
                              i, 
                              (AudioUnitParameterValue) newAzimuth, 
                              0);
        AUGraphUpdate(mGraph, NULL);
        
    }
}

- (void)setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback
                     error: &audioSessionError];
    
    if (audioSessionError != nil) {
        NSLog (@"Error setting audio session category.");
        return;
    }
    
    // Request the desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredHardwareSampleRate: graphSampleRate
                                        error: &audioSessionError];
    
    if (audioSessionError != nil) {
        NSLog (@"Error setting preferred hardware sample rate.");
        return;
    }
    
    // Activate the audio session
    [mySession setActive: YES
                   error: &audioSessionError];
    
    if (audioSessionError != nil) { 
        NSLog (@"Error activating audio session during initial setup.");
        return;
    }
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [mySession currentHardwareSampleRate];
    
    // Register the audio route change listener callback function with the audio session.
    AudioSessionAddPropertyListener (
                                     kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     (void *) &self
                                     );
}

- (void)dealloc {
    DisposeAUGraph(mGraph);
}

/*************************************************************
 * Respond to having been interrupted. This method sends a notification to the 
 * controller object, which in turn invokes the playOrStop: toggle method. The 
 *    interruptedDuringPlayback flag lets the  endInterruptionWithFlags: method know 
 *    whether playback was in progress at the time of the interruption.
 */
- (void) beginInterruption {
    
    NSLog (@"Audio session was interrupted.");
    
    if (playing) {
        
        self.interruptedDuringPlayback = YES;
        
        NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
        [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: self]; 
    }
}

/*************************************************************
 * Respond to the end of an interruption. This method gets invoked, for example, 
 *   after the user dismisses a clock alarm.
 */
- (void) endInterruptionWithFlags: (NSUInteger) flags {
    
    // Test if the interruption that has just ended was one from which this app 
    //    should resume playback.
    if (flags & AVAudioSessionInterruptionFlags_ShouldResume) {
        
        NSError *endInterruptionError = nil;
        [[AVAudioSession sharedInstance] setActive: YES
                                             error: &endInterruptionError];
        if (endInterruptionError != nil) {
            
            NSLog (@"Unable to reactivate the audio session after the interruption ended.");
            return;
            
        } else {
            
            NSLog (@"Audio session reactivated after interruption.");
            
            if (interruptedDuringPlayback) {
                
                self.interruptedDuringPlayback = NO;
                
                // Resume playback by sending a notification to the controller object, which
                //    in turn invokes the playOrStop: toggle method.
                NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
                [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: self]; 
                
            }
        }
    }
}

/*************************************************************
 * UTILITY METHODS
 */
- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result {
    
    char resultString[5];
    UInt32 swappedResult = CFSwapInt32HostToBig (result);
    bcopy (&swappedResult, resultString, 4);
    resultString[4] = '\0';
    
    NSLog (
           @"*** %@ error: %d %08X %4.4s\n",
           errorString,
           (char*) &resultString
           );
}

- (void) setupStereoStreamFormat {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    
    // Fill the application audio format struct's fields to define a linear PCM, 
    //        stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mSampleRate        = graphSampleRate;
    
    
    NSLog (@"The stereo stream format");
    [self printASBD: stereoStreamFormat];
}

- (void) setupMonoStreamFormat {
    
    monoStreamFormat.mSampleRate = graphSampleRate; // set sample rate
    monoStreamFormat.mFormatID = kAudioFormatLinearPCM;
    monoStreamFormat.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    monoStreamFormat.mBitsPerChannel = sizeof(AudioSampleType) * 8; // AudioSampleType == 16 bit signed ints
    monoStreamFormat.mChannelsPerFrame = 1;
    monoStreamFormat.mFramesPerPacket = 1;
    monoStreamFormat.mBytesPerFrame = (monoStreamFormat.mBitsPerChannel / 8 ) * monoStreamFormat.mChannelsPerFrame;
    monoStreamFormat.mBytesPerPacket = monoStreamFormat.mBytesPerFrame * monoStreamFormat.mFramesPerPacket;
    
    NSLog (@"The mono stream format");
    [self printASBD: monoStreamFormat];
    
}

- (void) printASBD: (AudioStreamBasicDescription) asbd {
    
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10X",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10d",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10d",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10d",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10d",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10d",    asbd.mBitsPerChannel);
}

@end