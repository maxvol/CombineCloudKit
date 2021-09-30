//
//  CKRecord+Fetcher.swift
//  
//
//  Created by Maxim Volgin on 30/09/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
extension CKRecord {
    
    struct FetcherPublisher: Publisher {
        typealias Output = CKRecord
        typealias Failure = Error

        fileprivate let database: CKDatabase
        fileprivate let query: CKQuery
        fileprivate let limit: Int
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = FetcherSubscription<S>(subscriber: subscriber, publisher: self)
            subscriber.receive(subscription: subscription)
            subscription.fetch(query: self.query)
        }
        
    }
    
}

@available(macOS 10, iOS 13, *)
private extension CKRecord {
    
    class FetcherSubscription<Target: Subscriber>: Subscription where Target.Input == CKRecord, Target.Failure == Error {
            
        private var subscriber: Target?
        private let publisher: FetcherPublisher
        
        init(subscriber: Target, publisher: FetcherPublisher) {
            self.subscriber = subscriber
            self.publisher = publisher
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            subscriber = nil
        }
        
        // MARK: - private
        
        fileprivate func fetch(query: CKQuery) {
            let operation = CKQueryOperation(query: query)
            self.setupAndAdd(operation: operation)

        }

        private func setupAndAdd(operation: CKQueryOperation) {
            operation.resultsLimit = self.publisher.limit
            operation.recordFetchedBlock = self.recordFetchedBlock
            operation.queryCompletionBlock = self.queryCompletionBlock
            self.publisher.database.add(operation)
        }
        
        private func recordFetchedBlock(record: CKRecord) {
            _ = self.subscriber?.receive(record)
        }
        
        private func queryCompletionBlock(cursor: CKQueryOperation.Cursor?, error: Error?) {
            
            if let error = error {
                subscriber?.receive(completion: .failure(error))
                return
            }
            
            if let cursor = cursor {
                let operation = CKQueryOperation(cursor: cursor)
                self.setupAndAdd(operation: operation)
                return
            }
            
            subscriber?.receive(completion: .finished)
        }
        
    }
    
}

@available(macOS 10, iOS 13, *)
extension CKRecord {
    
    static func fetch(recordType: String,
                      predicate: NSPredicate = NSPredicate(value: true),
                      sortDescriptors: [NSSortDescriptor]? = nil,
                      limit: Int = 400,
                      in database: CKDatabase) -> FetcherPublisher {
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        
        return FetcherPublisher(
            database: database,
            query: query,
            limit: limit
        )
    }
    
}
