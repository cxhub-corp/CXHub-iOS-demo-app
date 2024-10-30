//
//  NotificationViewController.m
//  notify-demo-content-extension-objc
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

#import "NotificationViewControllerObjc.h"

@import CXHubCore;
@import CXHubNotify;

static NSString const* LOG_TAG = @"NotificationViewController";
static bool apiIsInitialized = false;

@interface NotificationViewControllerObjc ()

@property (nonatomic, strong) UIImageView *bigContentImage;
@property (nonatomic, strong) UILabel *contentExtensionLabel;

@end

@implementation NotificationViewControllerObjc



+(void)initialize {
    //Init CXHubSDK with default config, contained in provided Notify.plist
    //ApiIsInitialized = [CXApp initExtensionWithDefaultConfigAndEventsReceiver:nil];
    
    NSString *configFile = [[NSBundle mainBundle] pathForResource:@"Notify" ofType:@"plist"];
    CXAppConfig *config = [[CXAppConfig alloc] initWithConfig:configFile];
    apiIsInitialized = [CXApp initExtensionWithConfig:config withEventsReceiver:nil];
    NSLog(@"apiIsInitialized: %@",apiIsInitialized ? @"YES":@"NO");
    
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
    if(!self->_bigContentImage) {
        self->_bigContentImage = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self->_bigContentImage.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:self->_bigContentImage];
    }
    if(!self->_contentExtensionLabel) {
        self->_contentExtensionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 24)];
        self->_contentExtensionLabel.text = @"This is ContentExtension view";
        self->_contentExtensionLabel.textAlignment = NSTextAlignmentCenter;
        self.contentExtensionLabel.textColor = UIColor.greenColor;
        self.contentExtensionLabel.backgroundColor = UIColor.whiteColor;
        [self.view addSubview:self->_contentExtensionLabel];
    }
    // Do any required interface initialization here.
}

- (void)viewWillLayoutSubviews {
    self.bigContentImage.frame = self.view.bounds;
    self.bigContentImage.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    
    self.contentExtensionLabel.frame = CGRectMake(0, 0, self.view.bounds.size.width, 24);
    self.contentExtensionLabel.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    [super viewWillLayoutSubviews];
}

#pragma mark UNNotificationContentExtension Delegate

- (void)didReceiveNotification:(UNNotification *)notification {
    NSLog(@"didReceiveNotification -> (apiIsInitialized: %@)",apiIsInitialized ? @"YES":@"NO");
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
    else {
        self.contentExtensionLabel.text = notification.request.content.title;
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
        if(self.bigContentImage) {
            NSData *imgData = content.attachmentData;
            UIImage *img = [UIImage imageWithData:imgData];
            [self->_bigContentImage setImage:img]; //[UIImage imageWithData:content.attachmentData]];
        }
        else {
            self.contentExtensionLabel.text = [NSString stringWithFormat:@"%@/n%@",notification.request.content.title,@"Content Updated"];
        }
        [self.view layoutIfNeeded];
    });
}


@end
