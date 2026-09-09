//
//  EMFrostedNavBar.m
//  EMTwitter
//
//  Floating frosted-glass navigation pill that replaces the stock tab bar.
//  - The pill floats above content at the bottom of the screen with a blur
//    (frosted glass) effect and rounded corners.
//  - It shows the tabs enabled in the Custom Tab Bar settings
//    (BHCustomTabBarUtility), falling back to Home / Search / Notifications /
//    Messages.
//  - Tapping a button switches the app's tab through the stock
//    UITabBarController selection API.
//

#import "EMFrostedNavBar.h"
#import "../CustomTabBar/BHCustomTabBarUtility.h"
#import "../BHTBundle/BHTBundle.h"
#import "../TWHeaders.h"
#import <CoreText/CoreText.h>

@interface UIImage (EMFrostedNavBarAdditions)
+ (id)tfn_vectorImageNamed:(id)arg1 fitsSize:(struct CGSize)arg2 fillColor:(id)arg3;
@end

#pragma mark - Material icon rendering

// Material icon glyph name for each tab page.
static NSString *EMMaterialIconNameForPageID(NSString *pageID) {
    if ([pageID isEqualToString:@"home"]) return @"home";
    if ([pageID isEqualToString:@"guide"]) return @"search";
    if ([pageID isEqualToString:@"ntab"]) return @"notifications";
    if ([pageID isEqualToString:@"messages"]) return @"message";
    if ([pageID isEqualToString:@"profile"]) return @"person";
    if ([pageID isEqualToString:@"audiospace"]) return @"mic";
    if ([pageID isEqualToString:@"communities"]) return @"groups";
    if ([pageID isEqualToString:@"grok"]) return @"auto_awesome";
    if ([pageID isEqualToString:@"media"]) return @"photo_library";
    return @"home";
}

// Private-use codepoints, identical for the filled and outlined fonts.
static unichar EMMaterialGlyph(NSString *glyphName) {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"home":            @0xE88A,
            @"search":          @0xE8B6,
            @"notifications":   @0xE7F4,
            @"message":         @0xE0C9,
            @"person":          @0xE7FD,
            @"mic":             @0xE029,
            @"groups":          @0xF233,
            @"auto_awesome":    @0xE65F,
            @"photo_library":   @0xE413,
        };
    });
    NSNumber *code = map[glyphName];
    return code ? (unichar)code.unsignedIntValue : 0;
}

// Loads the Material icon fonts from the tweak bundle (filled .ttf + outlined
// .otf) and returns the matching UIFont.
static UIFont *EMMaterialFont(BOOL filled, CGFloat size) {
    static UIFont *regularFont = nil;
    static UIFont *outlinedFont = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [[BHTBundle sharedBundle] mainBundle];
        NSArray *entries = @[
            @{ @"file": @"MaterialIcons-Regular", @"ext": @"ttf", @"outlined": @NO },
            @{ @"file": @"MaterialIconsOutlined-Regular", @"ext": @"otf", @"outlined": @YES },
        ];
        for (NSDictionary *entry in entries) {
            NSString *path = [bundle pathForResource:entry[@"file"] ofType:entry[@"ext"]];
            if (!path) continue;
            NSData *data = [NSData dataWithContentsOfFile:path];
            if (!data) continue;
            CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
            CGFontRef cgFont = provider ? CGFontCreateWithDataProvider(provider) : NULL;
            if (provider) CGDataProviderRelease(provider);
            if (!cgFont) continue;

            CFErrorRef error = NULL;
            if (!CTFontManagerRegisterGraphicsFont(cgFont, &error)) {
                if (error) CFRelease(error);
            }
            CFStringRef psName = CGFontCopyPostScriptName(cgFont);
            if (psName) {
                UIFont *font = [UIFont fontWithName:(__bridge NSString *)psName size:16];
                if (font) {
                    if ([entry[@"outlined"] boolValue]) outlinedFont = font;
                    else regularFont = font;
                }
                CFRelease(psName);
            }
            CFRelease(cgFont);
        }
    });
    UIFont *base = filled ? (regularFont ?: outlinedFont) : (outlinedFont ?: regularFont);
    return base ? [base fontWithSize:size] : nil;
}

// Renders a Material glyph as a template image (black); tint with accent color.
static UIImage *EMMaterialImage(NSString *glyphName, CGFloat size, BOOL filled) {
    unichar ch = EMMaterialGlyph(glyphName);
    if (!ch) return nil;
    UIFont *font = EMMaterialFont(filled, size * 0.9);
    if (!font) return nil;

    NSString *glyph = [NSString stringWithCharacters:&ch length:1];
    __block UIImage *image = nil;
    if (@available(iOS 10.0, *)) {
        UIGraphicsImageRenderer *renderer =
            [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size)];
        image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
            NSDictionary *attrs = @{
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: [UIColor blackColor],
            };
            CGSize textSize = [glyph sizeWithAttributes:attrs];
            CGRect rect = CGRectMake((size - textSize.width) / 2.0,
                                     (size - textSize.height) / 2.0,
                                     textSize.width, textSize.height);
            [glyph drawInRect:rect withAttributes:attrs];
        }];
    }
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@implementation EMFrostedNavBar

static EMFrostedNavBar *sShared = nil;
static NSMutableArray *sPageIDs = nil;   // visible page IDs in order
static NSMutableArray *sButtons = nil;   // UIControl per page
static NSMutableArray *sIcons = nil;     // UIImageView per page
static const NSInteger kEMFrostedNavBarTag = 910; // 909 = padlock, 9001 = copy button

#pragma mark - Public class API

+ (EMFrostedNavBar *)shared {
    if (!sShared) sShared = [[self alloc] init];
    return sShared;
}

+ (void)installIfNeeded {
    [[self shared] installIfNeededImpl];
}

+ (void)refreshTint {
    [[self shared] refreshHighlightImpl];
}

+ (void)removeAll {
    [[self shared] removeAllImpl];
}

+ (void)selectTabWithPageID:(NSString *)pageID {
    [[self shared] selectTabWithPageIDImpl:pageID];
}

#pragma mark - Window helpers

- (UIWindow *)keyWindow {
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) return w;
    }
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (!w.hidden) return w;
    }
    return nil;
}

- (UIView *)findPill:(UIWindow *)window {
    if (!window) return nil;
    for (UIView *v in window.subviews) {
        if (v.tag == kEMFrostedNavBarTag) return v;
    }
    return nil;
}

#pragma mark - Tab list

- (NSArray *)visiblePageIDs {
    NSArray *allowed = [BHCustomTabBarUtility getAllowedTabBars];
    if (allowed && allowed.count > 0) return allowed;
    return @[@"home", @"guide", @"ntab", @"messages"];
}

- (NSString *)iconNameForPageID:(NSString *)pageID selected:(BOOL)selected {
    if ([pageID isEqualToString:@"home"]) return selected ? @"home" : @"home_stroke";
    if ([pageID isEqualToString:@"guide"]) return selected ? @"search" : @"search_stroke";
    if ([pageID isEqualToString:@"ntab"]) return selected ? @"notifications" : @"notifications_stroke";
    if ([pageID isEqualToString:@"messages"]) return selected ? @"messages" : @"messages_stroke";
    if ([pageID isEqualToString:@"profile"]) return selected ? @"person" : @"person_stroke";
    if ([pageID isEqualToString:@"audiospace"]) return selected ? @"spaces" : @"spaces_stroke";
    if ([pageID isEqualToString:@"communities"]) return selected ? @"communities" : @"communities_stroke";
    if ([pageID isEqualToString:@"grok"]) return selected ? @"grok_icon_blackhole" : @"grok_icon_blackhole_stroke";
    if ([pageID isEqualToString:@"media"]) return selected ? @"media_tab" : @"media_tab_stroke";
    return selected ? @"home" : @"home_stroke";
}

- (UIImageView *)iconForPageID:(NSString *)pageID selected:(BOOL)selected {
    // Material 3-style icon (outlined when unselected, filled when selected).
    UIImage *img = EMMaterialImage(EMMaterialIconNameForPageID(pageID), 26, selected);
    if (!img) {
        // Fallback: Twitter's own vector icons if the Material fonts are missing.
        img = [UIImage tfn_vectorImageNamed:[self iconNameForPageID:pageID selected:selected]
                                    fitsSize:CGSizeMake(26, 26)
                                   fillColor:[UIColor secondaryLabelColor]];
    }
    UIImageView *iv = [[UIImageView alloc] initWithImage:img];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    return iv;
}

#pragma mark - Install / remove

- (void)installIfNeededImpl {
    UIWindow *window = [self keyWindow];
    if (!window) return;
    UIViewController *root = window.rootViewController;
    if (!root || ![root isKindOfClass:NSClassFromString(@"T1TabBarViewController")]) {
        // No tab bar on screen (e.g., signed out): make sure no stale pill
        // lingers over the login screen.
        UIView *existing = [self findPill:window];
        if (existing) {
            [existing removeFromSuperview];
            sPageIDs = nil;
            sButtons = nil;
            sIcons = nil;
        }
        return;
    }

    if ([self findPill:window]) return;

    [self hideStockTabBarImpl];
    [self buildPill:window];
}

- (void)removeAllImpl {
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        UIView *pill = [self findPill:w];
        if (pill) [pill removeFromSuperview];
    }
    sPageIDs = nil;
    sButtons = nil;
    sIcons = nil;
}

- (void)hideStockTabBarImpl {
    UIWindow *window = [self keyWindow];
    if (!window) return;
    UIViewController *root = window.rootViewController;
    if (!root || ![root isKindOfClass:NSClassFromString(@"T1TabBarViewController")]) return;

    T1TabBarViewController *tabBar = (T1TabBarViewController *)root;
    NSArray *tabs = tabBar.tabViews;
    if (!tabs) return;

    NSMutableArray *contentViews = [NSMutableArray array];
    for (UIViewController *vc in ((UITabBarController *)tabBar).viewControllers) {
        if (vc.view) [contentViews addObject:vc.view];
    }

    UIView *barContainer = nil;
    for (T1TabView *tab in tabs) {
        if ([tab respondsToSelector:@selector(setHidden:)]) [tab setHidden:YES];
        UIView *parent = tab.superview;
        if (!parent || parent == root.view) continue;
        if ([contentViews containsObject:parent]) continue;
        barContainer = parent;
    }
    if (barContainer) barContainer.hidden = YES;
}

- (void)buildPill:(UIWindow *)window {
    NSArray *pageIDs = [self visiblePageIDs];
    if (pageIDs.count == 0) return;

    NSMutableArray *constraints = [NSMutableArray array];

    // Rounded clipping container so the blur gets rounded corners too.
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.layer.cornerRadius = 28;
    container.clipsToBounds = YES;
    container.userInteractionEnabled = YES;
    container.tag = kEMFrostedNavBarTag;
    [window addSubview:container];

    // Frosted glass layer: blur effect + translucent tint.
    UIBlurEffectStyle style = (window.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
    UIVisualEffectView *fx =
        [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:style]];
    fx.translatesAutoresizingMaskIntoConstraints = NO;
    fx.userInteractionEnabled = YES;
    [container addSubview:fx];

    UIView *tint = [[UIView alloc] init];
    tint.translatesAutoresizingMaskIntoConstraints = NO;
    if (window.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        tint.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.07 alpha:0.55];
    } else {
        tint.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6];
    }
    [fx.contentView addSubview:tint];

    [constraints addObjectsFromArray:@[
        [fx.topAnchor constraintEqualToAnchor:container.topAnchor],
        [fx.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [fx.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [fx.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [tint.topAnchor constraintEqualToAnchor:fx.contentView.topAnchor],
        [tint.leadingAnchor constraintEqualToAnchor:fx.contentView.leadingAnchor],
        [tint.trailingAnchor constraintEqualToAnchor:fx.contentView.trailingAnchor],
        [tint.bottomAnchor constraintEqualToAnchor:fx.contentView.bottomAnchor]
    ]];

    sPageIDs = [NSMutableArray array];
    sButtons = [NSMutableArray array];
    sIcons = [NSMutableArray array];

    CGFloat buttonSize = 44.0;
    CGFloat spacing = 8.0;
    CGFloat inset = 14.0;
    CGFloat pillWidth = inset * 2 + buttonSize * pageIDs.count + spacing * (pageIDs.count - 1);

    UIControl *prev = nil;
    for (NSInteger i = 0; i < pageIDs.count; i++) {
        NSString *pageID = pageIDs[i];
        [sPageIDs addObject:pageID];

        UIControl *ctrl = [[UIControl alloc] init];
        ctrl.translatesAutoresizingMaskIntoConstraints = NO;
        [ctrl addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [fx.contentView addSubview:ctrl];
        [sButtons addObject:ctrl];

        UIImageView *iv = [self iconForPageID:pageID selected:NO];
        [ctrl addSubview:iv];
        [sIcons addObject:iv];

        [constraints addObject:[ctrl.widthAnchor constraintEqualToConstant:buttonSize]];
        [constraints addObject:[ctrl.heightAnchor constraintEqualToConstant:buttonSize]];
        [constraints addObject:[ctrl.centerYAnchor constraintEqualToAnchor:fx.contentView.centerYAnchor]];
        if (prev) {
            [constraints addObject:[ctrl.leadingAnchor constraintEqualToAnchor:prev.trailingAnchor
                                                                   constant:spacing]];
        } else {
            [constraints addObject:[ctrl.leadingAnchor constraintEqualToAnchor:fx.contentView.leadingAnchor
                                                                   constant:inset]];
        }
        [constraints addObject:[iv.centerXAnchor constraintEqualToAnchor:ctrl.centerXAnchor]];
        [constraints addObject:[iv.centerYAnchor constraintEqualToAnchor:ctrl.centerYAnchor]];
        [constraints addObject:[iv.widthAnchor constraintEqualToConstant:26]];
        [constraints addObject:[iv.heightAnchor constraintEqualToConstant:26]];

        prev = ctrl;
    }

    [constraints addObjectsFromArray:@[
        [container.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
        [container.bottomAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.bottomAnchor
                                                      constant:-14],
        [container.widthAnchor constraintEqualToConstant:pillWidth],
        [container.heightAnchor constraintEqualToConstant:56]
    ]];

    [NSLayoutConstraint activateConstraints:constraints];

    [self refreshHighlightImpl];
}

#pragma mark - Interaction

- (void)tabTapped:(UIControl *)sender {
    NSInteger idx = [sButtons indexOfObject:sender];
    if (idx == NSNotFound || idx >= sPageIDs.count) return;
    NSString *pageID = sPageIDs[idx];
    [self selectTabWithPageIDImpl:pageID];
}

- (void)selectTabWithPageIDImpl:(NSString *)pageID {
    UIWindow *window = [self keyWindow];
    if (!window) return;
    UIViewController *root = window.rootViewController;
    if (!root || ![root isKindOfClass:NSClassFromString(@"T1TabBarViewController")]) return;

    T1TabBarViewController *tabBar = (T1TabBarViewController *)root;
    NSArray *tabs = tabBar.tabViews;
    if (!tabs) return;

    NSInteger idx = NSNotFound;
    for (NSInteger i = 0; i < tabs.count; i++) {
        T1TabView *tab = tabs[i];
        if (tab.scribePage && [tab.scribePage isEqualToString:pageID]) {
            idx = i;
            break;
        }
    }
    if (idx == NSNotFound) return;

    NSArray *vcs = ((UITabBarController *)tabBar).viewControllers;
    if (vcs && idx < vcs.count) {
        UIViewController *target = vcs[idx];
        if ([tabBar respondsToSelector:@selector(setSelectedViewController:)]) {
            [tabBar performSelector:@selector(setSelectedViewController:) withObject:target];
        } else if (idx < tabs.count) {
            T1TabView *tab = tabs[idx];
            if ([tab respondsToSelector:@selector(setSelected:)]) [(id)tab setSelected:YES];
        }
    } else if (idx < tabs.count) {
        T1TabView *tab = tabs[idx];
        if ([tab respondsToSelector:@selector(setSelected:)]) [(id)tab setSelected:YES];
    }

    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"T1TabBarAppearanceDidChangeNotification" object:nil];

    [self refreshHighlightImpl];
}

- (void)refreshHighlightImpl {
    if (!sButtons || !sPageIDs || !sIcons) return;

    UIWindow *window = [self keyWindow];
    if (!window) return;
    UIViewController *root = window.rootViewController;
    if (!root || ![root isKindOfClass:NSClassFromString(@"T1TabBarViewController")]) return;

    UITabBarController *tabBar = (UITabBarController *)root;
    UIViewController *sel = tabBar.selectedViewController;
    NSInteger selIdx = NSNotFound;
    if (sel) {
        NSArray *vcs = tabBar.viewControllers;
        if (vcs) selIdx = [vcs indexOfObject:sel];
    }

    for (NSInteger i = 0; i < sButtons.count; i++) {
        NSString *pageID = sPageIDs[i];
        BOOL selected = (i == selIdx);
        UIImageView *iv = sIcons[i];
        UIColor *color = selected ? BHTCurrentAccentColor() : [UIColor secondaryLabelColor];

        // Material 3-style icon: filled + accent when selected, outlined +
        // secondary when not. Template images, so the tint does the coloring.
        UIImage *img = EMMaterialImage(EMMaterialIconNameForPageID(pageID), 26, selected);
        if (!img) {
            img = [UIImage tfn_vectorImageNamed:[self iconNameForPageID:pageID selected:selected]
                                        fitsSize:CGSizeMake(26, 26)
                                       fillColor:color];
        }
        iv.image = img;
        iv.tintColor = color;
    }
}

@end