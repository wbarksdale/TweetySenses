//
//  WFBSoundSources.m
//  TwitterSynth
//
//  Created by William Barksdale on 7/14/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import "WFBSoundSourceManager.h"

#define kSoundsDirectory @"tweetsounds"

@implementation WFBSoundSourceManager

static NSString __strong *baseUrl = nil;
static NSArray __strong *soundSourceNames = nil;

+ (void) loadSoundSourceList{
    baseUrl = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], kSoundsDirectory];
    NSFileManager *manager = [NSFileManager defaultManager];
    soundSourceNames = [manager contentsOfDirectoryAtPath:baseUrl error:nil];
    NSLog(@"%@", soundSourceNames);
}

+ (NSString *) defaultSoundUrl{
    if(!soundSourceNames)
        [WFBSoundSourceManager loadSoundSourceList];
    return [baseUrl stringByAppendingPathComponent:[soundSourceNames objectAtIndex:0]];
}

+ (NSArray *) getSounds{
    if(!soundSourceNames)
        [WFBSoundSourceManager loadSoundSourceList];
    return soundSourceNames;
}

+ (NSString *) getURLForSound: (NSString *) soundName{
    return [baseUrl stringByAppendingPathComponent:soundName];
}

@end
