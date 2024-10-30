//
//  NotificationService.swift
//  notify-demo-sevice-extension-swift
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

import UserNotifications
import CXHubCore
import CXHubNotify

class NotificationService: UNNotificationServiceExtension {

    private var apiIsInitialized :  Bool = false
    
    override init() {
        //Init sdk
        guard let configFile = Bundle.main.path(forResource: "Notify", ofType: "plist") else { fatalError() };
        guard let config = CXAppConfig(config: configFile) else { fatalError() }
        
        //guard let config = CXAppConfig.default() else { fatalError() }
        apiIsInitialized = CXApp.initExtension(with: config, withEventsReceiver: nil)
    }
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        if self.apiIsInitialized {
            //This is notification for CXHubSDK and it will handle all other logic
            let didReceive = CXApp.didReceiveExtensionNotificationRequest(request, withContentHandler: contentHandler)
            NSLog("Did receive: %@", didReceive ? "YES":"NO")
            if !didReceive {
                contentHandler(request.content)
            }
        } else {
            //Some other application notification, so application could do whatever necessary
            contentHandler(request.content)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if self.apiIsInitialized  {
            let timeWillExpire = CXApp.serviceExtensionTimeWillExpire()
            NSLog("Time expire: %@", timeWillExpire ? "YES":"NO")
            //In case CXHubSDK extension api logic was started, then CXHubSDK will take care of content handlers,
            //otherwise application could do whatever necessary
        } else {
            //Some other custom application logic to call content handler
        }
    }
}

