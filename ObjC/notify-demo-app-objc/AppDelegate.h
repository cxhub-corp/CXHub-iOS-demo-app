//
//  AppDelegate.h
//  notify-demo-app
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UNUserNotificationCenter.h>

#define TEST_APP_PUSH_TOKEN_OBTAINED @"test.app.pushtoken.obtained"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>

/**
 are used only to update demo-app's interface, CXHubSDK itself doesn't need these properties
 */
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString* devicePushToken;

@end

