//
//  WFBLoginViewController.h
//  TwitterSynth
//
//  Created by William Barksdale on 9/17/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFBLoginViewController : UIViewController{

IBOutlet UITextField *usernameField;
IBOutlet UITextField *passwordField;

}

-(IBAction)dismissKeyboard:(id)sender;
-(IBAction)login:(id)sender;

@property(nonatomic, strong) IBOutlet UITextField *usernameField;
@property(nonatomic, strong) IBOutlet UITextField *passwordField;

@end