# FitPay iOS SDK 


[![GitHub license](https://img.shields.io/github/license/fitpay/fitpay-ios-sdk.svg)](https://github.com/fitpay/fitpay-ios-sdk/blob/develop/LICENSE)
[![Build Status](https://travis-ci.org/fitpay/fitpay-ios-sdk.svg?branch=develop)](https://travis-ci.org/fitpay/fitpay-ios-sdk)
[![Latest pod release](https://img.shields.io/cocoapods/v/FitpaySDK.svg)](https://cocoapods.org/pods/FitpaySDK)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Installing the SDK

Fitpay distributes the SDK via cocoapods and carthage. Documentation on using **cocoapods** can be found [here](https://guides.cocoapods.org/using/getting-started.html) and for **carthage** [here](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos). 
### Cocoapods
Currently we are using cocoapods v1.4.0

Once you have set up your project to use cocoapods, add the following to your Podfile:
```
pod 'FitpaySDK'
```

### Carthage
Once you have set up your project to use carthage, add the following to your Cartfile:
```
github "fitpay/fitpay-ios-sdk"
```
After that you should follow to default carthage workflow, which is:

1. Execute next command:  ```$carthage update --platform iOS```
1. On your application targets’ “General” settings tab, in the “Linked Frameworks and Libraries” section, drag and drop all frameworks from the Carthage/Build folder on disk.
1. On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script in which you specify your shell (ex: `bin/sh`), add the following contents to the script area below the shell:

  ```sh
  /usr/local/bin/carthage copy-frameworks
  ```
  and add the paths to the frameworks you want to use under “Input Files”, e.g.:
 
  ```
  $(SRCROOT)/Carthage/Build/iOS/Alamofire.framework
  $(SRCROOT)/Carthage/Build/iOS/AlamofireObjectMapper.framework
  $(SRCROOT)/Carthage/Build/iOS/JSONWebToken.framework
  $(SRCROOT)/Carthage/Build/iOS/ObjectMapper.framework
  $(SRCROOT)/Carthage/Build/iOS/FitpaySDK.framework
  ```

## Using the SDK

### Building the SDK locally

```
sudo gem install cocoapods
cd ~  
mkdir fitpay
cd fitpay  
git clone git@github.com:fitpay/fitpay-ios-sdk.git
cd fitpay-ios-sdk
pod install  
```
Open Xcode (currently using Xcode 9.2), and add a project (->Open another project->/users/yourname/fitpay/fitpay-ios-sdk)  

Select the **FitpaySDK** build under Product->Scheme. Ensure that the scheme is set to build for Generic iOS Device.

### Running Tests From the Commandline
By default the tests will run in the iPhone 7 simulator.
```
./bin/test
```
To test on a different simulator, pass in a valid simulator same.
```
./bin/test "iPhone 5s"
```

### Card Scanning
By default the FitPay WebView utilizes a web based card scanning service which is currently being EOL'ed, that means the ability to scan a card during card entry now must be handled natively by the SDK implementation.  The SDK provides an interface `IFitPayCardScanner` where a scanning implementation can be provided.   An full working example using the [Card.IO](https://www.card.io/) utility can be seen in our [reference implementation](https://github.com/fitpay/Pagare_iOS_WV/).
 
### Logging
In order to remain flexible with the various mobile logging strategies, the SDK provides a mechanism to utilize custom logging implementations. For custom implementation there is protocol `LogsOutputProtocol` which should be implemented, and after that object of that protocol implementation should be added to logs ouput.

Code example:

```
        class ErrorPusherOutput: LogsOutputProtocol {
            func send(level: LogLevel, message: String, file: String, function: String, line: Int) {
                if level == .error {
                    print("Going to push next message:", message)
                    // code for pushing here
                }
            }
        }
        
        let log = FitpaySDKLogger.sharedInstance
        log.addOutput(output: ConsoleOutput())
        log.addOutput(output: ErrorPusherOutput())
        log.minLogLevel = .debug

```

## Contributing to the SDK
We welcome contributions to the SDK. For your first few contributions please fork the repo, make your changes and submit a pull request. Internally we branch off of develop, test, and PR-review the branch before merging to develop (moderately stable). Releases to Master happen less frequently, undergo more testing, and can be considered stable. For more information, please read:  [http://nvie.com/posts/a-successful-git-branching-model/](http://nvie.com/posts/a-successful-git-branching-model/)

## License
This code is licensed under the MIT license. More information can be found in the [LICENSE](LICENSE) file contained in this repository.

## Questions? Comments? Concerns?
Please contact the team via a github issue, OR, feel free to email us: sdk@fit-pay.com


## Fit Pay Internal Instructions 
### Publishing Updated SDKs
* Please add a name to each release using the following convention: `FitPay SDK for iOS vX.X.X`
* Please also include notes using proper markdown about each major PR in the release.
* [How-to publish (deploy) a new version of the iOS FitPay SDK](https://fitpay.atlassian.net/wiki/spaces/ENG/pages/92798977/How-to+publish+deploy+a+new+version+of+the+iOS+FitPay+SDK)

