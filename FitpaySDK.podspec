Pod::Spec.new do |s|
  s.requires_arc = true
  s.name = 'FitpaySDK'
  s.version = '0.4.2'
  s.license = 'MIT'
  s.summary = 'Swift based library for the Fitpay Platform'
  s.homepage = 'https://github.com/fitpay/fitpay-ios-sdk'
  s.authors = { 'Fit Pay, Inc' => 'sdk@fit-pay.com' }
  s.source = { :git => 'https://github.com/fitpay/fitpay-ios-sdk.git', :tag => 'v0.4.2' }

  s.dependency 'Alamofire', '4.1.0'
  s.dependency 'ObjectMapper', '2.2.5'
  s.dependency 'AlamofireObjectMapper', '4.0.0'
  s.dependency 'JWTDecode', '2.0.0'
  s.dependency 'KeychainAccess', '3.0.0'

  s.ios.deployment_target = '9.0'
  s.source_files  = "{FitpaySDK,Common}/**/*.swift"


end

