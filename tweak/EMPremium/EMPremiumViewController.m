//
//  EMPremiumViewController.m
//  EMTwitter
//
//  Full-screen, non-dismissible paywall shown when the user is logged in.
//  - Prompts the user to subscribe on the EmAppleFlagship Patreon page
//    (EAF Pro or Ultra tiers) to unlock EMTwitter Premium.
//  - Lets the user enter the Patreon email they subscribed with.
//  - If the email is on the whitelist (see BHTManager), EMTwitter Premium
//    is unlocked permanently on the device.
//

#import "EMPremiumViewController.h"
#import "../BHTManager.h"
#import "../BHTBundle/BHTBundle.h"
#import "../FrostedNavBar/EMFrostedNavBar.h"

@interface EMPremiumViewController ()
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UILabel *errorLabel;
@end

@implementation EMPremiumViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"verified_stroke"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = UIColor.labelColor;

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_TITLE"];
    title.textColor = UIColor.labelColor;
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    title.textAlignment = NSTextAlignmentCenter;

    UILabel *message = [[UILabel alloc] init];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.text = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_MESSAGE"];
    message.textColor = UIColor.secondaryLabelColor;
    message.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    message.textAlignment = NSTextAlignmentCenter;
    message.numberOfLines = 0;

    UIButton *subscribeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [subscribeButton setTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_SUBSCRIBE_BUTTON"]
                      forState:UIControlStateNormal];
    [subscribeButton setTitleColor:UIColor.labelColor forState:UIControlStateNormal];
    [subscribeButton addTarget:self action:@selector(onSubscribeTap:) forControlEvents:UIControlEventTouchUpInside];
    subscribeButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.emailField = [UITextField new];
    self.emailField.placeholder = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_EMAIL_PLACEHOLDER"];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailField.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *unlockButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [unlockButton setTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_UNLOCK_BUTTON"]
                     forState:UIControlStateNormal];
    [unlockButton setTitleColor:UIColor.labelColor forState:UIControlStateNormal];
    [unlockButton addTarget:self action:@selector(onUnlockTap:) forControlEvents:UIControlEventTouchUpInside];
    unlockButton.translatesAutoresizingMaskIntoConstraints = NO;

    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.errorLabel.text = @"";
    self.errorLabel.textColor = UIColor.systemRedColor;
    self.errorLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.numberOfLines = 0;

    [self.view addSubview:icon];
    [self.view addSubview:title];
    [self.view addSubview:message];
    [self.view addSubview:subscribeButton];
    [self.view addSubview:self.emailField];
    [self.view addSubview:unlockButton];
    [self.view addSubview:self.errorLabel];

    [NSLayoutConstraint activateConstraints:@[
        [icon.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [icon.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:140],
        [title.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:20],
        [message.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [message.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:14],
        [message.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-48],
        [subscribeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [subscribeButton.topAnchor constraintEqualToAnchor:message.bottomAnchor constant:28],
        [self.emailField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emailField.topAnchor constraintEqualToAnchor:subscribeButton.bottomAnchor constant:20],
        [self.emailField.widthAnchor constraintEqualToConstant:300],
        [unlockButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [unlockButton.topAnchor constraintEqualToAnchor:self.emailField.bottomAnchor constant:20],
        [self.errorLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.errorLabel.topAnchor constraintEqualToAnchor:unlockButton.bottomAnchor constant:14],
        [self.errorLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-48]
    ]];
}

- (void)onSubscribeTap:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[BHTManager premiumPatreonURL]]
                                              options:@{}
                                    completionHandler:nil];
}

- (void)onUnlockTap:(UIButton *)sender {
    NSString *email = self.emailField.text;
    if (email == nil) email = @"";
    if ([BHTManager isPremiumEmail:email]) {
        [BHTManager setPremiumEmail:email];
        [BHTManager setPremium:YES];
        self.errorLabel.text = @"";
        [self dismissViewControllerAnimated:YES completion:^{
            // Bring the floating nav pill back now that the paywall is gone.
            [EMFrostedNavBar installIfNeeded];
        }];
    } else {
        self.errorLabel.text = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_INVALID_EMAIL"];
    }
}

@end