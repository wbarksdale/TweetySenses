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

- (void) trackLocation{
    //get location
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    [locationManager startUpdatingHeading];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // NSArray *keywords = [[NSArray alloc] initWithObjects:@"happy", @"sad", nil];
    // twitterStream = [[WFBTwitterStream alloc] initWithKeywords:keywords andListener:self];
    self.synth = [[WFBSynth alloc] init];
    [synth startAUGraph];
    [self trackLocation];
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
                //TODO
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
        CLLocationDegrees northBorder = loc.latitude + 1.7;
        CLLocationDegrees southBorder = loc.latitude - 1.7;
        CLLocationDegrees westBorder = loc.longitude - 1.7;
        CLLocationDegrees eastBorder = loc.longitude + 1.7;
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

@end
