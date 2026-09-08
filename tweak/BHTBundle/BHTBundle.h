//
//  BHTBundle.h
//  BHTwitter
//
//  Created by BandarHelal on 07/08/2022.
//

#import <Foundation/Foundation.h>
@interface BHTBundle : NSObject
+ (instancetype)sharedBundle;
- (NSString *)localizedStringForKey:(NSString *)key;
// Fetches one of Twitter's own strings from the app's Localization bundle.
- (NSString *)localizedTwitterStringForKey:(NSString *)key;
- (NSURL *)pathForFile:(NSString *)fileName;
- (NSString *)BHTwitterVersion;

@property (nonatomic, strong, readonly) NSBundle *mainBundle;  // <-- ADD THIS LINE

@end