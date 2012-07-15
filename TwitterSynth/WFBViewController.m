//
//  WFBViewController.m
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBViewController.h"

@implementation WFBViewController{
    int nilCount;
    CLLocationDirection heading;
    CLLocation *location;
}
@synthesize synth;
@synthesize geoTwitterStream;
@synthesize locationManager;
@synthesize twitterStream;

@synthesize playButton;
@synthesize soundPicker;


- (id) initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        isPlaying = false;
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

- (void) playButtonPressed:(id)sender{
    if(isPlaying){
        //stop playing
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
        [synth stopAUGraph];
        isPlaying = false;
    }else{
        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self trackLocation];
        [synth startAUGraph];
        isPlaying = true;
    }
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    [synth stopAUGraph];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// tweet stream delegates

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
                NSLog(@"Tweet:\n\
                      \tlat = %f long = %f\n\
                      \tdistance = %f\n\
                      \tbearing  = %f\n\
                      \ttext     = %@\n", latitude, longitude, distance, bearing,text);
                if(isPlaying)
                    [synth playSoundWithAzimuth:(bearing - 180.0f) withDistance: (distance)];
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

- (void) laggingStream: (NSString *) message{
    NSLog(@"warning message: \n%@\n\n", message);
}

// returns the bearing between the two points. 0 = north, 90 = east, 180 = south, 270 = east
- (double) getHeadingForDirectionFromCoordinate:(CLLocationCoordinate2D)fromLoc toCoordinate:(CLLocationCoordinate2D)toLoc
{
    double fLat = fromLoc.latitude * (M_PI/180.0);
    double fLng = fromLoc.longitude  * (M_PI/180.0);
    double tLat = toLoc.latitude  * (M_PI/180.0);
    double tLng = toLoc.longitude  * (M_PI/180.0);
    
    double headRadians = atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng));
    
    return headRadians * (180.0/M_PI) + 180.0;
}

//CLLocation delegates
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if(geoTwitterStream == nil){
        CLLocationCoordinate2D loc = [newLocation coordinate];
        CLLocationDegrees northBorder = loc.latitude + 1.9;
        CLLocationDegrees southBorder = loc.latitude - 1.9;
        CLLocationDegrees westBorder = loc.longitude - 1.9;
        CLLocationDegrees eastBorder = loc.longitude + 1.9;
        CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(southBorder, westBorder);
        CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(northBorder, eastBorder);
        NSLog(@"latitutde: %f", loc.latitude);
        NSLog(@"longitutde: %f\n", loc.longitude);
        
        //this should call should be somewhere else
        geoTwitterStream = [[WFBTwitterStream alloc] initWithSWCorner:southWest NECorner:northEast listener:self];
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
