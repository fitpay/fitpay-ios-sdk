platform :ios, '9.0'
use_frameworks!

target 'FitpaySDK' do
    pod 'Alamofire', '4.0.0'
    pod 'ObjectMapper', '2.0.0'
    pod 'AlamofireObjectMapper', '4.0.0'
    pod 'JWTDecode', '2.0.0'
    pod 'KeychainAccess', '3.0.0'
end

target 'FitpaySDKDemo' do
    pod 'AlamofireObjectMapper', '4.0.0'
    pod 'JWTDecode', '2.0.0'
    pod 'KeychainAccess', '3.0.0'
end

target 'FitpaySDKTests' do
    pod 'AlamofireObjectMapper', '4.0.0'
    pod 'JWTDecode', '2.0.0'
end

target 'RTMClientApp' do
    pod 'AlamofireObjectMapper', '4.0.0'
    pod 'JWTDecode', '2.0.0'
    pod 'KeychainAccess', '3.0.0'
end

target 'ObjCDemo' do
    pod 'AlamofireObjectMapper', '4.0.0'
    pod 'JWTDecode', '2.0.0'
    pod 'KeychainAccess', '3.0.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0.1'
    end
  end
end
