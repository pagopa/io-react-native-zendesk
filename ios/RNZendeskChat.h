#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <React/RCTBridgeModule.h>

@interface RNZendeskChat : NSObject<RCTBridgeModule>
@end


@interface NavigationControllerWithCompletion : UINavigationController
@property (nonatomic, copy) RCTResponseSenderBlock completion;
@end


