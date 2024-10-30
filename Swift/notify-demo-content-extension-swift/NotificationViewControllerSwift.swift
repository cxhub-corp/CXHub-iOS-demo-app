//
//  NotificationViewController.swift
//  notify-demo-content-extension-swift
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import CXHubCore
import CXHubNotify

class NotificationViewControllerSwift: UIViewController, UNNotificationContentExtension {
    
    private var apiIsInitialized :  Bool = false
    
    @IBOutlet var bigContentImage: UIImageView!
    @IBOutlet var contentExtensionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.initializeSDK()
    }
     
    func didReceive(_ notification: UNNotification) {
        let processed = apiIsInitialized && CXNotify.requestNotificationExtensionContent(notification, with: self)
        
        if (!processed) {
            //Do some custom logic with a particular notification as it is not originated from CXHubSDK API.
        }
        else {
            self.contentExtensionLabel.text = notification.request.content.title;
        }
    }
    
    func initializeSDK () {
        //Init sdk
        //guard let config = CXAppConfig.default() else { fatalError() }
        
        guard let configFile = Bundle.main.path(forResource: "Notify", ofType: "plist") else { fatalError() };
        guard let config = CXAppConfig(config: configFile) else { fatalError() }
        
        apiIsInitialized = CXApp.initExtension(with: config, withEventsReceiver: nil)
    }
    
    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        if self.apiIsInitialized  {
            //For correct work of CXHubSDK, you need to check your ContentExtension Info.plist file to ensure
            //providing enough categories under Info.plist -> NSExtension -> NSExtensionAttributes -> UNNotificationExtensionCategory key
            //The same categories must be listed in Notify.plist (for all main app and both extensions) under Root -> LibNotify -> UNNotificationExtensionCategory key
            //Please, check the sample Notify.plist file provided for this demo-app.
            
            guard let context = self.extensionContext else { //context is required to determine which UNNotificationAction is called
                //Catch action by yourself, cause extension wasn't properly initialized
                return
            }
            CXApp.didReceiveExtensionNotificationResponse(response, in: context, completionHandler: completion)
        }
        else {
            //Catch action by yourself, cause CXHubSDK wasn't initialized correctly
        }
    }
}

extension NotificationViewControllerSwift: CXContentExtensionDelegate {

    func onContentUpdated(_ content: CXContentExtensionData?, for notification: UNNotification, withError error: Error?) {
        
        let localContent: CXContentExtensionData? = content

        DispatchQueue.main.async {
            guard let content = localContent, let attachmentData = content.attachmentData, error == nil else {
                return
            }
            
            self.bigContentImage.image = UIImage(data: attachmentData)
            self.contentExtensionLabel.text = String(format: "%@\n%@", notification.request.content.title,"Content updated")
        }
    }
}

