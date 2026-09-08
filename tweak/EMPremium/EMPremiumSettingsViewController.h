//
//  EMPremiumSettingsViewController.h
//  EMTwitter
//
//  Settings page showing EMTwitter Premium status, with the option to
//  subscribe on Patreon or enter a whitelisted Patreon email to unlock.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TFNTwitterAccount;

@interface EMPremiumSettingsViewController : UIViewController

- (instancetype)initWithAccount:(TFNTwitterAccount *)account;
- (void)onSubscribeTap:(UIButton *)sender;
- (void)onUnlockTap:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END