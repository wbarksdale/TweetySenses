//
//  WFBSoundSources.h
//  TwitterSynth
//
//  Created by William Barksdale on 7/14/12.
//  Copyright (c) 2012 University of Richmond. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFBSoundSourceManager : NSObject{
    
}

+ (void) loadSoundSourceList;
+ (NSArray *) getSounds;
+ (NSString *) getURLForSound: (NSString *) soundName;
+ (NSString *) defaultSoundUrl;

@end
