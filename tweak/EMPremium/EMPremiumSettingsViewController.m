//
//  EMPremiumSettingsViewController.m
//  EMTwitter
//
//  Settings page showing EMTwitter Premium status, with the option to
//  subscribe on Patreon or enter a whitelisted Patreon email to unlock.
//

#import "EMPremiumSettingsViewController.h"
#import "../BHTManager.h"
#import "../BHTBundle/BHTBundle.h"
#import "../BHDimPalette.h"

@interface EMPremiumSettingsViewController ()
@property (nonatomic, strong) TFNTwitterAccount *account;
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UILabel *errorLabel;
@end

@implementation EMPremiumSettingsViewController

- (instancetype)initWithAccount:(TFNTwitterAccount *)account {
    if ((self = [super init])) {
        self.account = account;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNav];
    [self buildUI];
}

- (void)setupNav {
    NSString *title = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_SETTINGS_TITLE"];
    if (self.account) {
        self.navigationItem.titleView = [objc_getClass("TFNTitleView") titleViewWithTitle:title subtitle:self.account.displayUsername];
    } else {
        self.title = title;
    }
}

- (void)buildUI {
    self.view.backgroundColor = [BHDimPalette currentBackgroundColor];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"verified_stroke"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = UIColor.labelColor;

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_TITLE"];
    title.textColor = UIColor.labelColor;
    title.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    title.textAlignment = NSTextAlignmentCenter;

    UILabel *status = [[UILabel alloc] init];
    status.translatesAutoresizingMaskIntoConstraints = NO;
    status.textAlignment = NSTextAlignmentCenter;
    status.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    if ([BHTManager Premium]) {
        status.text = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_SETTINGS_STATUS_UNLOCKED"];
        status.textColor = UIColor.systemGreenColor;
    } else {
        status.text = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_SETTINGS_STATUS_LOCKED"];
        status.textColor = UIColor.systemRedColor;
    }

    UILabel *message = [[UILabel alloc] init];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.text = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_SETTINGS_SUBTITLE"];
    message.textColor = UIColor.secondaryLabelColor;
    message.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    message.textAlignment = NSTextAlignmentCenter;
    message.numberOfLines = 0;

    UIButton *subscribeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [subscribeButton setTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_SUBSCRIBE_BUTTON"]
                      forState:UIControlStateNormal];
    [subscribeButton setTitleColor:UIColor.labelColor forState:UIControlStateNormal];
    [subscribeButton addTarget:self action:@selector(onSubscribeTap:) forControlEvents:UIControlEventTouchUpInside];
    subscribeButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:icon];
    [self.view addSubview:title];
    [self.view addSubview:status];
    [self.view addSubview:message];
    [self.view addSubview:subscribeButton];

    NSMutableArray *constraints = [NSMutableArray arrayWithArray:@[
        [icon.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [icon.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:120],
        [title.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:16],
        [status.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [status.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [message.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [message.topAnchor constraintEqualToAnchor:status.bottomAnchor constant:10],
        [message.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-48],
        [subscribeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [subscribeButton.topAnchor constraintEqualToAnchor:message.bottomAnchor constant:24]
    ]];

    if (![BHTManager Premium]) {
        self.emailField = [UITextField new];
        self.emailField.placeholder = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_EMAIL_PLACEHOLDER"];
        self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
        self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.emailField.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.emailField];

        UIButton *unlockButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [unlockButton setTitle:[[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_UNLOCK_BUTTON"]
                         forState:UIControlStateNormal];
        [unlockButton setTitleColor:UIColor.labelColor forState:UIControlStateNormal];
        [unlockButton addTarget:self action:@selector(onUnlockTap:) forControlEvents:UIControlEventTouchUpInside];
        unlockButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:unlockButton];

        self.errorLabel = [[UILabel alloc] init];
        self.errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.errorLabel.text = @"";
        self.errorLabel.textColor = UIColor.systemRedColor;
        self.errorLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        self.errorLabel.textAlignment = NSTextAlignmentCenter;
        self.errorLabel.numberOfLines = 0;
        [self.view addSubview:self.errorLabel];

        [constraints addObjectsFromArray:@[
            [self.emailField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.emailField.topAnchor constraintEqualToAnchor:subscribeButton.bottomAnchor constant:16],
            [self.emailField.widthAnchor constraintEqualToConstant:300],
            [unlockButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [unlockButton.topAnchor constraintEqualToAnchor:self.emailField.bottomAnchor constant:16],
            [self.errorLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.errorLabel.topAnchor constraintEqualToAnchor:unlockButton.bottomAnchor constant:12],
            [self.errorLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-48]
        ]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
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
        // Rebuild the page so it shows the unlocked state.
        NSMutableArray *toRemove = [NSMutableArray array];
        for (UIView *v in self.view.subviews) [toRemove addObject:v];
        for (UIView *v in toRemove) [v removeFromSuperview];
        [self buildUI];
    } else {
        self.errorLabel.text = [[BHTBundle sharedBundle] localizedStringForKey:@"EM_PREMIUM_INVALID_EMAIL"];
    }
}

@end