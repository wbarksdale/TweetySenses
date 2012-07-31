//
//  WFBViewController.m
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBViewController.h"

#define kBOUNDING_BOX_SIZE 333000
//111,000m in 1 degree

@implementation WFBViewController{
    int nilCount;
    CLLocationDirection heading;
    CLLocation *location;
}

@synthesize synth;
@synthesize twitterStream;
@synthesize locationManager;

@synthesize isPlaying;
@synthesize bleepProfanities;

@synthesize playButton;
@synthesize soundPicker;
@synthesize tweetLabel;

- (id) initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        self.isPlaying = false;
        self.bleepProfanities = true;
        [WFBSoundSourceManager loadSoundSourceList];
        self.synth = [[WFBSynth alloc] init];
    }
    return self;
}

- (void) trackLocation{
    //get location
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    [locationManager startUpdatingHeading];
}

- (void) stopTrackingLocation{
    [locationManager stopUpdatingLocation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)stopStream{
    [twitterStream stopStream];
}

- (IBAction)playButtonPressed:(id)sender{
    if(self.isPlaying){
        //stop playing
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
        [twitterStream stopStream];
        [self stopTrackingLocation];
        [synth stopAUGraph];
        self.isPlaying = false;
    }else{
        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self trackLocation];
        [synth startAUGraph];
        self.isPlaying = true;
    }
}

- (IBAction)bleepProfanitiesChanged:(id)sender{
    UISwitch *bleepSwitch = (UISwitch *) sender;
    self.bleepProfanities = bleepSwitch.isOn;
    NSLog(@"bleepProfanities = %@", self.bleepProfanities ? @"true" : @"false");
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
    //calculate distance
    NSDictionary *coordinatesDict = [tweet objectForKey:@"coordinates"];
    NSNull *nullObj = [NSNull null];
    if(![coordinatesDict isEqual: nullObj]){
        NSArray *coordinatesArray = [coordinatesDict objectForKey:@"coordinates"];
        if(![coordinatesArray isEqual:nullObj]){
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
                NSLog(@"\n\tTweet:\
                      \n\tlat = %f long = %f\
                      \n\tdistance = %f\
                      \n\tbearing  = %f\
                      \n\ttext     = %@", latitude, longitude, distance, bearing,text);
                [self.tweetLabel setText:text];
                if(self.isPlaying){
                    double maxDistance = sqrt( (double) (2.0 * kBOUNDING_BOX_SIZE * kBOUNDING_BOX_SIZE) );
                    
                    NSString *sound = @"default";
                    float playbackRate = 1.0;
                    
                    //Profanities code
                    int numProfanities = [self countProfanities:[tweet objectForKey:@"text"]];
                    if(numProfanities > 0 && self.bleepProfanities){
                        playbackRate = 1 - (.1 * numProfanities);
                        if(playbackRate <= 0){
                            playbackRate = .1;
                        }
                        sound = @"bleep";
                    }
                        
                    [synth playSound:sound
                         withAzimuth:(bearing - 180.0f)
                        withDistance:(float) ((distance / maxDistance) * 1000)
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

- (void) laggingStream: (NSString *) message{
    NSLog(@"warning message: \n%@\n\n", message);
}


#pragma mark LocationDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if(!twitterStream){
        self.twitterStream = [[WFBTwitterStream alloc] initWithListener:self];
    }
    if(!twitterStream.streaming){
        CLLocationCoordinate2D loc = [newLocation coordinate];
        NSLog(@"bouding box is %f degrees", kBOUNDING_BOX_SIZE/111000.0);
        CLLocationDegrees northBorder = loc.latitude + kBOUNDING_BOX_SIZE / 111000;
        CLLocationDegrees southBorder = loc.latitude - kBOUNDING_BOX_SIZE / 111000;
        CLLocationDegrees westBorder = loc.longitude - kBOUNDING_BOX_SIZE / 111000;
        CLLocationDegrees eastBorder = loc.longitude + kBOUNDING_BOX_SIZE / 111000;
        CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(southBorder, westBorder);
        CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(northBorder, eastBorder);
        NSLog(@"latitutde: %f", loc.latitude);
        NSLog(@"longitutde: %f\n", loc.longitude);
        
        //this should call should be somewhere else
        [twitterStream startStreamWithSWCorner:southWest NECorner:northEast];
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
    [synth readAudioFileIntoMemory:soundUrl];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    NSArray *sounds = [WFBSoundSourceManager getSounds];
    return [sounds objectAtIndex:row];
}

@end
