//
//  EMFrostedNavBar.h
//  EMTwitter
//
//  Floating frosted-glass navigation pill that replaces the stock tab bar.
//

#import <UIKit/UIKit.h>

@interface EMFrostedNavBar : NSObject
// Installs the floating pill on the active window (if the tab bar is up) and
// hides the stock tab bar. Safe to call repeatedly.
+ (void)installIfNeeded;
// Re-renders the pill's icons with the current accent color / selection state.
+ (void)refreshTint;
// Removes the pill from every window and resets state.
+ (void)removeAll;
// Switches the app to the tab whose scribe page ID equals pageID.
+ (void)selectTabWithPageID:(NSString *)pageID;
@end