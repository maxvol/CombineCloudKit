//
//  CKSubscription+Combine.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
extension CKSubscription {
    
    func savePublisher(in database: CKDatabase) -> AnyPublisher<CKSubscription?, Error> {
        Deferred {
            Future<CKSubscription?, Error> { promise in
                database.save(self) { (subscription, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(subscription))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func fetchPublisher(with subscriptionID: String, in database: CKDatabase) -> AnyPublisher<CKSubscription?, Error> {
        Deferred {
            Future<CKSubscription?, Error> { promise in
                database.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(subscription))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func deletePublisher(with subscriptionID: String, in database: CKDatabase) -> AnyPublisher<String?, Error> {
        Deferred {
            Future<String?, Error> { promise in
                database.delete(withSubscriptionID: subscriptionID) { (subscriptionID, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(subscriptionID))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func modifyPublisher(subscriptionsToSave: [CKSubscription]?, subscriptionIDsToDelete: [String]?, in database: CKDatabase) -> AnyPublisher<([CKSubscription]?, [String]?), Error> {
        Deferred {
            Future<([CKSubscription]?, [String]?), Error> { promise in
                let operation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptionsToSave, subscriptionIDsToDelete: subscriptionIDsToDelete)
                operation.qualityOfService = .utility
                operation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success((subscriptions, deletedIds)))
                    }
                }
                database.add(operation)
            }
        }
        .eraseToAnyPublisher()
    }
    
    /*
     func fetchAllSubscriptions(completionHandler: ([CKSubscription]?, Error?) -> Void)
     Fetches all subscription objects asynchronously, with a low priority, from the current database.
     */

}
