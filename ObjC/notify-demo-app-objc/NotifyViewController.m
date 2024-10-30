//
//  NotifyViewController.m
//  notify-demo-app-objc
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

#import "NotifyViewController.h"
#import "AppDelegate.h"
@import CXHubNotify;

static NSString *const DEFAULT_TEST_USER_ID = @"vladimir_2_test.gk.2011_dont_use_please@mail.ru";

@interface NotifyViewController ()

@end

@implementation NotifyViewController

- (IBAction)onChangeNotificationState:(id)sender {
    __auto_type alert = [UIAlertController alertControllerWithTitle:@"Notification state" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"Enabled" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CXNotify.getInstance.notificationState = CXNotificationStateEnabled;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Only transactions" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CXNotify.getInstance.notificationState = CXNotificationStateRestricted;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Disabled" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        CXNotify.getInstance.notificationState = CXNotificationStateDisabled;
    }]];
    [self presentViewController:alert animated:true completion:nil];
}

- (IBAction)deviceIdTrackingSettings:(id)sender {
    __auto_type alert = [UIAlertController alertControllerWithTitle:@"DeviceID tracking" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    __auto_type actionEnable = [UIAlertAction actionWithTitle:@"Enable" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[CXNotify getInstance] setDeviceIdTrackingEnabled:true];
    }];
    [alert addAction:actionEnable];

    __auto_type actionDisable = [UIAlertAction actionWithTitle:@"Disable" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[CXNotify getInstance] setDeviceIdTrackingEnabled:false];
    }];
    [alert addAction:actionDisable];

    __auto_type actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:actionCancel];

    [self presentViewController:alert animated:true completion:nil];
}

- (IBAction)onSendTestEventsNowButtonClick:(id)sender {
    //An application could force CXHubSDK to send important events as soon as possible
    [[CXNotify getInstance] collectEventMap:@{@"TestEvent1":@"TestEventValue1", @"TestNumberEvent1":@(42)}
                          withImmediateLogic:YES];
    [[CXNotify getInstance] collectEvent:@"TestEvent2"
                                withValue:@"TestEventValue2"
                       withImmediateLogic:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.devicePushToken.text = appDelegate.devicePushToken;
    [[NSNotificationCenter defaultCenter] addObserverForName:TEST_APP_PUSH_TOKEN_OBTAINED object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        self.devicePushToken.text = (NSString*) note.object;
    }];
    //Set user id after some delay to imitate user login process
    const dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        //Inform CXHub about userId change
        [[CXNotify getInstance] setUserId:DEFAULT_TEST_USER_ID ofType:@"Email"];
    });
    self.instanceId.text = [[CXNotify getInstance] getInstanceId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
