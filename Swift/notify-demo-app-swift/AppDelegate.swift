//
//  AppDelegate.swift
//  notify-demo-app-swift
//
//  Copyright © 2023 Mail.Ru LLC. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import CXHubCore
import CXHubNotify

class NotifyHandler: NSObject, CXUnhandledErrorReceiver, CXMonitoringEventReceiver {
    
    private enum Constants {
        static let logTag: NSString = "AppDelegate"
    }
    
    func onUnhandledException(_ exception: NSException) {
        NSLog("\(Constants.logTag) - exception: \(exception.description)")
    }
    
    func onUnexpectedError(_ error: Error) {
        NSLog("\(Constants.logTag) - error: \(error.localizedDescription)")
    }
    
    func logEvent(_ key: String, withValue value: String?) {
        NSLog("\(Constants.logTag) - CXHubSDK internal event: \(key) with value: \(value ?? "")")
    }
    
    func logEvent(_ key: String, withMapping mapping: [String : String]) {
        NSLog("\(Constants.logTag) - CXHubSDK internal event: \(key) with value: \(mapping)")
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private enum AppDelegateErrors: Error {
        case pushNotificationsAreUnavailableOnSimulator
    }
    
    fileprivate enum Constants {
        static let logTag = "AppDelegate"
        static let testEvent1:String = "TestEvent1"
        static let testEvent2:String = "TestEvent2"
        static let testValue2:String = "TestValue2"
        static let tokenUpdatedEvent:String = "TokenUpdated"
    }
    
    var window: UIWindow?
    var devicePushToken: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        //Subscribe for push notifications
        do {
            try registerForRemoteNotifications()
        } catch {
            NSLog("Push notifications are unavailable on iOS simulator")
//            return true
        }

        guard let config = CXAppConfig.default() else { fatalError() }
        CXApp.initWith(config, withEventsReceiver: nil)
        CXApp.setUnhandledErrorReceiver(NotifyHandler())
        CXApp.setMonitoringEventReceiver(NotifyHandler())

        // Setup delegate to get requests from CXHubSDK
        CXNotify.getInstance()?.setDelegate(self)

        //Collect some events during initialization process
        CXNotify.getInstance()?.collectEvent(Constants.testEvent1)
        CXNotify.getInstance()?.collectEvent(Constants.testEvent2, withValue: Constants.testValue2)
        //An application could customize notification landing view using keys in Info.plist file starting with CX prefix.
        //Check out CXHubSDK documentation to understand actual meaning of all provided keys.
        self.setUserId()
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        //Forward system call to CXHubSDK
        CXApp.applicationWillEnterForeground(application)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        //Forward system call to CXHubSDK
        CXApp.applicationDidBecomeActive(application)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        //Forward system call to CXHubSDK
        CXApp.applicationWillResignActive(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        //Forward system call to CXHubSDK
        CXApp.applicationDidEnterBackground(application)
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        //Forward system call to CXHubSDK
        CXApp.applicationWillTerminate(application)
    }
    
    func applicationSignificantTimeChange(_ application: UIApplication) {
        //Forward system call to CXHubSDK
        CXApp.applicationSignificantTimeChange(application)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //any custom event could be sent via CXHubSDK API
        CXNotify.getInstance()?.collectEvent(Constants.tokenUpdatedEvent)
        
        //provide CXHubSDK with a valid push token obtained from the OS
        //and forward system call to CXHubSDK
        CXApp.applicationDidRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        
        let token = deviceToken.hexString
        self.devicePushToken = token
        NotificationCenter.default.post(name: .PushTokenObtained, object: token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        CXApp.applicationDidFailToRegisterForRemoteNotificationsWithError(error)
    }
    
    // Uncomment next to forward local notifications (keeping CXHub format) to CXhubSDK
    //func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
    //    let joinedCompletionHandler = CXApp.didReceiveLocalNotification(notification.userInfo, withCompletionHandler: {})
    //    joinedCompletionHandler()
    //}
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let joinedCompletionHandler = CXApp.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
        //Do here your application specific push processing logic.
        joinedCompletionHandler(.noData)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if let joinedCompletionHandler = CXApp.performFetch(completionHandler: completionHandler) {
            //Simulate some application specific background data processing
            Thread.sleep(forTimeInterval: 1)
            //When all down call an aggregated callback to give ability to CXHubSDK complete all it's
            //background tasks
            joinedCompletionHandler(.newData)
        } else {
            completionHandler(.newData)
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        //Do some app's specific check if app can open url, if yes, then return 'true', otherwise 'false'
        
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    //Called when a notification is delivered to a foreground app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //An application could control here what to do in case of CXHubSDK push received
        //in a foreground mode.
        //If you have NotificationService component, it's corresponding method is called instead even in foreground mode.
        
        let res = CXApp.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)

        switch res {
        case .failure, .unknown:
            completionHandler([.banner,.list, .sound])
        default:
            break
        }
    }

    //Called to let your app know which action was selected by the user for a given notification.
    //If you have ContentExtension component, it's corresponding method is called instead even in foreground mode.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //Do here your application specific push processing logic.
        if let joinedCompletionHandler = CXApp.didReceive(response, withCompletionHandler: completionHandler) {
            joinedCompletionHandler()
        } else {
            completionHandler()
        }
    }    
}

extension AppDelegate: CXNotifyDelegate {

    //MARK: @required:

    /**
     This method is called when user select action open_main
     on landing. It's called in main thread.
     */

    func cxOpenMainInterface() -> Bool {
        //you may provide some specific logic (i.e. open any other ViewController here)
        //return 'true' if your logic succeeded, otherwise 'false'.
        //if 'true', then 'NotifyMessageLandingOpened' event is sent to CXHub-server
        return true
    }
    
    //MARK: @optional:

    /**
     You may implement this method in your class.
     All incoming pushes with url will be tried to open url with this method.
     If your implementation returns true handling of url will be completed
     else logic will call method -[UIApplication openUrl:].
     This method will be called in the main thread.
     */
    func open(_ url: URL) -> Bool {
        //Example implementation
        let preferences = UserDefaults.standard
        if(!preferences.bool(forKey: "CX_CatchDeepLink")) {
            return false
        }
        let vc = UIAlertController(title: "App is handling url", message: url.absoluteString, preferredStyle: .alert)
        window?.rootViewController?.present(vc, animated: true, completion: nil)
        return true;
    }

    var activityTitleFont: UIFont {
        let baseFont = UIFont.systemFont(ofSize: 24.0, weight: .heavy)
        if #available(iOS 11.0, *) {
            return UIFontMetrics.init(forTextStyle: .title1).scaledFont(for: baseFont)
        } else {
            return baseFont
        }
    }

    var activityBodyFont: UIFont {
        let baseFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        if #available(iOS 11.0, *) {
            return UIFontMetrics.init(forTextStyle: .body).scaledFont(for: baseFont)
        } else {
            return baseFont
        }
    }

    var activityButtonTitleFont: UIFont {
        let baseFont = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        if #available(iOS 11.0, *) {
            return UIFontMetrics.init(forTextStyle: .subheadline).scaledFont(for: baseFont)
        } else {
            return baseFont
        }
    }

}

private extension AppDelegate {
    func setUserId() {
        let userEmail = "vladimir_2_test.gk.2011_dont_use_please@mail.ru"
        let popTime = DispatchTime(uptimeNanoseconds: 2*NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            CXNotify.getInstance()?.setUserId(userEmail, ofType: "Email")
            CXNotify.getInstance()?.setInstanceProperty("Email", withStringValue: userEmail)
        }
    }
    
    func registerForRemoteNotifications() throws {
        
        #if targetEnvironment(simulator)
        throw AppDelegateErrors.pushNotificationsAreUnavailableOnSimulator
        #else
        if #available(iOS 10.0, *) {
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.delegate = self

            notificationCenter.requestAuthorization(options: [.alert, .badge, .sound, .carPlay]) { (granted, error) in
                if let error = error {
                    NSLog("Something was wrong: \(error)")
                } else if !granted {
                    NSLog("Push notifications disabled")
                }
                
                //Anyway try to register, checking notifications settings first
                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        switch settings.authorizationStatus {
                        case .authorized:
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                            break
                        //case .ephemeral:
                        //    break
                        //case .provisional:
                        //    break
                        default:
                            NSLog("User didn't give you permissions for notifications, but you still may register to receive notifications in silent mode")
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        #endif
    }
}

extension Notification.Name {
    static let PushTokenObtained = Notification.Name("test.app.pushtoken.obtained")
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
