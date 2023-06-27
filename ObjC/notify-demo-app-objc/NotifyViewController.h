//
//  NotifyViewController.h
//  notify-demo-app-objc
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//


@import UIKit;

@interface NotifyViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextView *devicePushToken;
@property (weak, nonatomic) IBOutlet UITextView *instanceId;

@end

