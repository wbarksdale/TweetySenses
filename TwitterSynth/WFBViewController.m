//
//  WFBViewController.m
//  TwitterSynth
//
//  Created by William Barksdale on 6/8/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBViewController.h"

@implementation WFBViewController{
    double happyCount;
    double sadCount;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSArray *keywords = [[NSArray alloc] initWithObjects:@"happy", @"sad", nil];
    twitterStream = [[WFBTwitterStream alloc] initWithKeywords:keywords andListener:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    happyCount = 0;
    sadCount = 0;
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// tweet stream delegates

- (void) receiveTweet:(NSDictionary *) tweet{
    NSString *text = [tweet objectForKey:@"text"];
    if([text rangeOfString:@"happy"].location == NSNotFound){
        sadCount += 1.0;
    }else{
        happyCount += 1.0;
    }
    NSLog(@"%f", happyCount/(happyCount + sadCount));
}

@end
