//
//  WFBLoginViewController.m
//  TwitterSynth
//
//  Created by William Barksdale on 9/17/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBLoginViewController.h"
#import "WFBKeychainWrapper.h"

@interface WFBLoginViewController ()

@end

@implementation WFBLoginViewController

-(IBAction)dismissKeyboard:(id)sender{
    [sender resignFirstResponder];
}

-(IBAction)login:(id)sender{
    NSData *username = [self.usernameField.text dataUsingEncoding:NSUTF8StringEncoding];
    [WFBKeychainWrapper save:@"username" data:username];
    NSData *password = [self.passwordField.text dataUsingEncoding:NSUTF8StringEncoding];
    [WFBKeychainWrapper save:@"password" data:password];
    [self dismissModalViewControllerAnimated:YES];
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

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
