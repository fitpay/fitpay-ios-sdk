// Generated by Apple Swift version 2.2 (swiftlang-703.0.18.8 clang-703.0.31)
#pragma clang diagnostic push

#if defined(__has_include) && __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if defined(__has_include) && __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif

#if defined(__has_attribute) && __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if defined(__has_attribute) && __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_EXTRA _name : _type
# if defined(__has_feature) && __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) SWIFT_ENUM(_type, _name)
# endif
#endif
#if defined(__has_feature) && __has_feature(modules)
@import ObjectiveC;
@import WebKit;
@import Foundation;
@import Dispatch;
@import Pusher;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"

SWIFT_CLASS("_TtC9FitpaySDK11APDUCommand")
@interface APDUCommand : NSObject
@property (nonatomic, copy) NSString * _Nullable commandId;
@property (nonatomic) NSInteger groupId;
@property (nonatomic) NSInteger sequence;
@property (nonatomic, copy) NSString * _Nullable command;
@property (nonatomic, copy) NSString * _Nullable type;
@property (nonatomic, copy) NSString * _Nullable responseCode;
@property (nonatomic, copy) NSString * _Nullable responseData;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, id> * _Nonnull responseDictionary;
@end


SWIFT_CLASS("_TtC9FitpaySDK11ApduPackage")
@interface ApduPackage : NSObject
@property (nonatomic, copy) NSString * _Nullable seIdType;
@property (nonatomic, copy) NSString * _Nullable targetDeviceType;
@property (nonatomic, copy) NSString * _Nullable targetDeviceId;
@property (nonatomic, copy) NSString * _Nullable packageId;
@property (nonatomic, copy) NSString * _Nullable seId;
@property (nonatomic, copy) NSString * _Nullable targetAid;
@property (nonatomic, copy) NSArray<APDUCommand *> * _Nullable apduCommands;
@property (nonatomic, copy) NSString * _Nullable validUntil;
@property (nonatomic, copy) NSString * _Nullable apduPackageUrl;
@property (nonatomic, readonly) BOOL isExpired;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, id> * _Nonnull responseDictionary;
@end


SWIFT_CLASS("_TtC9FitpaySDK5Asset")
@interface Asset : NSObject
@end

@class Image;

SWIFT_CLASS("_TtC9FitpaySDK12CardMetadata")
@interface CardMetadata : NSObject
@property (nonatomic, copy) NSString * _Nullable labelColor;
@property (nonatomic, copy) NSString * _Nullable issuerName;
@property (nonatomic, copy) NSString * _Nullable shortDescription;
@property (nonatomic, copy) NSString * _Nullable longDescription;
@property (nonatomic, copy) NSString * _Nullable contactUrl;
@property (nonatomic, copy) NSString * _Nullable contactPhone;
@property (nonatomic, copy) NSString * _Nullable contactEmail;
@property (nonatomic, copy) NSString * _Nullable termsAndConditionsUrl;
@property (nonatomic, copy) NSString * _Nullable privacyPolicyUrl;
@property (nonatomic, copy) NSArray<Image *> * _Nullable brandLogo;
@property (nonatomic, copy) NSArray<Image *> * _Nullable cardBackground;
@property (nonatomic, copy) NSArray<Image *> * _Nullable cardBackgroundCombined;
@property (nonatomic, copy) NSArray<Image *> * _Nullable coBrandLogo;
@property (nonatomic, copy) NSArray<Image *> * _Nullable icon;
@property (nonatomic, copy) NSArray<Image *> * _Nullable issuerLogo;
@end

@class Relationship;
@class NSError;

SWIFT_CLASS("_TtC9FitpaySDK16CardRelationship")
@interface CardRelationship : NSObject
@property (nonatomic, copy) NSString * _Nullable creditCardId;
@property (nonatomic, copy) NSString * _Nullable pan;

/// Get a single relationship
///
/// \param completion RelationshipHandler closure
- (void)relationship:(void (^ _Nonnull)(Relationship * _Nullable relationship, NSError * _Nullable error))completion;
@end

@class Payload;

SWIFT_CLASS("_TtC9FitpaySDK6Commit")
@interface Commit : NSObject
@property (nonatomic, strong) Payload * _Nullable payload;
@property (nonatomic, copy) NSString * _Nullable previousCommit;
@property (nonatomic, copy) NSString * _Nullable commit;
@end

@class TermsAssetReferences;
@class DeviceRelationships;
@class VerificationMethod;

SWIFT_CLASS("_TtC9FitpaySDK10CreditCard")
@interface CreditCard : NSObject
@property (nonatomic, copy) NSString * _Nullable creditCardId;
@property (nonatomic, copy) NSString * _Nullable userId;
@property (nonatomic, copy) NSString * _Nullable created;
@property (nonatomic, copy) NSString * _Nullable cardType;
@property (nonatomic, strong) CardMetadata * _Nullable cardMetaData;
@property (nonatomic, copy) NSString * _Nullable termsAssetId;
@property (nonatomic, copy) NSArray<TermsAssetReferences *> * _Nullable termsAssetReferences;
@property (nonatomic, copy) NSString * _Nullable eligibilityExpiration;
@property (nonatomic, copy) NSArray<DeviceRelationships *> * _Nullable deviceRelationships;
@property (nonatomic, copy) NSString * _Nullable targetDeviceId;
@property (nonatomic, copy) NSString * _Nullable targetDeviceType;
@property (nonatomic, copy) NSArray<VerificationMethod *> * _Nullable verificationMethods;
@property (nonatomic, copy) NSString * _Nullable externalTokenReference;
@property (nonatomic, copy) NSString * _Nullable pan;
@property (nonatomic, copy) NSString * _Nullable cvv;
@property (nonatomic, copy) NSString * _Nullable name;
@property (nonatomic, readonly) BOOL acceptTermsAvailable;
@property (nonatomic, readonly) BOOL declineTermsAvailable;
@property (nonatomic, readonly) BOOL deactivateAvailable;
@property (nonatomic, readonly) BOOL reactivateAvailable;
@property (nonatomic, readonly) BOOL makeDefaultAvailable;
@property (nonatomic, readonly) BOOL listTransactionsAvailable;

/// Delete a single credit card from a user's profile. If you delete a card that is currently the default source, then the most recently added source will become the new default.
///
/// \param completion DeleteCreditCardHandler closure
- (void)deleteCreditCard:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/// Update the details of an existing credit card
///
/// \param name name
///
/// \param street1 address
///
/// \param street2 address
///
/// \param city city
///
/// \param state state
///
/// \param postalCode postal code
///
/// \param countryCode country code
///
/// \param completion UpdateCreditCardHandler closure
- (void)updateWithName:(NSString * _Nullable)name street1:(NSString * _Nullable)street1 street2:(NSString * _Nullable)street2 city:(NSString * _Nullable)city state:(NSString * _Nullable)state postalCode:(NSString * _Nullable)postalCode countryCode:(NSString * _Nullable)countryCode completion:(void (^ _Nonnull)(CreditCard * _Nullable creditCard, NSError * _Nullable error))completion;

/// Indicates a user has accepted the terms and conditions presented when the credit card was first added to the user's profile
///
/// \param completion AcceptTermsHandler closure
- (void)acceptTerms:(void (^ _Nonnull)(BOOL pending, CreditCard * _Nullable card, NSError * _Nullable error))completion;

/// Indicates a user has declined the terms and conditions. Once declined the credit card will be in a final state, no other actions may be taken
///
/// \param completion DeclineTermsHandler closure
- (void)declineTerms:(void (^ _Nonnull)(BOOL pending, CreditCard * _Nullable card, NSError * _Nullable error))completion;

/// Mark the credit card as the default payment instrument. If another card is currently marked as the default, the default will automatically transition to the indicated credit card
///
/// \param completion MakeDefaultHandler closure
- (void)makeDefault:(void (^ _Nonnull)(BOOL pending, CreditCard * _Nullable creditCard, NSError * _Nullable error))completion;
@end

typedef SWIFT_ENUM(NSInteger, DeviceControlState) {
  DeviceControlStateESEPowerOFF = 0x00,
  DeviceControlStateESEPowerON = 0x02,
  DeviceControlStateESEPowerReset = 0x01,
};

@class User;

SWIFT_CLASS("_TtC9FitpaySDK10DeviceInfo")
@interface DeviceInfo : NSObject
@property (nonatomic, copy) NSString * _Nullable deviceIdentifier;
@property (nonatomic, copy) NSString * _Nullable deviceName;
@property (nonatomic, copy) NSString * _Nullable deviceType;
@property (nonatomic, copy) NSString * _Nullable manufacturerName;
@property (nonatomic, copy) NSString * _Nullable serialNumber;
@property (nonatomic, copy) NSString * _Nullable modelNumber;
@property (nonatomic, copy) NSString * _Nullable hardwareRevision;
@property (nonatomic, copy) NSString * _Nullable firmwareRevision;
@property (nonatomic, copy) NSString * _Nullable softwareRevision;
@property (nonatomic, copy) NSString * _Nullable created;
@property (nonatomic, copy) NSString * _Nullable osName;
@property (nonatomic, copy) NSString * _Nullable systemId;
@property (nonatomic, copy) NSArray<CardRelationship *> * _Nullable cardRelationships;
@property (nonatomic, copy) NSString * _Nullable licenseKey;
@property (nonatomic, copy) NSString * _Nullable bdAddress;
@property (nonatomic, copy) NSString * _Nullable pairing;
@property (nonatomic, copy) NSString * _Nullable secureElementId;
@property (nonatomic, copy) NSDictionary<NSString *, id> * _Nullable metadata;
@property (nonatomic, readonly) BOOL userAvailable;
@property (nonatomic, readonly) BOOL listCommitsAvailable;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;

/// Delete a single device
///
/// \param completion DeleteDeviceHandler closure
- (void)deleteDeviceInfo:(void (^ _Nonnull)(NSError * _Nullable error))completion;

/// Update the details of an existing device (For optional? parameters use nil if field doesn't need to be updated) //TODO: consider adding default nil value
///
/// \param firmwareRevision? firmware revision
///
/// \param softwareRevision? software revision
///
/// \param completion UpdateDeviceHandler closure
- (void)update:(NSString * _Nullable)firmwareRevision softwareRevision:(NSString * _Nullable)softwareRevision completion:(void (^ _Nonnull)(DeviceInfo * _Nullable device, NSError * _Nullable error))completion;
- (void)user:(void (^ _Nonnull)(User * _Nullable user, NSError * _Nullable error))completion;
@end


SWIFT_CLASS("_TtC9FitpaySDK19DeviceRelationships")
@interface DeviceRelationships : NSObject
@property (nonatomic, copy) NSString * _Nullable deviceType;
@property (nonatomic, copy) NSString * _Nullable deviceIdentifier;
@property (nonatomic, copy) NSString * _Nullable manufacturerName;
@property (nonatomic, copy) NSString * _Nullable deviceName;
@property (nonatomic, copy) NSString * _Nullable serialNumber;
@property (nonatomic, copy) NSString * _Nullable modelNumber;
@property (nonatomic, copy) NSString * _Nullable hardwareRevision;
@property (nonatomic, copy) NSString * _Nullable firmwareRevision;
@property (nonatomic, copy) NSString * _Nullable softwareRevision;
@property (nonatomic, copy) NSString * _Nullable created;
@property (nonatomic, copy) NSString * _Nullable osName;
@property (nonatomic, copy) NSString * _Nullable systemId;
@end


SWIFT_CLASS("_TtC9FitpaySDK13EncryptionKey")
@interface EncryptionKey : NSObject
@property (nonatomic, copy) NSString * _Nullable keyId;
@property (nonatomic, copy) NSString * _Nullable created;
@property (nonatomic, copy) NSString * _Nullable serverPublicKey;
@property (nonatomic, copy) NSString * _Nullable clientPublicKey;
@end

@class PaymentDevice;
@class WKWebView;
@class WKWebViewConfiguration;
@class NSURLRequest;
@class WKUserContentController;
@class WKScriptMessage;

SWIFT_CLASS("_TtC9FitpaySDK9FPWebView")
@interface FPWebView : NSObject <WKScriptMessageHandler>
- (nonnull instancetype)initWithClientId:(NSString * _Nonnull)clientId redirectUri:(NSString * _Nonnull)redirectUri paymentDevice:(PaymentDevice * _Nonnull)paymentDevice OBJC_DESIGNATED_INITIALIZER;
- (void)setWebView:(WKWebView * _Null_unspecified)webview;

/// This returns the configuration for a WKWebView that will enable the iOS rtm bridge in the web app. Note that the value "rtmBridge" is an agreeded upon value between this and the web-view.
- (WKWebViewConfiguration * _Nonnull)wvConfig;

/// This returns the request object clients will require in order to open a WKWebView
- (NSURLRequest * _Nonnull)wvRequest;

/// This is the implementation of WKScriptMessageHandler, and handles any messages posted to the RTM bridge from the web app. The callBackId corresponds to a JS callback that will resolve a promise stored in window.RtmBridge that will be called with the result of the action once completed. It expects a message with the following format:
///
/// {
/// "callBackId": 1,
/// "data": {
/// "action": "action",
/// "data": {
/// "userId": "userId",
/// "deviceId": "userId",
/// "token": "token"
/// }
/// }
/// }
- (void)userContentController:(WKUserContentController * _Nonnull)userContentController didReceiveScriptMessage:(WKScriptMessage * _Nonnull)message;
@end


SWIFT_CLASS("_TtC9FitpaySDK11FitpayEvent")
@interface FitpayEvent : NSObject
@property (nonatomic, readonly, strong) id _Nonnull eventData;
@end


SWIFT_CLASS("_TtC9FitpaySDK18FitpayEventBinding")
@interface FitpayEventBinding : NSObject
@end


@interface FitpayEventBinding (SWIFT_EXTENSION(FitpaySDK))
@end


SWIFT_CLASS("_TtC9FitpaySDK5Image")
@interface Image : NSObject
@property (nonatomic, copy) NSString * _Nullable mimeType;
- (void)retrieveAsset:(void (^ _Nonnull)(Asset * _Nullable asset, NSError * _Nullable error))completion;
@end

enum SecurityNFCState : NSInteger;
@class NSData;

SWIFT_PROTOCOL("_TtP9FitpaySDK26PaymentDeviceBaseInterface_")
@protocol PaymentDeviceBaseInterface
- (nonnull instancetype)initWithPaymentDevice:(PaymentDevice * _Nonnull)device;
- (void)connect;
- (void)disconnect;
- (BOOL)isConnected;
- (NSError * _Nullable)writeSecurityState:(enum SecurityNFCState)state;
- (NSError * _Nullable)sendDeviceControl:(enum DeviceControlState)state;
- (NSError * _Nullable)sendNotification:(NSData * _Nonnull)notificationData;
- (void)sendAPDUData:(NSData * _Nonnull)data sequenceNumber:(uint16_t)sequenceNumber;
- (DeviceInfo * _Nullable)deviceInfo;
- (enum SecurityNFCState)nfcState;
- (void)resetToDefaultState;
@end


SWIFT_CLASS("_TtC9FitpaySDK26MockPaymentDeviceInterface")
@interface MockPaymentDeviceInterface : NSObject <PaymentDeviceBaseInterface>
- (nonnull instancetype)initWithPaymentDevice:(PaymentDevice * _Nonnull)device OBJC_DESIGNATED_INITIALIZER;
- (void)connect;
- (void)disconnect;
- (BOOL)isConnected;
- (NSError * _Nullable)writeSecurityState:(enum SecurityNFCState)state;
- (NSError * _Nullable)sendDeviceControl:(enum DeviceControlState)state;
- (NSError * _Nullable)sendNotification:(NSData * _Nonnull)notificationData;
- (void)sendAPDUData:(NSData * _Nonnull)data sequenceNumber:(uint16_t)sequenceNumber;
- (DeviceInfo * _Nullable)deviceInfo;
- (enum SecurityNFCState)nfcState;
- (void)resetToDefaultState;
- (uint64_t)getDelayTime;
@end


@interface NSData (SWIFT_EXTENSION(FitpaySDK))
@end


@interface NSData (SWIFT_EXTENSION(FitpaySDK))
@end


@interface NSData (SWIFT_EXTENSION(FitpaySDK))
@end


@interface NSError (SWIFT_EXTENSION(FitpaySDK))
@end


@interface NSJSONSerialization (SWIFT_EXTENSION(FitpaySDK))
@end


SWIFT_CLASS("_TtC9FitpaySDK7Payload")
@interface Payload : NSObject
@property (nonatomic, strong) CreditCard * _Nullable creditCard;
@end

enum PaymentDeviceEventTypes : NSInteger;

SWIFT_CLASS("_TtC9FitpaySDK13PaymentDevice")
@interface PaymentDevice : NSObject

/// Binds to the event using SyncEventType and a block as callback.
///
/// \param eventType type of event which you want to bind to
///
/// \param completion completion handler which will be called when event occurs
- (FitpayEventBinding * _Nullable)bindToEventWithEventType:(enum PaymentDeviceEventTypes)eventType completion:(void (^ _Nonnull)(FitpayEvent * _Nonnull event))completion;

/// Binds to the event using SyncEventType and a block as callback.
///
/// \param eventType type of event which you want to bind to
///
/// \param completion completion handler which will be called when event occurs
///
/// \param queue queue in which completion will be called
- (FitpayEventBinding * _Nullable)bindToEventWithEventType:(enum PaymentDeviceEventTypes)eventType completion:(void (^ _Nonnull)(FitpayEvent * _Nonnull event))completion queue:(dispatch_queue_t _Nonnull)queue;

/// Removes bind with eventType.
- (void)removeBindingWithBinding:(FitpayEventBinding * _Nonnull)binding;

/// Removes all bindings.
- (void)removeAllBindings;

/// Close connection with payment device.
- (void)disconnect;

/// Returns true if phone connected to payment device and device info was collected.
@property (nonatomic, readonly) BOOL isConnected;

/// Returns DeviceInfo if phone already connected to payment device.
@property (nonatomic, readonly, strong) DeviceInfo * _Nullable deviceInfo;

/// Returns NFC state on payment device.
@property (nonatomic, readonly) enum SecurityNFCState nfcState;

/// Allows to power on / off the secure element or to reset it in preparation for sending it APDU and other commandsю Calls OnApplicationControlReceived event on device reset?
///
/// \param state desired security state
- (NSError * _Nullable)sendDeviceControl:(enum DeviceControlState)state;

/// Sends a notification to the payment device. Payment devices can then provide visual or tactile feedback depending on their capabilities.
///
/// \param notificationData //TODO:????
- (NSError * _Nullable)sendNotification:(NSData * _Nonnull)notificationData;

/// Changes interface with payment device. Default is BLE (PaymentDeviceBLEInterface). If you want to implement your own interface than it should confirm PaymentDeviceBaseInterface protocol. Also implementation should call PaymentDevice.callCompletionForEvent() for events. Can be changed if device disconnected.
- (NSError * _Nullable)changeDeviceInterface:(id <PaymentDeviceBaseInterface> _Nonnull)interface;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


typedef SWIFT_ENUM(NSInteger, PaymentDeviceEventTypes) {
  PaymentDeviceEventTypesOnDeviceConnected = 0,
  PaymentDeviceEventTypesOnDeviceDisconnected = 1,
  PaymentDeviceEventTypesOnNotificationReceived = 2,
  PaymentDeviceEventTypesOnSecurityStateChanged = 3,
  PaymentDeviceEventTypesOnApplicationControlReceived = 4,
};


SWIFT_CLASS("_TtC9FitpaySDK12Relationship")
@interface Relationship : NSObject
@property (nonatomic, strong) DeviceInfo * _Nullable device;

/// Removes a relationship between a device and a creditCard if it exists
///
/// \param completion DeleteRelationshipHandler closure
- (void)deleteRelationship:(void (^ _Nonnull)(NSError * _Nullable error))completion;
@end

@class RestSession;

SWIFT_CLASS("_TtC9FitpaySDK10RestClient")
@interface RestClient : NSObject
- (nonnull instancetype)initWithSession:(RestSession * _Nonnull)session OBJC_DESIGNATED_INITIALIZER;

/// Creates a new user within your organization
///
/// \param firstName first name of the user
///
/// \param lastName last name of the user
///
/// \param birthDate birth date of the user in date format [YYYY-MM-DD]
///
/// \param email email of the user
///
/// \param completion CreateUserHandler closure
- (void)createUser:(NSString * _Nonnull)email password:(NSString * _Nonnull)password firstName:(NSString * _Nullable)firstName lastName:(NSString * _Nullable)lastName birthDate:(NSString * _Nullable)birthDate termsVersion:(NSString * _Nullable)termsVersion termsAccepted:(NSString * _Nullable)termsAccepted origin:(NSString * _Nullable)origin originAccountCreated:(NSString * _Nullable)originAccountCreated completion:(void (^ _Nonnull)(User * _Nullable user, NSError * _Nullable error))completion;

/// Retrieves the details of an existing user. You need only supply the unique user identifier that was returned upon user creation
///
/// \param id user id
///
/// \param completion UserHandler closure
- (void)userWithId:(NSString * _Nonnull)id completion:(void (^ _Nonnull)(User * _Nullable user, NSError * _Nullable error))completion;

/// Endpoint to allow for returning responses to APDU execution
///
/// \param package ApduPackage object
///
/// \param completion ConfirmAPDUPackageHandler closure
- (void)confirmAPDUPackage:(NSString * _Nonnull)url package:(ApduPackage * _Nonnull)package completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;
- (void)user:(NSString * _Nonnull)url completion:(void (^ _Nonnull)(User * _Nullable user, NSError * _Nullable error))completion;
@end


SWIFT_CLASS("_TtC9FitpaySDK11RestSession")
@interface RestSession : NSObject
@property (nonatomic, copy) NSString * _Nullable userId;
@property (nonatomic, readonly) BOOL isAuthorized;
- (nonnull instancetype)initWithClientId:(NSString * _Nonnull)clientId redirectUri:(NSString * _Nonnull)redirectUri authorizeURL:(NSString * _Nonnull)authorizeURL baseAPIURL:(NSString * _Nonnull)baseAPIURL OBJC_DESIGNATED_INITIALIZER;
- (void)loginWithUsername:(NSString * _Nonnull)username password:(NSString * _Nonnull)password completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;
@end


SWIFT_CLASS("_TtC9FitpaySDK9RtmConfig")
@interface RtmConfig : NSObject
@property (nonatomic, copy) NSString * _Nullable clientId;
@property (nonatomic, copy) NSString * _Nullable redirectUri;
@property (nonatomic, strong) DeviceInfo * _Nullable paymentDevice;
- (nonnull instancetype)initWithClientId:(NSString * _Nonnull)clientId redirectUri:(NSString * _Nonnull)redirectUri paymentDevice:(DeviceInfo * _Nonnull)paymentDevice OBJC_DESIGNATED_INITIALIZER;
@end

@class NSURL;

SWIFT_CLASS("_TtC9FitpaySDK10RtmSession")
@interface RtmSession : NSObject
- (nonnull instancetype)initWithAuthorizationURL:(NSURL * _Nonnull)authorizationURL OBJC_DESIGNATED_INITIALIZER;

/// Establishes websocket connection, provides URL for webview member; When webview loads URL and establishes websocket connection RTM session is ready to be used by RTM client for exchanging messages; In order to be notified when particular event occurs, callback must be set (onConnect, onParticipantsReady, onUserLogin)
///
/// \param deviceInfo payment device object
- (void)connectAndWaitForParticipants:(DeviceInfo * _Nonnull)deviceInfo;

/// Handles notification when device synchronization is required
@property (nonatomic, copy) void (^ _Nullable onSychronizationRequest)(void);
@end

@class PTPusher;
@class PTPusherConnection;

@interface RtmSession (SWIFT_EXTENSION(FitpaySDK)) <PTPusherDelegate>
- (void)pusher:(PTPusher * _Null_unspecified)pusher connectionDidConnect:(PTPusherConnection * _Null_unspecified)connection;
@end

@class PTPusherPresenceChannel;
@class PTPusherChannelMember;

@interface RtmSession (SWIFT_EXTENSION(FitpaySDK)) <PTPusherPresenceChannelDelegate>
- (void)presenceChannelDidSubscribe:(PTPusherPresenceChannel * _Null_unspecified)channel;
- (void)presenceChannel:(PTPusherPresenceChannel * _Null_unspecified)channel memberAdded:(PTPusherChannelMember * _Null_unspecified)member;
- (void)presenceChannel:(PTPusherPresenceChannel * _Null_unspecified)channel memberRemoved:(PTPusherChannelMember * _Null_unspecified)member;
@end

typedef SWIFT_ENUM(NSInteger, SecurityNFCState) {
  SecurityNFCStateDisabled = 0x00,
  SecurityNFCStateEnabled = 0x01,
  SecurityNFCStateDoNotChangeState = 0xFF,
};

typedef SWIFT_ENUM(NSInteger, SyncEventType) {
  SyncEventTypeCONNECTING_TO_DEVICE = 0x1,
  SyncEventTypeCONNECTING_TO_DEVICE_FAILED = 2,
  SyncEventTypeCONNECTING_TO_DEVICE_COMPLETED = 3,
  SyncEventTypeSYNC_STARTED = 4,
  SyncEventTypeSYNC_FAILED = 5,
  SyncEventTypeSYNC_COMPLETED = 6,
  SyncEventTypeSYNC_PROGRESS = 7,
  SyncEventTypeAPDU_COMMANDS_PROGRESS = 8,
  SyncEventTypeCOMMIT_PROCESSED = 9,
  SyncEventTypeCARD_ADDED = 10,
  SyncEventTypeCARD_DELETED = 11,
  SyncEventTypeCARD_ACTIVATED = 12,
  SyncEventTypeCARD_DEACTIVATED = 13,
  SyncEventTypeCARD_REACTIVATED = 14,
  SyncEventTypeSET_DEFAULT_CARD = 15,
  SyncEventTypeRESET_DEFAULT_CARD = 16,
};


SWIFT_CLASS("_TtC9FitpaySDK11SyncManager")
@interface SyncManager : NSObject
+ (SyncManager * _Nonnull)sharedInstance;
@property (nonatomic, strong) PaymentDevice * _Nullable paymentDevice;
@property (nonatomic, readonly) BOOL isSyncing;

/// Starts sync process with payment device. If device disconnected, than system tries to connect.
///
/// \param user user from API to whom device belongs to.
- (NSError * _Nullable)sync:(User * _Nonnull)user;

/// Binds to the sync event using SyncEventType and a block as callback.
///
/// \param eventType type of event which you want to bind to
///
/// \param completion completion handler which will be called when system receives commit with eventType
- (FitpayEventBinding * _Nullable)bindToSyncEventWithEventType:(enum SyncEventType)eventType completion:(void (^ _Nonnull)(FitpayEvent * _Nonnull event))completion;

/// Binds to the sync event using SyncEventType and a block as callback.
///
/// \param eventType type of event which you want to bind to
///
/// \param completion completion handler which will be called when system receives commit with eventType
///
/// \param queue queue in which completion will be called
- (FitpayEventBinding * _Nullable)bindToSyncEventWithEventType:(enum SyncEventType)eventType completion:(void (^ _Nonnull)(FitpayEvent * _Nonnull event))completion queue:(dispatch_queue_t _Nonnull)queue;

/// Removes bind.
- (void)removeSyncBindingWithBinding:(FitpayEventBinding * _Nonnull)binding;

/// Removes all synchronization bindings.
- (void)removeAllSyncBindings;
@end


SWIFT_CLASS("_TtC9FitpaySDK20TermsAssetReferences")
@interface TermsAssetReferences : NSObject
@property (nonatomic, copy) NSString * _Nullable mimeType;
- (void)retrieveAsset:(void (^ _Nonnull)(Asset * _Nullable asset, NSError * _Nullable error))completion;
@end

@class NSDecimalNumber;

SWIFT_CLASS("_TtC9FitpaySDK11Transaction")
@interface Transaction : NSObject
@property (nonatomic, copy) NSString * _Nullable transactionId;
@property (nonatomic, copy) NSString * _Nullable transactionType;
@property (nonatomic, strong) NSDecimalNumber * _Nullable amount;
@property (nonatomic, copy) NSString * _Nullable currencyCode;
@property (nonatomic, copy) NSString * _Nullable authorizationStatus;
@property (nonatomic, copy) NSString * _Nullable transactionTime;
@property (nonatomic, copy) NSString * _Nullable merchantName;
@property (nonatomic, copy) NSString * _Nullable merchantCode;
@property (nonatomic, copy) NSString * _Nullable merchantType;
@end


SWIFT_CLASS("_TtC9FitpaySDK4User")
@interface User : NSObject
@property (nonatomic, copy) NSString * _Nullable id;
@property (nonatomic, copy) NSString * _Nullable created;
@property (nonatomic, copy) NSString * _Nullable lastModified;
@property (nonatomic, readonly, copy) NSString * _Nullable firstName;
@property (nonatomic, readonly, copy) NSString * _Nullable lastName;
@property (nonatomic, readonly, copy) NSString * _Nullable birthDate;
@property (nonatomic, readonly, copy) NSString * _Nullable email;
@property (nonatomic, readonly) BOOL listCreditCardsAvailable;
@property (nonatomic, readonly) BOOL listDevicesAvailable;

/// Add a single credit card to a user's profile. If the card owner has no default card, then the new card will become the default.
///
/// \param pan pan
///
/// \param expMonth expiration month
///
/// \param expYear expiration year
///
/// \param cvv cvv code
///
/// \param name user name
///
/// \param street1 address
///
/// \param street2 address
///
/// \param street3 street name
///
/// \param city address
///
/// \param state state
///
/// \param postalCode postal code
///
/// \param country country
///
/// \param completion CreateCreditCardHandler closure
- (void)createCreditCardWithPan:(NSString * _Nonnull)pan expMonth:(NSInteger)expMonth expYear:(NSInteger)expYear cvv:(NSString * _Nonnull)cvv name:(NSString * _Nonnull)name street1:(NSString * _Nonnull)street1 street2:(NSString * _Nonnull)street2 street3:(NSString * _Nonnull)street3 city:(NSString * _Nonnull)city state:(NSString * _Nonnull)state postalCode:(NSString * _Nonnull)postalCode country:(NSString * _Nonnull)country completion:(void (^ _Nonnull)(CreditCard * _Nullable creditCard, NSError * _Nullable error))completion;

/// For a single user, create a new device in their profile
///
/// \param deviceType device type
///
/// \param manufacturerName manufacturer name
///
/// \param deviceName device name
///
/// \param serialNumber serial number
///
/// \param modelNumber model number
///
/// \param hardwareRevision hardware revision
///
/// \param firmwareRevision firmware revision
///
/// \param softwareRevision software revision
///
/// \param systemId system id
///
/// \param osName os name
///
/// \param licenseKey license key
///
/// \param bdAddress bd address //TODO: provide better description
///
/// \param secureElementId secure element id
///
/// \param pairing pairing date [MM-DD-YYYY]
///
/// \param completion CreateNewDeviceHandler closure
- (void)createNewDevice:(NSString * _Nonnull)deviceType manufacturerName:(NSString * _Nonnull)manufacturerName deviceName:(NSString * _Nonnull)deviceName serialNumber:(NSString * _Nonnull)serialNumber modelNumber:(NSString * _Nonnull)modelNumber hardwareRevision:(NSString * _Nonnull)hardwareRevision firmwareRevision:(NSString * _Nonnull)firmwareRevision softwareRevision:(NSString * _Nonnull)softwareRevision systemId:(NSString * _Nonnull)systemId osName:(NSString * _Nonnull)osName licenseKey:(NSString * _Nonnull)licenseKey bdAddress:(NSString * _Nonnull)bdAddress secureElementId:(NSString * _Nonnull)secureElementId pairing:(NSString * _Nonnull)pairing completion:(void (^ _Nonnull)(DeviceInfo * _Nullable device, NSError * _Nullable error))completion;
- (void)createRelationshipWithCreditCardId:(NSString * _Nonnull)creditCardId deviceId:(NSString * _Nonnull)deviceId completion:(void (^ _Nonnull)(Relationship * _Nullable relationship, NSError * _Nullable error))completion;
- (void)deleteUser:(void (^ _Nonnull)(NSError * _Nullable error))completion;
- (void)updateUserWithFirstName:(NSString * _Nullable)firstName lastName:(NSString * _Nullable)lastName birthDate:(NSString * _Nullable)birthDate originAccountCreated:(NSString * _Nullable)originAccountCreated termsAccepted:(NSString * _Nullable)termsAccepted termsVersion:(NSString * _Nullable)termsVersion completion:(void (^ _Nonnull)(User * _Nullable user, NSError * _Nullable error))completion;
@end


SWIFT_CLASS("_TtC9FitpaySDK18VerificationMethod")
@interface VerificationMethod : NSObject
@property (nonatomic, copy) NSString * _Nullable verificationId;
@property (nonatomic, copy) NSString * _Nullable value;
@property (nonatomic, copy) NSString * _Nullable created;
@property (nonatomic, copy) NSString * _Nullable lastModified;
@property (nonatomic, copy) NSString * _Nullable verified;
@property (nonatomic, copy) NSString * _Nullable verifiedEpoch;
@property (nonatomic, readonly) BOOL selectAvailable;
@property (nonatomic, readonly) BOOL verifyAvailable;
@property (nonatomic, readonly) BOOL cardAvailable;

/// When an issuer requires additional authentication to verfiy the identity of the cardholder, this indicates the user has selected the specified verification method by the indicated verificationTypeId
///
/// \param completion SelectVerificationTypeHandler closure
- (void)selectVerificationType:(void (^ _Nonnull)(BOOL pending, VerificationMethod * _Nullable verificationMethod, NSError * _Nullable error))completion;

/// If a verification method is selected that requires an entry of a pin code, this transition will be available. Not all verification methods will include a secondary verification step through the FitPay API
///
/// \param completion VerifyHandler closure
- (void)verify:(NSString * _Nonnull)verificationCode completion:(void (^ _Nonnull)(BOOL pending, VerificationMethod * _Nullable verificationMethod, NSError * _Nullable error))completion;

/// Retrieves the details of an existing credit card. You need only supply the uniqueidentifier that was returned upon creation.
///
/// \param completion CreditCardHandler closure
- (void)retrieveCreditCard:(void (^ _Nonnull)(CreditCard * _Nullable creditCard, NSError * _Nullable error))completion;
@end

#pragma clang diagnostic pop
