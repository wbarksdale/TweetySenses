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

- (IBAction)bleepProfanitiesChanged:(id)sender{
    UISwitch *bleepSwitch = (UISwitch *) sender;
    UITabBarController *tbar = (UITabBarController *) self.view.window.rootViewController;
    for(UIViewController *vc in tbar.viewControllers){
        if([vc isKindOfClass:[WFBViewController class]]){
            ((WFBViewController *)vc).bleepProfanities = bleepSwitch.isOn;
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
