//
//  EMPremiumViewController.h
//  EMTwitter
//
//  Full-screen, non-dismissible paywall shown when the user is logged in.
//  Unlocks EMTwitter Premium when a whitelisted Patreon email is entered.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMPremiumViewController : UIViewController

- (void)onSubscribeTap:(UIButton *)sender;
- (void)onUnlockTap:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END