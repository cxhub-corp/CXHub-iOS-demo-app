//
//  AppDelegate.m
//  notify-demo-app
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

#import "AppDelegate.h"

@import CXHubCore;
@import CXHubNotify;

static NSString *const LOG_TAG = @"AppDelegate";

@interface EventsHandler : NSObject <CXUnhandledErrorReceiver, CXMonitoringEventReceiver>
@end

@implementation EventsHandler

- (void)onUnhandledException:(NSException *)exception {
    NSLog(@"%@ - CXHubSDK exception: %@", LOG_TAG, exception);
}

- (void)onUnexpectedError:(NSError *)error {
    NSLog(@"%@ - CXHubSDK error: %@", LOG_TAG, error);
}

- (void)logEvent:(NSString *)key withValue:(NSString *)value {
    NSLog(@"%@ - CXHubSDK internal event: %@ with value: %@", LOG_TAG, key, value);
}

- (void)logEvent:(NSString *)key withMapping:(NSDictionary<NSString *, NSString *> *)mapping {
    NSLog(@"%@ - CXHubSDK internal event: %@ with mapping: %@", LOG_TAG, key, mapping);
}

@end


@interface AppDelegate() <CXNotifyDelegate>

@property (nonatomic, strong) EventsHandler *eventsHandler;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //Init sdk
    self.eventsHandler = [EventsHandler new];
    
    /**
     There are few alternative ways to initialize library.
     
     For example you may want to create few configurations and use
     various app names for them.
     
     1. You may create few configuration files and use them
        #ifdef DEBUG
            NSString *configFile = [[NSBundle mainBundle] pathForResource:@"Debug-config" ofType:@"plist"];
        #else
            NSString *configFile = [[NSBundle mainBundle] pathForResource:@"Release-config" ofType:@"plist"];
        #endif
        CXAppConfig *config = [[CXAppConfig alloc] initWithConfig:configFile];
        [CXApp initWithConfig:config withEventsReceiver:nil];
     
     2. Or you can use one config file. Load it and change before initialize app.
        CXAppConfig *config = [CXAppConfig defaultConfig];
        // Change parameters of config
        [CXApp initWithConfig:config withEventsReceiver:nil];
     */
    
    //Following line initializes library with default config and events handler (see EventsHandler class above), you may send 'nil' if don't want to handle events and\or unhandled exceptions.
    //NB: Notify.plist with all required keys must be provided.
    
    //[CXApp initWithDefaultConfigAndEventsReceiver:self.eventsHandler];
    
    NSString *configFile = [[NSBundle mainBundle] pathForResource:@"Notify" ofType:@"plist"];
    CXAppConfig *config = [[CXAppConfig alloc] initWithConfig:configFile];
    if([CXApp initWithConfig:config withEventsReceiver:self.eventsHandler]) {
        // Setup delegate for get requests from CXHubSDK
        [[CXNotify getInstance] setDelegate:self];
        
        //Collect some events during initialization process
        [[CXNotify getInstance] collectEvent:@"TestEvent1"];
        [[CXNotify getInstance] collectEvent:@"TestEvent2" withValue:@"TestValue2"];
    }
    //Subscribe for push notifications
    [self authorizeForRemoteNotificationsWithCompletion:^(BOOL granted, NSError *error) {
        
        //Here one can do something, which should be performed prior to APNS registration
        // but after requesting push notification permissions
        // This provide an option to check which permissions are restricted (if granted == false)
        
        //if granted, then an app will register for remote notifications ap APNS right after completion handler finished it's work
        NSLog(@"granted: %@", granted ? @"YES":@"NO");
        
    }];

    //An application could customize notification landing view using keys in Info.plist file starting with CX prefix.
    //Check out CXHubSDK documentation to understand actual meaning of all provided keys.
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    //Forward system call to CXHubSDK
    [CXApp applicationDidBecomeActive:application];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    //Forward system call to CXHubSDK
    [CXApp applicationWillResignActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    //Forward system call to CXHubSDK
    [CXApp applicationWillTerminate:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    //Forward system call to CXHubSDK
    [CXApp applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    //Forward system call to CXHubSDK
    [CXApp applicationWillEnterForeground:application];
}

#pragma mark - Work with URL (UIApplicationDelegate)

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    //Do some app's specific check if app can open url, if yes, then return 'true', otherwise 'false'
    return true;
}

#pragma mark - Work with remote notifications
#pragma mark RegisterForPushNotifications

- (void)authorizeForRemoteNotificationsWithCompletion:(void (^)(BOOL granted, NSError *error))completionHandler {
#if TARGET_OS_SIMULATOR
    
    //There is no way to receive real push notifications in simulator, therefore local notifications are used instead to show how library works
    dispatch_async(dispatch_get_main_queue(), ^{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if(!!completionHandler) {
                completionHandler(true, nil);
            }
            NSString* testToken = [[[NSUUID UUID] UUIDString] stringByAppendingString:@"-simulator"];
            [CXApp applicationDidRegisterForRemoteNotificationsWithDeviceToken:[testToken dataUsingEncoding:NSUTF8StringEncoding]];
        });
    });
    return;
#else
    //Set UNUserNotificationCenterDelegate - this have to be done prior to be registered for remote notifications
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    
    UNAuthorizationOptions optsToRequest = UNAuthorizationOptionAlert|UNAuthorizationOptionBadge|UNAuthorizationOptionSound|UNAuthorizationOptionCarPlay;
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:optsToRequest completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if(error == nil && granted) {
            [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                if(settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                    if(!!completionHandler) {
                        completionHandler(granted, error);
                    }
                }
                else {
                    if(!!completionHandler) {
                         completionHandler(!granted,error);
                    }
                }
                //we'll register for notifications anyway, if there is no permission granted, we still keep receiving notifications, but in silent mode
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
            }];
        }
        else {
            if(!!completionHandler) {
                completionHandler(granted, error);
            }
            //we'll register for notifications anyway, if there is no permission granted, we still keep receiving notifications, but in silent mode
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
    }];
#endif
}

#pragma mark RemoteNotifications registration reaction (successful or fail)

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    //any custom event could be sent via CXHubSDK API, using 'collectEvent:...' interface
    [[CXNotify getInstance] collectEvent:@"TokenUpdated"];
    
    //provide CXHubSDK with a valid push token obtained from the OS
    [CXApp applicationDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];

    
    //next block is used only to update demo-app's interface, CXHubSDK doesn't need it
    NSMutableString * token = [NSMutableString new];
    [deviceToken enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        for (int i = 0; i < byteRange.length; i++) {
            [token appendFormat:@"%02.2hhx", ((unsigned char *)bytes)[i]];
        }
    }];
    self.devicePushToken = token;
    [[NSNotificationCenter defaultCenter] postNotificationName:TEST_APP_PUSH_TOKEN_OBTAINED object:self.devicePushToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [CXApp applicationDidFailToRegisterForRemoteNotificationsWithError:error];
}

- (void) application:(UIApplication *)application
        didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    //prints notification payload json
    //[self printNotificationPayloadJSON:userInfo];
    
    CXBackgroundFetchCallback joinedCompletionHandler = [CXApp didReceiveRemoteNotification:userInfo
                                                                       fetchCompletionHandler:completionHandler];
    //Do here your application specific push processing logic.
    joinedCompletionHandler(UIBackgroundFetchResultNoData);
}

/**
 Helper method to print notification payload as pretty json (unformatted)
 */
- (void)printNotificationPayloadJSON:(NSDictionary *)notificationUserInfo {
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:notificationUserInfo options:NSJSONWritingPrettyPrinted error:&err];
    if(!err && !!jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"Notification.payload:\n %@\n\n",jsonString);
    }
}

#pragma mark - Other UIApplicationDelegate methods

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    NSLog(@"%@ - background fetch", LOG_TAG);
    CXBackgroundFetchCallback joinedCompletionHandler = [CXApp performFetchWithCompletionHandler:completionHandler];
    //Simulate some application specific background data processing
    [NSThread sleepForTimeInterval:1];
    //When all down call an aggregated callback to give ability to CXHubSDK complete all it's
    //background tasks
    joinedCompletionHandler(UIBackgroundFetchResultNewData);
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
    //Forward system call to CXHubSDK
    [CXApp applicationSignificantTimeChange:application];
}

#pragma mark - UNUserNotificationCenterDelegate

//Called when a notification is delivered to a foreground app.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center
      willPresentNotification:(UNNotification *)notification
        withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0))
{
    NSLog(@"%@ - user info (foreground): %@", LOG_TAG, notification.request.content.userInfo);
    //An application could control here what to do in case of CXHubSDK push received
    //in a foreground mode.
    //If you have NotificationService component, it's corresponding method is called instead even in foreground mode.
    __auto_type result = [CXApp userNotificationCenter:center
                                willPresentNotification:notification
                                  withCompletionHandler:completionHandler];
    
    if (result == CXWillPresentNotificationResultSuccess) {
        NSLog(@"%@ - user info (foreground): %@, processed by libverify: %lu",
              LOG_TAG, notification.request.content.userInfo, (unsigned long)result);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert);
    }
}

//Called to let your app know which action was selected by the user for a given notification.
//If you have ContentExtension component, it's corresponding method is called instead even in foreground mode.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
        withCompletionHandler:(void(^)(void))completionHandler API_AVAILABLE(ios(10.0))
{
    CXCallBack joinedCompletionHandler = [CXApp didReceiveNotificationResponse:response
                                                           withCompletionHandler:completionHandler];
    //Do here your application specific push processing logic.
    joinedCompletionHandler();
}

#pragma mark - CXNotifyDelegate

//MARK: @required:

/**
 This method is called when user select action open_main
 on landing. It's called in main thread.
 */

- (bool)cxOpenMainInterface {
    //you may provide some specific logic (i.e. open any other ViewController here)
    //return 'true' if your logic succeeded, otherwise 'false'.
    //if 'true', then 'NotifyMessageLandingOpened' event is sent to CXHub-server
    return true;
}

//MARK: @optional:

/**
 You may implement this method in your class.
 All incoming pushes with url will be tried to open url with this method.
 If your implementation returns true handling of url will be completed
 else logic will call method -[UIApplication openUrl:].
 This method will be called in the main thread.
 */

- (bool)openURL:(NSURL *)url {
    //Example implementation
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (![preferences boolForKey:@"CX_CatchDeepLink"]) {
        return false;
    }

    __auto_type vc = [UIAlertController alertControllerWithTitle:@"App is handling url" message:url.absoluteString preferredStyle:UIAlertControllerStyleAlert];

    [vc addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
    [[_window rootViewController] presentViewController:vc animated:true completion:nil];
    return true;
}

- (UIFont *)activityTitleFont {
    __auto_type baseFont = [UIFont systemFontOfSize:24.0 weight:UIFontWeightHeavy];
    if (@available(iOS 11.0, *)) {
        return [[UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle1] scaledFontForFont:baseFont];
    } else {
        return baseFont;
    }
}

- (UIFont *)activityBodyFont {
    __auto_type baseFont = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    if (@available(iOS 11.0, *)) {
        return [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:baseFont];
    } else {
        return baseFont;
    }
}

- (UIFont *)activityButtonTitleFont {
    __auto_type baseFont = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    if (@available(iOS 11.0, *)) {
        return [[UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:baseFont];
    } else {
        return baseFont;
    }
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0)) {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0)){
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
