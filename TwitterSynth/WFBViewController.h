//
//  WFBViewController.h
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFBTwitterStream.h"
#import "WFBTwitterStreamListener.h"
#import <CoreLocation/CoreLocation.h>

@interface WFBViewController : UIViewController <WFBTwitterStreamListener, CLLocationManagerDelegate>
{
    WFBTwitterStream *twitterStream;
    WFBTwitterStream *geoTwitterStream;
    CLLocationManager *locationManager;
}

@property(nonatomic) WFBTwitterStream *twitterStream;
@property(nonatomic) WFBTwitterStream *geoTwitterStream;
@property(nonatomic) CLLocationManager *locationManager;

@end
