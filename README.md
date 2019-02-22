# FitPay iOS SDK 

We are gradually moving content regarding consumption of this SDK to our [documentation](https://docs.fit-pay.com). The intended audience for this README is developers contributing to this repository.

[![GitHub license](https://img.shields.io/github/license/fitpay/fitpay-ios-sdk.svg)](https://github.com/fitpay/fitpay-ios-sdk/blob/develop/LICENSE)
[![Build Status](https://travis-ci.com/fitpay/fitpay-ios-sdk.svg?branch=develop)](https://travis-ci.com/fitpay/fitpay-ios-sdk)
[![Latest pod release](https://img.shields.io/cocoapods/v/FitpaySDK.svg)](https://cocoapods.org/pods/FitpaySDK)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codecov](https://codecov.io/gh/fitpay/fitpay-ios-sdk/branch/develop/graph/badge.svg)](https://codecov.io/gh/fitpay/fitpay-ios-sdk)
[![Documentation coverage](docs/badge.svg)](docs/badge.svg)

## Installation - Pod Install
Your podfile should look something like this:
```
target 'YourApp' do
pod 'FitpaySDK', '~>1.6.0'
end
```

## Running Tests From the Commandline
By default the tests will run in the iPhone 7 simulator.
```
./bin/test
```
To test on a different simulator, pass in a valid simulator name.
```
./bin/test "iPhone 5s"
``` 

# Migration from 0.x to 1.x

This content has been moved to our [documentation](https://docs.fit-pay.com/SDK/iOS/migration/)

# Contributing to the SDK
We welcome contributions to the SDK. For your first few contributions please fork the repo, make your changes and submit a pull request. Internally we branch off of develop, test, and PR-review the branch before merging to develop (moderately stable). Releases to Master happen less frequently, undergo more testing, and can be considered stable. For more information, please read:  [http://nvie.com/posts/a-successful-git-branching-model/](http://nvie.com/posts/a-successful-git-branching-model/)

# License
This code is licensed under the MIT license. More information can be found in the [LICENSE](LICENSE) file contained in this repository.

# Questions? Comments? Concerns?
Please contact [FitPay Support](https://support.fit-pay.com)


# Fit Pay Internal Instructions 
### Releasing Updated SDK
Note: You must have cocoapods permissions set up to deploy. [Learn more](https://guides.cocoapods.org/making/getting-setup-with-trunk.html)

1. Run deploy script with old and new version numbers (maintain 3 digit semantic versioning)
	* Example: `sh deploy.sh 1.2.0 1.2.1`
	* You should be on develop branch
	* The script will exit early if you don't supply two arguments or have uncommitted changed
* Create a release in Github 
	* Use the following convention for name: `FitPay SDK for iOS vX.X.X`
	* Include notes using proper markdown about each major PR in the release.
		* notes can be gathered from commit messages and from github releases page (commits since this release)
* Confirm release was successful by running `pod update` in Pagare


