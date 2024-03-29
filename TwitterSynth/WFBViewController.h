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
#import "WFBSynth.h"

@interface WFBViewController : UIViewController <WFBTwitterStreamListener,
            CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    WFBTwitterStream *twitterStream;
    CLLocationManager *locationManager;
    WFBSynth *synth;

    bool bleepProfanities;
    bool playFollowerSound;
    
    int boundingBoxSize;
    IBOutlet UIPickerView *soundPicker;
    IBOutlet UIButton *playButton;
    IBOutlet UILabel *tweetLabel;
}

- (IBAction)playButtonPressed:(id)sender;
- (IBAction)runSynthTests:(id)sender;

- (void) stopStream;
- (void) stopTrackingLocation;

@property(nonatomic) bool bleepProfanities;
@property(nonatomic) bool playFollowerSound;
@property(nonatomic) int boundingBoxSize;

@property(nonatomic, strong) IBOutlet UIPickerView *soundPicker;
@property(nonatomic, strong) IBOutlet UIButton *playButton;
@property(nonatomic, strong) IBOutlet UILabel *tweetLabel;

@property(nonatomic, strong) WFBSynth *synth;
@property(nonatomic, strong) WFBTwitterStream *twitterStream;
@property(nonatomic, strong) CLLocationManager *locationManager;

@end
