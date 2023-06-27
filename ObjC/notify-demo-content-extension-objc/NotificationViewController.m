//
//  NotificationViewController.m
//  notify-demo-content-extension-objc
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@import CXHubCore;
@import CXHubNotify;

static NSString const* LOG_TAG = @"NotificationViewController";
static bool apiIsInitialized = false;

@interface NotificationViewController () <UNNotificationContentExtension>

@property (weak, nonatomic) IBOutlet UIImageView *bigContentImage;

@end

@implementation NotificationViewController

+(void)initialize {
    //Init CXHubSDK with default config, contained in provided Notify.plist
    //ApiIsInitialized = [CXApp initExtensionWithDefaultConfigAndEventsReceiver:nil];
    
    NSString *configFile = [[NSBundle mainBundle] pathForResource:@"Notify" ofType:@"plist"];
    CXAppConfig *config = [[CXAppConfig alloc] initWithConfig:configFile];
    apiIsInitialized = [CXApp initExtensionWithConfig:config withEventsReceiver:nil];
    
    //If you use come custom config, then you may use:
    /**
     * Initialize api for extension with custom config
     * @param config is a path to config file
     * @param eventsReceiver should implement either protocol CXUnhandledErrorReceiver
     * or CXMonitoringEventReceiver or both.
     */
    //+ (BOOL) initExtensionWithConfig:(CXAppConfig *)config
    //              withEventsReceiver:(nullable id)eventsReceiver;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any required interface initialization here.
}

#pragma mark UNNotificationContentExtension Delegate

- (void)didReceiveNotification:(UNNotification *)notification {
    if (!apiIsInitialized) {
        //Some error occured while initializing library, you need to handle such situations according to your app's logic
        return;
    }
    //Request 'big' notification content, if success, 'onContentUpdated... ' is called by CXHubSDK when content is downloaded
    // <CXContentExtensionDelegate> delegate will be set to 'self' (i.e. this ViewController)
    BOOL processed = [CXNotify requestNotificationExtensionContent:notification
                                                       withDelegate:self];
    
    if (!processed) {
        //Do some custom logic with a particular notification as it is not originated from CXHubSDK API.
    }
}

- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response
                     completionHandler:(void (^)(UNNotificationContentExtensionResponseOption option))completion {
    //If CXHubSDK is initialized correctly, transfer UNNotificationAction(s) (push notification toast button action) catches to CXHubSDK
    if(apiIsInitialized) {
        //For correct work of CXHubSDK, you need to check your ContentExtension Info.plist file to ensure
        //providing enough categories under Info.plist -> NSExtension -> NSExtensionAttributes -> UNNotificationExtensionCategory key
        //The same categories must be listed in Notify.plist (for all main app and both extensions) under Root -> LibNotify -> UNNotificationExtensionCategory key
        //Please, check the sample Notify.plist file provided for this demo-app.
        NSExtensionContext *context = self.extensionContext; //context is required to determine which UNNotificationAction is called
        [CXApp didReceiveExtensionNotificationResponse:response inContext:context completionHandler:completion];
    }
    else {
        //Catch action by yourself, cause CXHubSDK wasn't initialized correctly
    }
        
}

#pragma mark CXContentExtensionDelegate

- (void)onContentUpdated:(CXContentExtensionData *)content
         forNotification:(UNNotification *)notification
               withError:(NSError *)error {
    //Updates extension bigImage
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil || content == nil || content.attachmentData == nil) {
            return;
        }
        [self.bigContentImage setImage:[UIImage imageWithData:content.attachmentData]];
    });
}


@end
