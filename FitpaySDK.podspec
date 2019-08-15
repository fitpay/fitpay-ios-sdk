Pod::Spec.new do |s|
  s.requires_arc = true
  s.name = 'FitpaySDK'
  s.version = '1.6.2'
  s.license = 'MIT'
  s.summary = 'Swift based library for the Fitpay Platform'
  s.homepage = 'https://github.com/fitpay/fitpay-ios-sdk'
  s.authors = { 'Fit Pay, Inc' => 'sdk@fit-pay.com' }
  s.source = { :git => 'https://github.com/fitpay/fitpay-ios-sdk.git', :tag => 'v1.6.2' }

  s.dependency 'Alamofire', '~> 4.1'
  s.dependency 'RxSwift', '~> 4.1'

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.2'
  s.source_files  = "{FitpaySDK}/**/*.{h,m,swift}"

end
