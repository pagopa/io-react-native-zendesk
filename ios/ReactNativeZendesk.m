#import "ReactNativeZendesk.h"
#import <AnswerBotSDK/AnswerBotSDK.h>
#import <MessagingSDK/MessagingSDK.h>
#import <MessagingAPI/MessagingAPI.h>
#import <SDKConfigurations/SDKConfigurations.h>
#import <AnswerBotProvidersSDK/AnswerBotProvidersSDK.h>
#import <ChatSDK/ChatSDK.h>
#import <ChatProvidersSDK/ChatProvidersSDK.h>
#import <CommonUISDK/CommonUISDK.h>
#import <SupportSDK/SupportSDK.h>
#import <SupportProvidersSDK/SupportProvidersSDK.h>
#import <ZendeskCoreSDK/ZendeskCoreSDK.h>

@interface NavigationControllerWithCompletion : UINavigationController
@property (nonatomic, copy, nullable) RCTResponseSenderBlock completion;
@end

static UIUserInterfaceStyle _overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;

@implementation ReactNativeZendesk

- (void)applyUserInterfaceStyleToNavigationController:(UINavigationController *)navController {
    if (_overrideUserInterfaceStyle == UIUserInterfaceStyleUnspecified) {
        return;
    }
    // Force style on the window so the keyboard also respects it
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window) {
        window.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
    }
    navController.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
    navController.navigationBar.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
    navController.view.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
    if (navController.viewControllers.firstObject) {
        navController.viewControllers.firstObject.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
        navController.viewControllers.firstObject.view.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
    }
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        if (_overrideUserInterfaceStyle == UIUserInterfaceStyleLight) {
            appearance.backgroundColor = [UIColor whiteColor];
            appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
            appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
            navController.navigationBar.tintColor = [UIColor blackColor];
            navController.navigationBar.barTintColor = [UIColor whiteColor];
        } else if (_overrideUserInterfaceStyle == UIUserInterfaceStyleDark) {
            appearance.backgroundColor = [UIColor blackColor];
            appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
            appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
            navController.navigationBar.tintColor = [UIColor whiteColor];
            navController.navigationBar.barTintColor = [UIColor blackColor];
        }
        navController.navigationBar.standardAppearance = appearance;
        navController.navigationBar.scrollEdgeAppearance = appearance;
        navController.navigationBar.compactAppearance = appearance;
    }
}

- (void)forceUserInterfaceStyleOnViewHierarchy:(UIView *)view {
    view.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
    // Force background color on views that use hardcoded white/black
    // but skip input-related views to preserve contrast
    BOOL isInputView = [view isKindOfClass:[UITextField class]] ||
                       [view isKindOfClass:[UITextView class]] ||
                       [view isKindOfClass:[UIToolbar class]] ||
                       [view isKindOfClass:[UIInputView class]];
    if (!isInputView) {
        if (_overrideUserInterfaceStyle == UIUserInterfaceStyleDark) {
            if ([self isLightColor:view.backgroundColor]) {
                view.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
            }
        } else if (_overrideUserInterfaceStyle == UIUserInterfaceStyleLight) {
            if ([self isDarkColor:view.backgroundColor]) {
                view.backgroundColor = [UIColor whiteColor];
            }
        }
    }
    // Fix text color on labels
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (_overrideUserInterfaceStyle == UIUserInterfaceStyleDark) {
            if ([self isDarkColor:label.textColor]) {
                label.textColor = [UIColor whiteColor];
            }
        } else if (_overrideUserInterfaceStyle == UIUserInterfaceStyleLight) {
            if ([self isLightColor:label.textColor]) {
                label.textColor = [UIColor blackColor];
            }
        }
    }
    // Fix text color on text views (message input)
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        if (_overrideUserInterfaceStyle == UIUserInterfaceStyleDark) {
            textView.textColor = [UIColor whiteColor];
            textView.keyboardAppearance = UIKeyboardAppearanceDark;
        } else if (_overrideUserInterfaceStyle == UIUserInterfaceStyleLight) {
            textView.textColor = [UIColor blackColor];
            textView.keyboardAppearance = UIKeyboardAppearanceLight;
        }
    }
    // Fix icon tint on image views (attach icon etc.)
    if ([view isKindOfClass:[UIImageView class]]) {
        if (_overrideUserInterfaceStyle == UIUserInterfaceStyleDark) {
            if ([self isDarkColor:view.tintColor]) {
                view.tintColor = [UIColor lightGrayColor];
            }
        } else if (_overrideUserInterfaceStyle == UIUserInterfaceStyleLight) {
            if ([self isLightColor:view.tintColor]) {
                view.tintColor = [UIColor darkGrayColor];
            }
        }
    }
    // Fix send button: when disabled ensure it's visible on dark background
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        if (_overrideUserInterfaceStyle == UIUserInterfaceStyleDark) {
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        }
    }
    // Fix border color on views (input field borders)
    if (view.layer.borderWidth > 0 && view.layer.borderColor != NULL) {
        if (_overrideUserInterfaceStyle == UIUserInterfaceStyleDark) {
            view.layer.borderColor = [UIColor colorWithWhite:0.4 alpha:1.0].CGColor;
        } else if (_overrideUserInterfaceStyle == UIUserInterfaceStyleLight) {
            view.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
        }
    }
    for (UIView *subview in view.subviews) {
        [self forceUserInterfaceStyleOnViewHierarchy:subview];
    }
}

- (BOOL)isLightColor:(UIColor *)color {
    if (!color) return NO;
    CGFloat white = 0;
    if ([color getWhite:&white alpha:nil]) {
        return white > 0.9;
    }
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        CGFloat brightness = (r * 299 + g * 587 + b * 114) / 1000;
        return brightness > 0.9;
    }
    return NO;
}

- (BOOL)isDarkColor:(UIColor *)color {
    if (!color) return NO;
    CGFloat white = 0;
    if ([color getWhite:&white alpha:nil]) {
        return white < 0.3;
    }
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        CGFloat brightness = (r * 299 + g * 587 + b * 114) / 1000;
        return brightness < 0.3;
    }
    return NO;
}

- (void)applyStyleAfterPresentation:(UINavigationController *)navController {
    if (_overrideUserInterfaceStyle == UIUserInterfaceStyleUnspecified) {
        return;
    }
    // Apply multiple times with increasing delays to catch lazily loaded views
    NSArray *delays = @[@0.1, @0.5, @1.0];
    for (NSNumber *delay in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delay doubleValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_overrideUserInterfaceStyle != UIUserInterfaceStyleUnspecified) {
                [self forceUserInterfaceStyleOnViewHierarchy:navController.view];
                for (UIViewController *vc in navController.viewControllers) {
                    vc.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
                    [self forceUserInterfaceStyleOnViewHierarchy:vc.view];
                    for (UIViewController *child in vc.childViewControllers) {
                        child.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
                        [self forceUserInterfaceStyleOnViewHierarchy:child.view];
                    }
                }
                if (navController.presentedViewController) {
                    navController.presentedViewController.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
                    [self forceUserInterfaceStyleOnViewHierarchy:navController.presentedViewController.view];
                }
            }
        });
    }
}
RCT_EXPORT_MODULE()
RCT_EXPORT_METHOD(chatConfiguration: (NSDictionary *)options) {
    ZDKChatConfiguration *chatConfiguration = [[ZDKChatConfiguration alloc] init];
    if (options[@"chatMenuActions"]) {
        chatConfiguration.chatMenuActions = options[@"chatMenuActions"];
    }
    if (options[@"isChatTranscriptPromptEnabled"]) {
        chatConfiguration.isChatTranscriptPromptEnabled = options[@"isChatTranscriptPromptEnabled"];
    }
    if (options[@"isPreChatFormEnabled"]) {
        chatConfiguration.isPreChatFormEnabled = options[@"isPreChatFormEnabled"];
    }
    if (options[@"isOfflineFormEnabled"]) {
        chatConfiguration.isOfflineFormEnabled = options[@"isOfflineFormEnabled"];
    }
    if (options[@"isAgentAvailabilityEnabled"]) {
        chatConfiguration.isAgentAvailabilityEnabled = options[@"isAgentAvailabilityEnabled"];
    }
}

- (void)executeOnMainThread:(void (^)(void))block
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

RCT_EXPORT_METHOD(openTicket:(RCTResponseSenderBlock)onClose) {
    [self executeOnMainThread:^{
        [self openTicketFunction:onClose];
    }];
}
RCT_EXPORT_METHOD(showTickets:(RCTResponseSenderBlock)onClose) {
    [self executeOnMainThread:^{
        [self showTicketsFunction:onClose];
    }];
}
NSMutableString* mutableLog;
NSString* logId;
NSMutableDictionary* customFields;
NSMutableArray* tags;
UIViewController *currentController;
#ifndef MAX_LOG_LENGTH
#define MAX_LOG_LENGTH 60000
#endif
#ifndef MAX_TAGS_LENGTH
#define MAX_TAGS_LENGTH 100
#endif

RCT_EXPORT_METHOD(resetCustomFields) {
    [self initGlobals];
    [customFields removeAllObjects];
}
RCT_EXPORT_METHOD(resetTags) {
    [self initGlobals];
    [tags removeAllObjects];
}
RCT_EXPORT_METHOD(resetLog) {
    [self initGlobals];
    [mutableLog setString:@""];
}

// dismiss the current controller shown, if any
RCT_EXPORT_METHOD(dismiss) {
    [self executeOnMainThread:^{
        if(currentController != nil){
            [currentController dismissViewControllerAnimated:TRUE completion:nil];
        }
        currentController = nil;
        // Restore window to follow system appearance
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
        }
    }];
}

- (void) initGlobals
{
    if(mutableLog == nil){
        mutableLog = [[NSMutableString alloc] init];
    }
    if(customFields == nil){
        customFields = [[NSMutableDictionary alloc] init];
    }
    if(tags == nil){
        tags = [NSMutableArray array];
    }
}
RCT_EXPORT_METHOD(appendLog:(NSString *)log) {
    [self initGlobals];
    [mutableLog insertString:log atIndex:0];
    [mutableLog substringToIndex:fmax(0,fmin(MAX_LOG_LENGTH,mutableLog.length - 1))];
}
- (void) addTicketCustomFieldFunction:(NSString *)key withValue:(NSString *)value
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *customFieldID = [f numberFromString:key];
    ZDKCustomField *customField = [[ZDKCustomField alloc] initWithFieldId:customFieldID value:value];
    [customFields setObject:customField forKey:customFieldID];
}
RCT_EXPORT_METHOD(addTicketCustomField:(NSString *)key withValue:(NSString *)value) {
    [self initGlobals];
    [self addTicketCustomFieldFunction:key withValue:value];
}

- (void) addTicketTagFunction:(NSString *)tag
{
    NSString * snakeTag = [tag stringByReplacingOccurrencesOfString:@" "
                                         withString:@"_"];
    // avoid duplicates
    if([tags containsObject:snakeTag]){
        return;
    }
    [tags addObject:snakeTag];
    int elementsToRemove = (int)tags.count - MAX_TAGS_LENGTH;
    int i = 0;
    while(i < elementsToRemove){
        [tags removeObjectAtIndex:0];
        i++;
    }

}
RCT_EXPORT_METHOD(addTicketTag:(NSString *)tag) {
    [self initGlobals];
    [self addTicketTagFunction:tag];
}
RCT_EXPORT_METHOD(setUserIdentity: (NSDictionary *)user) {
  if (user[@"token"]) {
    id<ZDKObjCIdentity> userIdentity = [[ZDKObjCJwt alloc] initWithToken:user[@"token"]];
    [[ZDKClassicZendesk instance] setIdentity:userIdentity];
  } else {
    id<ZDKObjCIdentity> userIdentity = [[ZDKObjCAnonymous alloc] initWithName:user[@"name"] // name is nullable
                                          email:user[@"email"]]; // email is nullable
    [[ZDKClassicZendesk instance] setIdentity:userIdentity];
  }
}
RCT_EXPORT_METHOD(init:(NSDictionary *)options) {
  [ZDKClassicZendesk initializeWithAppId:options[@"appId"]
      clientId: options[@"clientId"]
      zendeskUrl: options[@"url"]];
  [ZDKSupport initializeWithZendesk: [ZDKClassicZendesk instance]];
  [ZDKChat initializeWithAccountKey:options[@"key"] appId:options[@"appId"] queue:dispatch_get_main_queue()];
  [ZDKAnswerBot initializeWithZendesk:[ZDKClassicZendesk instance] support:[ZDKSupport instance]];
  logId = options[@"logId"];

}
RCT_EXPORT_METHOD(initChat:(NSString *)key) {
  [ZDKChat initializeWithAccountKey:key queue:dispatch_get_main_queue()];
}
RCT_EXPORT_METHOD(setPrimaryColor:(NSString *)color) {
  [ZDKCommonTheme currentTheme].primaryColor = [self colorFromHexString:color];
}
RCT_EXPORT_METHOD(setUserInterfaceStyle:(NSString *)style) {
  if ([style isEqualToString:@"light"]) {
    _overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
  } else if ([style isEqualToString:@"dark"]) {
    _overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
  } else {
    _overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
  }
  // Apply immediately to the window
  dispatch_async(dispatch_get_main_queue(), ^{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window) {
        window.overrideUserInterfaceStyle = _overrideUserInterfaceStyle;
    }
  });
  // Force global UINavigationBar appearance
  if (@available(iOS 13.0, *)) {
    UINavigationBarAppearance *globalAppearance = [[UINavigationBarAppearance alloc] init];
    [globalAppearance configureWithOpaqueBackground];
    if (_overrideUserInterfaceStyle == UIUserInterfaceStyleLight) {
        globalAppearance.backgroundColor = [UIColor whiteColor];
        globalAppearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
        [UINavigationBar appearance].tintColor = [UIColor blackColor];
        [UINavigationBar appearance].barTintColor = [UIColor whiteColor];
    } else if (_overrideUserInterfaceStyle == UIUserInterfaceStyleDark) {
        globalAppearance.backgroundColor = [UIColor blackColor];
        globalAppearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        [UINavigationBar appearance].tintColor = [UIColor whiteColor];
        [UINavigationBar appearance].barTintColor = [UIColor blackColor];
    }
    [UINavigationBar appearance].standardAppearance = globalAppearance;
    [UINavigationBar appearance].scrollEdgeAppearance = globalAppearance;
  }
}
RCT_EXPORT_METHOD(setNotificationToken:(NSData *)deviceToken) {
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self registerForNotifications:deviceToken];
  });
}

RCT_EXPORT_METHOD(hasOpenedTickets:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    ZDKRequestProvider *provider = [ZDKRequestProvider new];
    [provider getAllRequestsWithCallback:^(ZDKRequestsWithCommentingAgents *requestsWithCommentingAgents, NSError *error) {
        if(error != nil){
            reject(@"event_failure", @"no response", nil);
            return;
        }
        NSNumber *ticketsCount = [NSNumber numberWithInt:[requestsWithCommentingAgents requests].count];
        resolve(ticketsCount);
    }];
}
RCT_EXPORT_METHOD(getTotalNewResponses:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    ZDKRequestProvider * provider = [ZDKRequestProvider new];
        [provider getUpdatesForDeviceWithCallback:^(ZDKRequestUpdates * _Nullable requestUpdates) {
            NSNumber *totalUpdates = [NSNumber numberWithInt:requestUpdates.totalUpdates];
            resolve(totalUpdates);
        }];
}
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}
- (void) showHelpCenterFunction:(NSDictionary *)options {
    NSError *error = nil;
    NSArray *engines = @[];
    NSString *botName = @"ChatBot";
    if (options[@"botName"]) {
      botName = options[@"botName"];
    }
    if (options[@"withChat"]) {
      engines = @[(id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error]];
    }
    ZDKHelpCenterUiConfiguration* helpCenterUiConfig = [ZDKHelpCenterUiConfiguration new];
    helpCenterUiConfig.objcEngines = engines;
    ZDKArticleUiConfiguration* articleUiConfig = [ZDKArticleUiConfiguration new];
    articleUiConfig.objcEngines = engines;
     if (options[@"disableTicketCreation"]) {
         helpCenterUiConfig.showContactOptions = NO;
         articleUiConfig.showContactOptions = NO;
    }
    UIViewController* controller = [ZDKHelpCenterUi buildHelpCenterOverviewUiWithConfigs: @[helpCenterUiConfig, articleUiConfig]];
    // controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Close"
    //                                                                                    style: UIBarButtonItemStylePlain
    //                                                                                   target: self
    //                                                                                   action: @selector(chatClosedClicked)];
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    currentController = topController;
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: controller];
    [self applyUserInterfaceStyleToNavigationController:navControl];
    [topController presentViewController:navControl animated:YES completion:^{
        [self applyStyleAfterPresentation:navControl];
    }];
}
- (void) openTicketFunction:(RCTResponseSenderBlock)onClose {
    [self initGlobals];
    if(logId != nil){
        [self addTicketCustomFieldFunction:logId  withValue:mutableLog];
    }

    ZDKRequestUiConfiguration * config = [ZDKRequestUiConfiguration new];
    config.customFields = customFields.allValues;
    config.tags = tags;

    UIViewController *openTicketController = [ZDKRequestUi buildRequestUiWith:@[config]];
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    currentController = topController;
    NavigationControllerWithCompletion *navControl = [[NavigationControllerWithCompletion alloc] initWithRootViewController: openTicketController];
    navControl.completion = onClose;
    [self applyUserInterfaceStyleToNavigationController:navControl];
    [topController presentViewController:navControl animated:YES completion:^{
        [self applyStyleAfterPresentation:navControl];
    }];
  }
- (void) showTicketsFunction:(RCTResponseSenderBlock)onClose {
    ZDKRequestListUiConfiguration * config = [ZDKRequestListUiConfiguration new];
    config.allowRequestCreation = false;
    UIViewController *showTicketsController = [ZDKRequestUi buildRequestListWith:@[config]];
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    currentController = topController;
    NavigationControllerWithCompletion *navControl = [[NavigationControllerWithCompletion alloc] initWithRootViewController: showTicketsController];
    navControl.completion = onClose;
    [self applyUserInterfaceStyleToNavigationController:navControl];
    [topController presentViewController:navControl animated:YES completion:^{
        [self applyStyleAfterPresentation:navControl];
    }];
  }
- (void) chatClosedClicked {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    [topController dismissViewControllerAnimated:TRUE completion:NULL];
}
- (void) registerForNotifications:(NSData *)deviceToken {
   [ZDKChat registerPushToken:deviceToken];
}
@end

@implementation NavigationControllerWithCompletion

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // Restore window to follow system appearance
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window) {
        window.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    }
    if (self.completion) {
        self.completion(@[[NSNull null]]);
        self.completion = nil;
    }
}

@end
