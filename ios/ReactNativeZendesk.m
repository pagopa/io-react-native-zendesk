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

@implementation ReactNativeZendesk
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
    [topController presentViewController:navControl animated:YES completion:nil];
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
    
    [topController presentViewController:navControl animated:YES completion:nil];
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

    [topController presentViewController:navControl animated:YES completion:nil];
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
    if (self.completion) {
        self.completion(@[[NSNull null]]);
        self.completion = nil;
    }
}

@end
