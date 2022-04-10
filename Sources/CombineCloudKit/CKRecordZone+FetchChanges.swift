//
//  CKRecordZone+FetchChanges.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
public enum ZoneEvent {
    case changed(CKRecordZone.ID)
    case deleted(CKRecordZone.ID)
    case token(CKServerChangeToken)
}

@available(macOS 10, iOS 13, *)
extension CKRecordZone {
    
    struct FetchChangesPublisher: Publisher {
        typealias Output = ZoneEvent
        typealias Failure = Error

        let database: CKDatabase
        fileprivate let limit: Int
        fileprivate var previousServerChangeToken: CKServerChangeToken?

        init(database: CKDatabase, limit: Int, previousServerChangeToken: CKServerChangeToken? = nil) {
            self.database = database
            self.limit = limit
            self.previousServerChangeToken = previousServerChangeToken
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = FetchChangesSubscription<S>(subscriber: subscriber, publisher: self)
            subscriber.receive(subscription: subscription)
            subscription.fetch()
        }
        
    }
    
    final class FetchChangesSubscription<Target: Subscriber>: Subscription where Target.Input == ZoneEvent, Target.Failure == Error {
        
        private var subscriber: Target?
        private var publisher: FetchChangesPublisher
        
        init(subscriber: Target, publisher: FetchChangesPublisher) {
            self.subscriber = subscriber
            self.publisher = publisher
        }
        
        func request(_ demand: Subscribers.Demand) {}
        
        func cancel() { subscriber = nil }
        
        // MARK:- custom
        
        fileprivate func fetch() {
            let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: self.publisher.previousServerChangeToken)
            operation.resultsLimit = self.publisher.limit
            operation.fetchAllChanges = true
            operation.qualityOfService = QualityOfService.userInitiated
            operation.changeTokenUpdatedBlock = self.changeTokenUpdatedBlock
            operation.recordZoneWithIDChangedBlock = self.recordZoneWithIDChangedBlock
            operation.recordZoneWithIDWasDeletedBlock = self.recordZoneWithIDWasDeletedBlock
            self.publisher.database.add(operation)
        }
        
        // MARK: - callbacks
        
        private func recordZoneWithIDChangedBlock(zoneID: CKRecordZone.ID) {
            _ = self.subscriber?.receive(.changed(zoneID))
        }
        
        private func recordZoneWithIDWasDeletedBlock(zoneID: CKRecordZone.ID) {
            _ = self.subscriber?.receive(.deleted(zoneID))
        }
        
        private func changeTokenUpdatedBlock(serverChangeToken: CKServerChangeToken) {
            self.publisher.previousServerChangeToken = serverChangeToken
            _ = self.subscriber?.receive(.token(serverChangeToken))
        }
        
        private func fetchDatabaseChangesCompletionBlock(serverChangeToken: CKServerChangeToken?, moreComing: Bool, error: Error?) {
            self.publisher.previousServerChangeToken = serverChangeToken
            if let error = error {
                subscriber?.receive(completion: .failure(error)) // special handling for CKErrorChangeTokenExpired (purge local cache, fetch with token=nil)
                return
            }
            if moreComing {
                self.fetch()
                return
            }
            subscriber?.receive(completion: .finished)
        }
                
    }
    
}
