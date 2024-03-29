//
//  WFBViewController.m
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBViewController.h"
//111,000m in 1 degree

@interface WFBViewController(){
    bool shouldStream;
    bool isStreaming;
    bool isPlaying;
}

@property(nonatomic) bool shouldStream;
@property(nonatomic) bool isStreaming;
@property(nonatomic) bool shouldPlay;
@property(nonatomic) bool isPlaying;

-(void) startTwitterStream;
-(bool) isFollower:(NSDictionary *)userDict;

@end

@implementation WFBViewController{
    int nilCount;
    CLLocationDirection heading;
    CLLocation *location;
}


@synthesize synth;
@synthesize twitterStream;
@synthesize locationManager;
@synthesize bleepProfanities;
@synthesize playButton;
@synthesize soundPicker;
@synthesize tweetLabel;
@synthesize boundingBoxSize;
@synthesize playFollowerSound;

@synthesize shouldStream;
@synthesize isStreaming;
@synthesize isPlaying;

#define WFBTwitterConnectionFailure     @"WFBTwitterConnectionFailure"
#define WFBTwitterConnectionSuccess     @"WFBTwitterConnectionSuccess"
#define WFBLocationAquired              @"WFBLocationAquired"
#define WFBFailedToAquireLocation       @"WFBFailedToAquireLocation"

const Float32 MIN_PLAYBACK_RATE = .25;
const Float32 MAX_PLAYBACK_RATE = 1.75;
const Float32 MIN_FOLLOWER_COUNT = 20.0;
const Float32 MAX_FOLLOWER_COUNT = 3000;

- (id) initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        self.shouldPlay = false;
        self.isPlaying = false;
        self.shouldStream = false;
        self.isStreaming = false;
        self.boundingBoxSize = 180000;
        
        self.bleepProfanities = true;
        [WFBSoundSourceManager loadSoundSourceList];
        self.synth = [[WFBSynth alloc] init];
        
        //register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processNotification:)
                                                     name:WFBTwitterConnectionSuccess
                                                   object:nil];
        //register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processNotification:)
                                                     name:WFBTwitterConnectionFailure
                                                   object:nil];
        //register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processNotification:)
                                                     name:WFBLocationAquired
                                                   object:nil];
        //register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processNotification:)
                                                     name:WFBFailedToAquireLocation
                                                   object:nil];
    }
    return self;
}

- (void) processNotification: (NSNotification *) notification{
    NSLog(@"Notification Delivered: %@", [notification name]);
    NSString *note = [notification name];
    if([note isEqualToString:WFBFailedToAquireLocation]){
        NSLog(@"Failed to Aquire location");
        //alert user
    }
    if([note isEqualToString:WFBLocationAquired]){
        if(self.shouldStream){
            [self startTwitterStream];
        }
    }
    if([note isEqualToString:WFBTwitterConnectionSuccess]){
        [synth startAUGraph];
        self.isStreaming = true;
        self.isPlaying = true;
    }
    if([note isEqualToString:WFBTwitterConnectionFailure]){
        NSLog(@"could not connect to twitter stream");
        [self stopTrackingLocation];
        [self stopTwitterStream];
        self.isStreaming = false;
        self.shouldStream = false;
        self.isPlaying = false;
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
        //alert user
    }
}

- (void) viewDidLoad
{
    //set sonar_ping to default sound
    NSArray *sounds = [WFBSoundSourceManager getSounds];
    for(int i = 0; i < sounds.count; i++){
        if([[sounds objectAtIndex:i] isEqualToString:@"sonar_ping"]){
            [soundPicker selectRow:i inComponent:0 animated:NO];
            NSString *soundUrl = [WFBSoundSourceManager getURLForSound:[sounds objectAtIndex: i]];
            [synth readAudioFileIntoMemory:soundUrl];
        }
    }
    
    [super viewDidLoad];
}

- (IBAction)playButtonPressed:(id)sender{
    if(self.shouldStream && !self.isPlaying){
        return;
    }
    if(self.shouldStream){
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
        [self stopTwitterStream];
        [self stopTrackingLocation];
        [synth stopAUGraph];
        self.isPlaying = false;
    }else{
        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
        //first get some kind of location
        [self stopTwitterStream];   // just to make sure the connection is dead
        self.shouldStream = true;
        [self startTrackingLocation];
    }
}

- (void)stopTwitterStream{
    self.isStreaming = false;
    self.shouldStream = false;
    [twitterStream stopStream];
}

-(void) startTwitterStream {
    self.twitterStream = [[WFBTwitterStream alloc] initWithListener:self];
    if(location != nil){
        CLLocationCoordinate2D loc = [location coordinate];
        NSLog(@"bouding box is %f degrees", self.boundingBoxSize/111000.0);
        CLLocationDegrees northBorder = loc.latitude + self.boundingBoxSize / 111000;
        CLLocationDegrees southBorder = loc.latitude - self.boundingBoxSize / 111000;
        CLLocationDegrees westBorder = loc.longitude - self.boundingBoxSize / 111000;
        CLLocationDegrees eastBorder = loc.longitude + self.boundingBoxSize / 111000;
        CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(southBorder, westBorder);
        CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(northBorder, eastBorder);
        NSLog(@"latitutde: %f", loc.latitude);
        NSLog(@"longitutde: %f\n", loc.longitude);
        [twitterStream startStreamWithSWCorner:southWest NECorner:northEast];
    }else{
        NSLog(@"could not get location");
    }
}

- (void) startTrackingLocation{
    //get location
    location = nil;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    [locationManager startUpdatingHeading];
}

- (void) stopTrackingLocation{
    [locationManager stopUpdatingLocation];
    location = nil;
}

#define TEST_DISTANCE true
#define TEST_AZIMUTH true
- (IBAction)runSynthTests:(id)sender{
    [synth startAUGraph];
    
    if(TEST_DISTANCE){
        for(float i = 1.0; i < 20; i = i * 2){
            DLog(@"testing distance: %f", i)
            [synth playSound:@"default"
                 withAzimuth:0.0f
                withDistance:i
             withPitchChange:1.0f];
            [NSThread sleepForTimeInterval:.75];
        }
    }
    
    if(TEST_AZIMUTH){
        for(int i = -18; i <= 18; i += 3){
            DLog(@"testing azimuth: %d", i * 10)
            [synth playSound:@"default"
                 withAzimuth:i * 10.0f
                withDistance:500.0f
             withPitchChange:1.0f];
            [NSThread sleepForTimeInterval:.75];
        }
    }
    [synth stopAUGraph];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    [synth stopAUGraph];
    [twitterStream stopStream];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

/**
 * UTILITY
 * returns the bearing between the two points. 0 = north, 90 = east, 180 = south, 270 = east
 */
- (double) getHeadingForDirectionFromCoordinate:(CLLocationCoordinate2D)fromLoc toCoordinate:(CLLocationCoordinate2D)toLoc
{
    double fLat = fromLoc.latitude * (M_PI/180.0);
    double fLng = fromLoc.longitude  * (M_PI/180.0);
    double tLat = toLoc.latitude  * (M_PI/180.0);
    double tLng = toLoc.longitude  * (M_PI/180.0);
    
    double headRadians = atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng));
    
    return headRadians * (180.0/M_PI) + 180.0;
}

#pragma mark TweetStreamDelegate methods

- (void) receiveTweet:(NSDictionary *) tweet{
    if(!synth.isPlaying){
        NSLog(@"Got the first tweet");
        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
        [synth startAUGraph];
        self.isPlaying = true;
    }
    NSDictionary *coordinatesDict = [tweet objectForKey:@"coordinates"];
    if(![coordinatesDict isEqual: [NSNull null]]){
        NSArray *coordinatesArray = [coordinatesDict objectForKey:@"coordinates"];
        if(![coordinatesArray isEqual:[NSNull null]]){
            
            //At this point the tweet certainly has location
            double longitude = [[coordinatesArray objectAtIndex:0] doubleValue];
            double latitude = [[coordinatesArray objectAtIndex:1] doubleValue];
            if(latitude != 0){
                CLLocation *tweetLoc = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                CLLocationDistance distance = [location distanceFromLocation:tweetLoc];
                double bearing = [self getHeadingForDirectionFromCoordinate:tweetLoc.coordinate toCoordinate:location.coordinate];
                NSString *text = [tweet objectForKey:@"text"];
                if(text == nil){
                    text = @"no text";
                }
                DLog(@"\n\tTweet:\
                      \n\tlat = %f long = %f\
                      \n\tdistance = %f\
                      \n\tbearing  = %f\
                      \n\ttext     = %@", latitude, longitude, distance, bearing,text);
                if([self countProfanities:text] > 0){
                    [self.tweetLabel setText:@"********************************"];
                }else {
                    [self.tweetLabel setText:text];
                }

                //play some sound
                if(self.isPlaying){
                    double maxDistance = sqrt( (double) (2.0 * self.boundingBoxSize * self.boundingBoxSize) );
                    
                    //figure out what sound should play
                    NSString *sound = @"default";
                    int numProfanities = [self countProfanities:[tweet objectForKey:@"text"]];
                    if(numProfanities > 0 && self.bleepProfanities){
                        sound = @"bleep";
                    }

                    //figure out the playback rate to use based on followers_count
                    Float32 playbackRate = MAX_PLAYBACK_RATE;
                    NSDictionary *user = [tweet objectForKey:@"user"];
                    if(![user isEqual:[NSNull null]]){
                        int followersCount = [[user objectForKey:@"followers_count"] intValue];
                        DLog(@"followersCount: %d", followersCount);
                        if(followersCount < MIN_FOLLOWER_COUNT) playbackRate = MAX_PLAYBACK_RATE;
                        if(followersCount > MAX_FOLLOWER_COUNT) playbackRate = MIN_PLAYBACK_RATE;
                        if(followersCount >= MIN_FOLLOWER_COUNT && followersCount <= MAX_FOLLOWER_COUNT){
                            //compute playback rate from follower count
                            //playback rate is inversely and linearly related to the follower count
                            Float32 rise = MIN_PLAYBACK_RATE - MAX_PLAYBACK_RATE;
                            Float32 run = MAX_FOLLOWER_COUNT - MIN_FOLLOWER_COUNT;
                            Float32 slope = rise/run;
                            Float32 intercept = MIN_PLAYBACK_RATE - MAX_FOLLOWER_COUNT * slope;
                            playbackRate = followersCount * slope + intercept;
                            NSLog(@"playback rate: %f", playbackRate);
                        }
                        
                        /* this doesnt work because twitter API lied
                        if([self isFollower:user]){
                            NSLog(@"FOLLOWER TWEETED");
                            sound = @"follower";
                        }
                        */
                    }
                    NSLog(@"playback rate: %f", playbackRate);
                    [synth playSound:sound
                         withAzimuth:(bearing - 180.0f)
                        withDistance:(float) ((distance / maxDistance) * 20 + 1)
                     withPitchChange:playbackRate];
                }
            }else{
                //NSLog(@"badtweet");
            }
        }else{
            //NSLog(@"badtweet");
        }
    }else{
        //NSLog(@"badtweet");
    }
}

// I tried to implement a feature that would play a different sond for
//  tweets that came from users that the user was following
//  however the twitter API did not actually deliver the field as promised
-(bool)isFollower: (NSDictionary *) userDict{
    if([userDict isEqual:[NSNull null]]) return false;
    if(![[userDict objectForKey:@"screen_name"] isEqual:[NSNull null]]) NSLog(@"%@", userDict);
    if([[userDict objectForKey:@"following"] isEqual:[NSNull null]]) return false;
    return [[userDict objectForKey:@"following"] boolValue];
}

- (void) laggingStream: (NSString *) message{
    NSLog(@"warning message: \n%@\n\n", message);
}

//These values are not actually displayed to the user
// but rather are used as filter words
static NSArray *profanities = [NSArray arrayWithObjects:
                               @"fuck", 
                               @"bitch",
                               @"cunt",
                               @"suck",
                               @"balls",
                               @"shit",
                               @"fucker",
                               @"trick",
                               @"ho", 
                               @"ass", 
                               @"niggas",
                               @"nigga",
                               nil];

- (int) countProfanities: (NSString *)text{
    int count = 0;
    NSArray *words = [text componentsSeparatedByString:@" "];
    for(NSString *word in words){
        for(NSString *profanity in profanities){
            if([word isEqualToString:profanity]){
                count++;
            }
        }
    }
    return count;
}


#pragma mark LocationDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if(!self.isStreaming){
        NSLog(@"not streaming");
        @synchronized(self){
            NSLog(@"synchronized");
            if(!newLocation){
                NSLog(@"Invalid Location was delivered for some reason");
                return;
            }
            if(!location && self.shouldStream){
                NSLog(@"posting note");
                location = newLocation;
                [[NSNotificationCenter defaultCenter] postNotificationName:WFBLocationAquired object:nil];
            }
        }
    }
    location = newLocation;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"did fail with error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if(newHeading.trueHeading >0){
        float dHeading = newHeading.trueHeading - heading;
        [synth turnByDegrees:dHeading];
        heading = newHeading.trueHeading;
    }
}

#pragma mark UIPickerViewDataSource methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    NSArray *sounds = [WFBSoundSourceManager getSounds];
    return [sounds count];
}

#pragma mark UIPickerViewDelegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSArray *sounds = [WFBSoundSourceManager getSounds];
    NSString *soundUrl = [WFBSoundSourceManager getURLForSound:[sounds objectAtIndex:row]];
    NSLog(@"sound url %@", soundUrl);
    [synth readAudioFileIntoMemory:soundUrl];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    NSArray *sounds = [WFBSoundSourceManager getSounds];
    return [sounds objectAtIndex:row];
}

@end
