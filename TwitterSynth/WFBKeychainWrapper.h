//Attribution to user:anomie on stack overflow

#import <Foundation/Foundation.h>

//@class SimpleKeychainUserPass;

@interface WFBKeychainWrapper : NSObject

+ (void)save:(NSString *)service data:(id)data;
+ (id)load:(NSString *)service;
+ (void)delete:(NSString *)service;

@end