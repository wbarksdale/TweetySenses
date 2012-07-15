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
    WFBTwitterStream *geoTwitterStream;
    CLLocationManager *locationManager;
    WFBSynth *synth;
    
    bool isPlaying;
    IBOutlet UIPickerView *soundPicker;
    IBOutlet UIButton *playButton;
}

- (IBAction)playButtonPressed:(id)sender;

@property(nonatomic, strong) IBOutlet UIPickerView *soundPicker;
@property(nonatomic, strong) IBOutlet UIButton *playButton;

@property(nonatomic, strong) WFBSynth *synth;
@property(nonatomic, strong) WFBTwitterStream *twitterStream;
@property(nonatomic, strong) WFBTwitterStream *geoTwitterStream;
@property(nonatomic, strong) CLLocationManager *locationManager;

@end
