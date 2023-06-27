project "notify-demo-app.xcodeproj"
use_frameworks!
#
platform :ios, '12.1'
#
abstract_target 'CXHubSDK' do
        #pod 'CXHubSDK', '2.0.37'
        pod 'CXHubSDK', :path => "../../CXHubSDK_LocalGit/CXHubSDK"
#
    target 'notify-demo-app-objc'
        target 'notify-demo-service-extension-objc'
        target 'notify-demo-content-extension-objc'
#
    target 'notify-demo-app-swift'
        target 'notify-demo-service-extension-swift'
        target 'notify-demo-content-extension-swift'
end