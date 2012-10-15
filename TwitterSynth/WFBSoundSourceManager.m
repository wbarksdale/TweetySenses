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
@synthesize followerSound;

static NSString __strong *baseUrl = nil;
static NSArray __strong *soundSourceNames = nil;

+ (void) loadSoundSourceList{
    baseUrl = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], kSoundsDirectory];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *rawSources = [manager contentsOfDirectoryAtPath:baseUrl error:nil];
    
    //strip .caf from files
    NSMutableArray *sources = [[NSMutableArray alloc] init];
    int index = 0;
    for(NSString *rawSource in rawSources){
        NSString *sound = [rawSource substringToIndex:rawSource.length - 4];
        [sources insertObject:sound atIndex:index];
        index++;
    }
    soundSourceNames = [[NSArray alloc] initWithArray:sources];
    NSLog(@"%@", soundSourceNames);
}

+ (NSString *) defaultSoundUrl{
    if(!soundSourceNames)
        [WFBSoundSourceManager loadSoundSourceList];
    return [baseUrl stringByAppendingPathComponent:[[soundSourceNames objectAtIndex:0] stringByAppendingString:@".caf"]];
}

+ (NSString *) bleepSoundUrl{
    if(!soundSourceNames){
        [WFBSoundSourceManager loadSoundSourceList];
    }
    return [baseUrl stringByAppendingPathComponent:@"bleep.caf"];
}

+ (NSArray *) getSounds{
    if(!soundSourceNames)
        [WFBSoundSourceManager loadSoundSourceList];
    return soundSourceNames;
}

+ (NSString *) getURLForSound: (NSString *) soundName{
   return [baseUrl stringByAppendingPathComponent:[soundName stringByAppendingString:@".caf"]];
}

@end
