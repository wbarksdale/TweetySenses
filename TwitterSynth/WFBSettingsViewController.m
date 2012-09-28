//
//  WFBSettingsViewController.m
//  TwitterSynth
//
//  Created by William Barksdale on 9/22/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBSettingsViewController.h"
#import "WFBViewController.h"

@interface WFBSettingsViewController ()

@end

@implementation WFBSettingsViewController

@synthesize boundingBoxSlider;
@synthesize boundingBoxSizeLabel;

- (IBAction)bleepProfanitiesChanged:(id)sender{
    UISwitch *bleepSwitch = (UISwitch *) sender;
    self.getMainVC.bleepProfanities = bleepSwitch.isOn;
}

- (IBAction)valueChanged:(id)sender{
    UISlider *changedSlider = (UISlider *)sender;
    if(changedSlider == self.boundingBoxSlider){
        int newBoundingBoxSize = [changedSlider value];
        self.getMainVC.boundingBoxSize = newBoundingBoxSize * 1000;
        self.boundingBoxSizeLabel.text = [NSString stringWithFormat:@"%dkm", newBoundingBoxSize];
    }
}

- (WFBViewController *) getMainVC{
    UITabBarController *tbar = (UITabBarController *) self.view.window.rootViewController;
    for(UIViewController *vc in tbar.viewControllers){
        if([vc isKindOfClass:[WFBViewController class]]){
            return (WFBViewController *) vc;
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
