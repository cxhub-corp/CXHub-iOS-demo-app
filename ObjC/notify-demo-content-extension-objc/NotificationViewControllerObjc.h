//
//  NotificationViewController.h
//  notify-demo-content-extension-objc
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@import CXHubNotify;

@interface NotificationViewControllerObjc : UIViewController <CXContentExtensionDelegate, UNNotificationContentExtension>

- (void)didReceiveNotification:(UNNotification *)notification;

@end

