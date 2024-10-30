//
//  NotifyViewController.swift
//  notify-demo-app-swift
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

import UIKit
import CXHubNotify

class NotifyViewController: UIViewController, UITextFieldDelegate {
    
    private enum Constants {
        static let defaultTestUserId: String = "some@mail.ru"
        
        static let testEvent1: String = "TestEvent1"
        static let testEventValu1: NSString = NSString(string: "TestEventValue1")
        static let testNumberEvent1: String = "TestNumberEvent1"
        static let testNumberValue1: NSNumber = NSNumber(value: 42)
        
        static let testEvent2: String = "TestEvent2"
        static let testEventValu2: String = "TestEventValu2"
    }
    
    @IBOutlet weak var devicePushToken: UITextView!
    @IBOutlet weak var instanceId: UITextView!
    @IBOutlet weak var useSandbox: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            NSLog("Invalid app delegate")
            return
        }
        
        devicePushToken.text = appDelegate.devicePushToken
        NotificationCenter.default.addObserver(forName: .PushTokenObtained, object: nil, queue: nil) { (notification) in
            self.devicePushToken.text = (notification.object as? String) ?? nil
        }
        //Set user id after some delay to imitate user login process
        //DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
            //Inform CXHub about userId change
        //    CXNotify.getInstance()?.setUserId(Constants.defaultTestUserId)
        //}
        self.instanceId.text = CXNotify.getInstance()?.getInstanceId()
        var isUseSandboxString: String! = "YES"
        var isUseSandbox: Bool! = false
        isUseSandbox = CXApp.isAPNSSandbox
        if(!isUseSandbox) {
            isUseSandboxString = "NO"
        }
        self.useSandbox.text = isUseSandboxString
        let text = self.useSandbox.text
        NSLog("useSandbox: %@", text ?? "unknown")
        NSLog("", "")
    }
    

    @IBAction func changeNotificationState(sender: Any?) {
        let alert = UIAlertController(title: "Notification state", message: nil, preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Enabled", style: .default, handler: { (_) in
            CXNotify.getInstance()?.notificationState = .enabled
        }))
        alert.addAction(.init(title: "Restricted", style: .default, handler: { (_) in
            CXNotify.getInstance()?.notificationState = .restricted
        }))
        alert.addAction(.init(title: "Disabled", style: .destructive, handler: { (_) in
            CXNotify.getInstance()?.notificationState = .disabled
        }))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func deviceIDTrackingSettings(sender: Any?) {
        let alert = UIAlertController(title: "DeviceID tracking", message: nil, preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Enable", style: .default, handler: { (_) in
            CXNotify.getInstance()?.setDeviceIdTrackingEnabled(true)
        }))
        alert.addAction(.init(title: "Disable", style: .default, handler: { (_) in
            CXNotify.getInstance()?.setDeviceIdTrackingEnabled(false)
        }))
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func sendTestEventNow(sender: Any?) {
        //An application could force CXHubSDK to send important events as soon as possible
        CXNotify.getInstance()?.collectEventMap([Constants.testEvent1: Constants.testEventValu1, Constants.testNumberEvent1: Constants.testNumberValue1], withImmediateLogic: true)
        CXNotify.getInstance()?.collectEvent(Constants.testEvent2, withValue: Constants.testEventValu2, withImmediateLogic: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
