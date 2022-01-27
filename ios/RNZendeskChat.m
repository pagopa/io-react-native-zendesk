#import "RNZendeskChat.h"
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
@implementation RNZendeskChat
RCT_EXPORT_MODULE()
RCT_EXPORT_METHOD(setVisitorInfo:(NSDictionary *)options) {
  ZDKChatAPIConfiguration *config = [[ZDKChatAPIConfiguration alloc] init];
  if (options[@"department"]) {
    config.department = options[@"department"];
  }
  if (options[@"tags"]) {
    config.tags = options[@"tags"];
  }
  config.visitorInfo = [[ZDKVisitorInfo alloc] initWithName:options[@"name"]
                                                email:options[@"email"]
                                                phoneNumber:options[@"phone"]];
  ZDKChat.instance.configuration = config;
  NSLog(@"Setting visitor info: department: %@ tags: %@, email: %@, name: %@, phone: %@", config.department, config.tags, config.visitorInfo.email, config.visitorInfo.name, config.visitorInfo.phoneNumber);
}
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
RCT_EXPORT_METHOD(startChat:(NSDictionary *)options) {
  [self setVisitorInfo:options];
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self startChatFunction:options];
  });
}
RCT_EXPORT_METHOD(openTicket) {
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self openTicketFunction];
  });
}
RCT_EXPORT_METHOD(showTickets) {
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self showTicketsFunction];
  });
}
RCT_EXPORT_METHOD(showHelpCenter:(NSDictionary *)options) {
  [self setVisitorInfo:options];
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self showHelpCenterFunction:options];
  });
}
NSMutableString* mutableLog;
NSString* logId;
NSMutableDictionary* customFields;
NSMutableArray* tags;
#ifndef MAX_LOG_LENGTH
#define MAX_LOG_LENGTH 60000
#endif
#ifndef MAX_TAGS_LENGTH
#define MAX_TAGS_LENGTH 100
#endif

RCT_EXPORT_METHOD(reset) {
    [self initGlobals];
    [mutableLog setString:@""];
    [customFields removeAllObjects];
    [tags removeAllObjects];
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
    NSLog(@"%@",[tags componentsJoinedByString:@","]);
    
}
RCT_EXPORT_METHOD(addTicketTag:(NSString *)tag) {
    [self initGlobals];
    [self addTicketTagFunction:tag];
}
RCT_EXPORT_METHOD(setUserIdentity: (NSDictionary *)user) {
  if (user[@"token"]) {
    id<ZDKObjCIdentity> userIdentity = [[ZDKObjCJwt alloc] initWithToken:user[@"token"]];
    [[ZDKZendesk instance] setIdentity:userIdentity];
  } else {
    id<ZDKObjCIdentity> userIdentity = [[ZDKObjCAnonymous alloc] initWithName:user[@"name"] // name is nullable
                                          email:user[@"email"]]; // email is nullable
    [[ZDKZendesk instance] setIdentity:userIdentity];
  }
}
RCT_EXPORT_METHOD(init:(NSDictionary *)options) {
  [ZDKZendesk initializeWithAppId:options[@"appId"]
      clientId: options[@"clientId"]
      zendeskUrl: options[@"url"]];
  [ZDKSupport initializeWithZendesk: [ZDKZendesk instance]];
  [ZDKChat initializeWithAccountKey:options[@"key"] appId:options[@"appId"] queue:dispatch_get_main_queue()];
  [ZDKAnswerBot initializeWithZendesk:[ZDKZendesk instance] support:[ZDKSupport instance]];
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
        resolve(@[ticketsCount]);
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
    ZDKChatEngine *chatEngine = [ZDKChatEngine engineAndReturnError:&error];
    ZDKSupportEngine *supportEngine = [ZDKSupportEngine engineAndReturnError:&error];
    NSArray *engines = @[];
    ZDKMessagingConfiguration *messagingConfiguration = [ZDKMessagingConfiguration new];
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
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: controller];
    [topController presentViewController:navControl animated:YES completion:nil];
}
- (void) openTicketFunction {
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
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: openTicketController];
    [topController presentViewController:navControl animated:YES completion:nil];
  }
- (void) showTicketsFunction {
    ZDKRequestListUiConfiguration * config = [ZDKRequestListUiConfiguration new];
    config.allowRequestCreation = false;
    UIViewController *showTicketsController = [ZDKRequestUi buildRequestListWith:@[config]];
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: showTicketsController];
    [topController presentViewController:navControl animated:YES completion:nil];
  }
- (void) startChatFunction:(NSDictionary *)options {
    ZDKMessagingConfiguration *messagingConfiguration = [[ZDKMessagingConfiguration alloc] init];
    NSString *botName = @"ChatBot";
    if (options[@"botName"]) {
      botName = options[@"botName"];
    }
    messagingConfiguration.name = botName;
    if (options[@"botImage"]) {
      messagingConfiguration.botAvatar = options[@"botImage"];
    }
    NSError *error = nil;
    NSMutableArray *engines = [[NSMutableArray alloc] init];
    if (options[@"chatOnly"]) {
      engines = @[
        (id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error]
    ];
    } else {
      engines = @[
        (id <ZDKEngine>) [ZDKAnswerBotEngine engineAndReturnError:&error],
        (id <ZDKEngine>) [ZDKChatEngine engineAndReturnError:&error],
        (id <ZDKEngine>) [ZDKSupportEngine engineAndReturnError:&error],
      ];
    }
    ZDKChatConfiguration *chatConfiguration = [[ZDKChatConfiguration alloc] init];
    chatConfiguration.isPreChatFormEnabled = YES;
    chatConfiguration.isAgentAvailabilityEnabled = YES;
    UIViewController *chatController =[ZDKMessaging.instance buildUIWithEngines:engines
                                                                        configs:@[messagingConfiguration, chatConfiguration]
                                                                            error:&error];
    if (error) {
      NSLog(@"Error occured %@", error);
    }
    chatController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Close"
                                                                                       style: UIBarButtonItemStylePlain
                                                                                      target: self
                                                                                      action: @selector(chatClosedClicked)];
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }
        UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController: chatController];
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
