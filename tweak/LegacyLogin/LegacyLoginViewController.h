#import <UIKit/UIKit.h>

// Reimplementation of 9.67's built-in xAuth login form.
// Vendored from https://github.com/orionblur/NeoFreeBird (LegacyLogin).
@interface LegacyLoginViewController : UIViewController
+ (void)presentLoginFrom:(UIViewController*)presenter;

+ (UINavigationController*)loginRootNavigationController;
@end