//
//  WFBSettingsViewController.h
//  TwitterSynth
//
//  Created by William Barksdale on 9/22/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFBSettingsViewController : UIViewController{
    IBOutlet UISlider *boundingBoxSlider;
    IBOutlet UILabel *boundingBoxSizeLabel;
}

@property(nonatomic, retain) IBOutlet UISlider *boundingBoxSlider;
@property(nonatomic, retain) IBOutlet UILabel *boundingBoxSizeLabel;

- (IBAction)bleepProfanitiesChanged:(id)sender;
- (IBAction)valueChanged:(id)sender;

@end
