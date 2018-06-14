//
//  RestClient.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 6/11/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//

import Foundation
import Alamofire

 protocol RestClientInterface: class {
   //MARK: - Completion handlers

   //MARK: - RestClient
    /**
     Completion handler

     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
   typealias DeleteHandler = (_ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter ErrorType?:   Provides error object, or nil if no error occurs
     */
    typealias ConfirmCommitHandler = (_ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter ErrorType?:   Provides error object, or nil if no error occurs
     */
    typealias ConfirmAPDUPackageHandler = (_ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter transactions: Provides ResultCollection<Transaction> object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
     */
    typealias TransactionsHandler = (_ result: ResultCollection<Transaction>?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter transaction: Provides Transaction object, or nil if error occurs
     - parameter error:       Provides error object, or nil if no error occurs
     */
    typealias TransactionHandler = (_ transaction: Transaction?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter encryptionKey?: Provides created EncryptionKey object, or nil if error occurs
     - parameter error?:         Provides error object, or nil if no error occurs
     */
    typealias CreateEncryptionKeyHandler = (_ encryptionKey: EncryptionKey?, _ error: ErrorResponse?) -> Void

    typealias CreateKeyIfNeededHandler = CreateEncryptionKeyHandler

    /**
     Completion handler

     - parameter encryptionKey?: Provides EncryptionKey object, or nil if error occurs
     - parameter error?:         Provides error object, or nil if no error occurs
     */
    typealias EncryptionKeyHandler = (_ encryptionKey: EncryptionKey?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter error?: Provides error object, or nil if no error occurs
     */
    typealias DeleteEncryptionKeyHandler = (_ error: Error?) -> Void

    typealias CreateAuthHeaders = (_ headers: [String: String]?, _ error: ErrorResponse?) -> Void

    typealias PrepareAuthAndKeyHeaders = (_ headers: [String: String]?, _ error: ErrorResponse?) -> Void

    typealias PrepareKeyHeader = (_ headers: [String: String]?, _ error: ErrorResponse?) -> Void

    typealias IssuersHandler = (_ issuers: Issuers?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter asset: Provides Asset object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    typealias AssetsHandler = (_ asset: Asset?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter error: Provides error object, or nil if no error occurs
     */
     typealias SyncHandler = (_ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter error: Provides error object, or nil if no error occurs
     */
     typealias ResetHandler = (_ resetDeviceTask: ResetDeviceResult?, _ error: NSError?) -> Void

    /**
     Completion handler

     - parameter resultValue: Provides request object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    typealias RequestHandler = (_ resultValue: Any?, _ error: ErrorResponse?) -> Void
    //MARK: - RestClientUser

    /**
     Completion handler

     - parameter ResultCollection<User>?: Provides ResultCollection<User> object, or nil if error occurs
     - parameter ErrorType?: Provides error object, or nil if no error occurs
     */
    typealias ListUsersHandler = (ResultCollection<User>?, Error?) -> Void

    /**
     Completion handler

     - parameter user: Provides User object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    typealias UserHandler = (_ user: User?, _ error: ErrorResponse?) -> Void

    //MARK: - RestClientDevice

    /**
     Completion handler

     - parameter result: Provides ResultCollection<DeviceInfo> object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    typealias DevicesHandler = (_ result: ResultCollection<DeviceInfo>?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter device: Provides existing DeviceInfo object, or nil if error occurs
     - parameter error: Provides error object, or nil if no error occurs
     */
    typealias DeviceHandler = (_ device: DeviceInfo?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter commits: Provides ResultCollection<Commit> object, or nil if error occurs
     - parameter error:   Provides error object, or nil if no error occurs
     */
    typealias CommitsHandler = (_ result: ResultCollection<Commit>?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter commit:    Provides Commit object, or nil if error occurs
     - parameter error:     Provides error object, or nil if no error occurs
     */
    typealias CommitHandler = (_ commit: Commit?, _ error: ErrorResponse?) -> Void

    //MARK: - RestClientCreditCard

    /**
     Completion handler

     - parameter result: Provides collection of credit cards, or nil if error occurs
     - parameter error:  Provides error object, or nil if no error occurs
     */
    typealias CreditCardsHandler = (_ result: ResultCollection<CreditCard>?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter creditCard: Provides credit card object, or nil if error occurs
     - parameter error:  Provides error object, or nil if no error occurs
     */
    typealias CreditCardHandler = (_ creditCard: CreditCard?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter pending: Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that CreditCard object is nil in this case
     - parameter card?:   Provides updated CreditCard object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error?:  Provides error object, or nil if no error occurs
     */
    typealias CreditCardTransitionHandler = (_ pending: Bool, _ card: CreditCard?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter pending:            Provides pending flag, indicating that transition was accepted, but current status can be reviewed later. Note that VerificationMethod object is nil in this case
     - parameter verificationMethod: Provides VerificationMethod object, or nil if pending (Bool) flag is true or if error occurs
     - parameter error:              Provides error object, or nil if no error occurs
     */
    typealias VerifyHandler = (_ pending: Bool, _ verificationMethod: VerificationMethod?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter verificationMethod: Provides VerificationMethod object, or nil if error occurs
     - parameter error:              Provides error object, or nil if no error occurs
     */
    typealias VerifyMethodHandler = (_ verificationMethod: VerificationMethod?, _ error: ErrorResponse?) -> Void

    /**
     Completion handler

     - parameter verificationMethods: Provides VerificationMethods objects, or nil if error occurs
     - parameter error:              Provides error object, or nil if no error occurs
     */
    typealias VerifyMethodsHandler = (_ verificationMethods: ResultCollection<VerificationMethod>?, _ error: ErrorResponse?) -> Void


    //MARK: - RestClientRelationship

    /**
     Completion handler

     - parameter relationship: Provides Relationship object, or nil if error occurs
     - parameter error:        Provides error object, or nil if no error occurs
     */
    typealias RelationshipHandler = (_ relationship: Relationship?, _ error: ErrorResponse?) -> Void

    //MARK: - Methods

    //MARK: - RestClient
    func collectionItems<T>(_ url: String, completion: @escaping (_ resultCollection: ResultCollection<T>?, _ error: ErrorResponse?) -> Void) -> T?

    func confirm(_ url: String, executionResult: NonAPDUCommitState, completion: @escaping ConfirmCommitHandler)

    /**
     Endpoint to allow for returning responses to APDU execution

     - parameter package:    ApduPackage object
     - parameter completion: ConfirmAPDUPackageHandler closure
     */
    func confirmAPDUPackage(_ url: String, package: ApduPackage, completion: @escaping ConfirmAPDUPackageHandler)

    func transactions(_ url: String, limit: Int, offset: Int, completion: @escaping TransactionsHandler)

    func transactions(_ url: String, parameters: [String: Any]?, completion: @escaping TransactionsHandler)

    /**
     Creates a new encryption key pair

     - parameter clientPublicKey: client public key
     - parameter completion:      CreateEncryptionKeyHandler closure
     */
    func createEncryptionKey(clientPublicKey: String, completion: @escaping CreateEncryptionKeyHandler)

    /**
     Retrieve and individual key pair

     - parameter keyId:      key id
     - parameter completion: EncryptionKeyHandler closure
     */
    func encryptionKey(_ keyId: String, completion: @escaping EncryptionKeyHandler)

    /**
     Deletes encryption key

     - parameter keyId:      key id
     - parameter completion: DeleteEncryptionKeyHandler
     */
    func deleteEncryptionKey(_ keyId: String, completion: @escaping DeleteEncryptionKeyHandler)

    func createKeyIfNeeded(_ completion: @escaping CreateKeyIfNeededHandler)

    func createAuthHeaders(_ completion: CreateAuthHeaders)

    func skipAuthHeaders(_ completion: CreateAuthHeaders)

    func prepareAuthAndKeyHeaders(_ completion: @escaping PrepareAuthAndKeyHeaders)

    func preparKeyHeader(_ completion: @escaping PrepareAuthAndKeyHeaders)

    func issuers(completion: @escaping IssuersHandler)

    func assets(_ url: String, completion: @escaping AssetsHandler)

    func makePostCall(_ url: String, parameters: [String: Any]?, completion: @escaping SyncHandler)

    /**
     Creates a request for resetting a device

     - parameter deviceId:  device id
     - parameter userId: user id
     - parameter completion:      ResetHandler closure
     */
    func resetDeviceTasks(_ resetUrl: URL, completion: @escaping ResetHandler)

    /**
     Creates a request for getting reset status

     - parameter resetId:  reset device task id
     - parameter completion:   ResetHandler closure
     */
    func resetDeviceStatus(_ resetUrl: URL, completion: @escaping ResetHandler)

    //MARK: - RestClientUser

    /**
     Creates a new user within your organization

     - parameter firstName:  first name of the user
     - parameter lastName:   last name of the user
     - parameter birthDate:  birth date of the user in date format [YYYY-MM-DD]
     - parameter email:      email of the user
     - parameter completion: CreateUserHandler closure
     */
    func createUser(_ email: String, password: String, firstName: String?, lastName: String?,
                                 birthDate: String?, termsVersion: String?, termsAccepted: String?, origin: String?,
                                 originAccountCreated: String?, completion: @escaping UserHandler)

    /**
     Retrieves the details of an existing user. You need only supply the unique user identifier that was returned upon user creation

     - parameter id:         user id
     - parameter completion: UserHandler closure
     */
    func user(id: String, completion: @escaping UserHandler)

    /**
     Update the details of an existing user

     - parameter id:                   user id
     - parameter firstName:            first name or nil if no change is required
     - parameter lastName:             last name or nil if no change is required
     - parameter birthDate:            birth date in date format [YYYY-MM-DD] or nil if no change is required
     - parameter originAccountCreated: origin account created in date format [TODO: specify date format] or nil if no change is required
     - parameter termsAccepted:        terms accepted in date format [TODO: specify date format] or nil if no change is required
     - parameter termsVersion:         terms version formatted as [0.0.0]
     - parameter completion:           UpdateUserHandler closure
     */
    func updateUser(_ url: String,  firstName: String?, lastName: String?,
                                 birthDate: String?, originAccountCreated: String?, termsAccepted: String?,
                                 termsVersion: String?, completion: @escaping UserHandler)

    /**
     Delete a single user from your organization

     - parameter id:         user id
     - parameter completion: DeleteHandler closure
     */
    func deleteUser(_ url: String, completion: @escaping DeleteHandler)

    func user(_ url: String, completion: @escaping UserHandler)

    //MARK: - RestClientDevice

    func devices(_ url: String, limit: Int, offset: Int, completion: @escaping DevicesHandler) 

    func devices(_ url: String, parameters: [String: Any]?, completion: @escaping DevicesHandler)

    func createNewDevice(_ url: String, deviceType: String, manufacturerName: String, deviceName: String,
                         serialNumber: String?, modelNumber: String?, hardwareRevision: String?, firmwareRevision: String?,
                         softwareRevision: String?, notificationToken: String?, systemId: String?, osName: String?,
                         secureElementId: String?, casd: String?, completion: @escaping DeviceHandler)

    func deleteDevice(_ url: String, completion: @escaping DeleteHandler)

    func updateDevice(_ url: String,
                      firmwareRevision: String?,
                      softwareRevision: String?,
                      notificationToken: String?,
                      completion: @escaping DeviceHandler)

    func addDeviceProperty(_ url: String, propertyPath: String, propertyValue: String, completion: @escaping DeviceHandler)

    func commits(_ url: String, commitsAfter: String?, limit: Int, offset: Int, completion: @escaping CommitsHandler)

    func commits(_ url: String, parameters: [String: Any]?,  completion: @escaping CommitsHandler)

    func commit(_ url: String, completion: @escaping CommitHandler)

    //MARK: - RestClientCreditCard

    //MARK - Internal Functions
    func createCreditCard(_ url: String, pan: String, expMonth: Int, expYear: Int, cvv: String, name: String,
                          street1: String, street2: String, street3: String, city: String, state: String, postalCode: String, country: String,
                          completion: @escaping CreditCardHandler) 

    func creditCards(_ url: String, excludeState: [String], limit: Int, offset: Int, completion: @escaping CreditCardsHandler)

    func creditCards(_ url: String, parameters: [String: Any]?, completion: @escaping CreditCardsHandler)

    func deleteCreditCard(_ url: String, completion: @escaping DeleteHandler)

    func updateCreditCard(_ url: String, name: String?, street1: String?, street2: String?, city: String?, state: String?, postalCode: String?, countryCode: String?, completion: @escaping CreditCardHandler)

    func acceptTerms(_ url: String, completion: @escaping CreditCardTransitionHandler)

    func declineTerms(_ url: String, completion: @escaping CreditCardTransitionHandler)

    func selectVerificationType(_ url: String, completion: @escaping VerifyHandler)

    func verify(_ url: String, verificationCode: String, completion: @escaping VerifyHandler)

    func deactivate(_ url: String, causedBy: CreditCardInitiator, reason: String, completion: @escaping CreditCardTransitionHandler)

    func reactivate(_ url: String, causedBy: CreditCardInitiator, reason: String, completion: @escaping CreditCardTransitionHandler)

    func retrieveCreditCard(_ url: String, completion: @escaping CreditCardHandler)

    func makeDefault(_ url: String, completion: @escaping CreditCardTransitionHandler)
    
    func handleVerifyResponse(_ response: ErrorResponse?, completion: @escaping VerifyHandler)

    func getVerificationMethods(_ url: String, completion: @escaping VerifyMethodsHandler)

    func getVerificationMethod(_ url: String, completion: @escaping VerifyMethodHandler)

    func handleTransitionResponse(_ response: ErrorResponse?, completion: @escaping CreditCardTransitionHandler)

    //MARK: - RestClientRelationship
    /**
     Creates a relationship between a device and a creditCard

     - parameter userId:       user id
     - parameter creditCardId: credit card id
     - parameter deviceId:     device id
     - parameter completion:   CreateRelationshipHandler closure
     */
    func createRelationship(_ url: String, creditCardId: String, deviceId: String, completion: @escaping RelationshipHandler)

    func relationship(_ url: String, completion: @escaping RelationshipHandler)

    func deleteRelationship(_ url: String, completion: @escaping DeleteHandler)
}
