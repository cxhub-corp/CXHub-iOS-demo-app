//
//  NotificationService.m
//  notify-demo-service-extension-objc
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

#import "NotificationService.h"

@import CXHubCore;
@import CXHubNotify;

static BOOL ApiIsInitialized = true;

@implementation NotificationService

+(void)initialize {
    //Initialize CXHubSDK
    //CXAppConfig *appConfig = [CXAppConfig defaultConfig];
    //ApiIsInitialized = [CXApp initExtensionWithConfig:appConfig withEventsReceiver:nil];
    
    NSString *configFile = [[NSBundle mainBundle] pathForResource:@"Notify" ofType:@"plist"];
    CXAppConfig *config = [[CXAppConfig alloc] initWithConfig:configFile];
    ApiIsInitialized = [CXApp initExtensionWithConfig:config withEventsReceiver:nil];
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
                   withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler  API_AVAILABLE(ios(10.0)){
    
    if (!ApiIsInitialized) {
        //CXHubSDK wasn't initialized or some error occured
        contentHandler(request.content);
        return;
    }
    
    //If next is true, then it's CXHub notification, so library will proceed further processing
    BOOL isCXHubNotification = [CXApp didReceiveExtensionNotificationRequest:request withContentHandler:contentHandler];
    
    if(!isCXHubNotification) {
        //Some other application notification, so application could do whatever necessary
        contentHandler(request.content);
    }
}

- (void)serviceExtensionTimeWillExpire {
    //Check TTL of notification
    BOOL isTimeExpire = [CXApp serviceExtensionTimeWillExpire];
    if (isTimeExpire) {
        //In case CXHubSDK extension api logic was started CXHubSDK will take care of content handlers,
        //otherwise application could do whatever necessary
    } else {
        //Some other custom application logic to call content handler
    }
}

@end
