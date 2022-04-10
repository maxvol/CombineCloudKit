//
//  CKRecord+FetchChanges.swift
//  
//
//  Created by Maxim Volgin on 30/09/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
public enum RecordEvent {
    case changed(CKRecord)
    case deleted(CKRecord.ID)
    case token(CKRecordZone.ID, CKServerChangeToken)
}

@available(macOS 10, iOS 13, *)
extension CKRecord {
    
    struct FetchChangesPublisher: Publisher {
        typealias Output = RecordEvent
        typealias Failure = Error

        let database: CKDatabase
        let recordZoneIDs: [CKRecordZone.ID]
        fileprivate var optionsByRecordZoneID: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions]
        
        init(database: CKDatabase, recordZoneIDs: [CKRecordZone.ID], optionsByRecordZoneID: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions]? = nil) {
            self.database = database
            self.recordZoneIDs = recordZoneIDs
            self.optionsByRecordZoneID = optionsByRecordZoneID ?? [:]
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = FetchChangesSubscription<S>(subscriber: subscriber, publisher: self)
            subscriber.receive(subscription: subscription)
            subscription.fetch()
        }
        
    }
    
    final class FetchChangesSubscription<Target: Subscriber>: Subscription where Target.Input == RecordEvent, Target.Failure == Error {
        
        private var subscriber: Target?
        private var publisher: FetchChangesPublisher
        
        init(subscriber: Target, publisher: FetchChangesPublisher) {
            self.subscriber = subscriber
            self.publisher = publisher
        }
        
        func request(_ demand: Subscribers.Demand) {}
        
        func cancel() { subscriber = nil }
        
        // MARK: - callbacks
        
        private func recordChangedBlock(record: CKRecord) {
            _ = self.subscriber?.receive(.changed(record))
        }
        
        private func recordWithIDWasDeletedBlock(recordID: CKRecord.ID, undocumented: String) {
            print("\(recordID)|\(undocumented)") // TEMP undocumented?
            _ = self.subscriber?.receive(.deleted(recordID))
        }
        
        private func recordZoneChangeTokensUpdatedBlock(zoneID: CKRecordZone.ID, serverChangeToken: CKServerChangeToken?, clientChangeTokenData: Data?) {
            self.updateToken(zoneID: zoneID, serverChangeToken: serverChangeToken)
            
            if let token = serverChangeToken {
                _ = self.subscriber?.receive(.token(zoneID, token))
            }
            // TODO clientChangeTokenData?
        }
        
        private func recordZoneFetchCompletionBlock(zoneID: CKRecordZone.ID, serverChangeToken: CKServerChangeToken?, clientChangeTokenData: Data?, moreComing: Bool, recordZoneError: Error?) {
            // TODO clientChangeTokenData ?
            if let error = recordZoneError {
                //            subscriber.on(.error(error)) // special handling for CKErrorChangeTokenExpired (purge local cache, fetch with token=nil)
                return
            }

            self.updateToken(zoneID: zoneID, serverChangeToken: serverChangeToken)

            if let token = serverChangeToken {
                _ = self.subscriber?.receive(.token(zoneID, token))
            }
            
    //        if moreComing {
    //            self.fetch() // TODO only for this zone?
    //            return
    //        } else {
    //            if let index = self.recordZoneIDs.index(of: zoneID) {
    //                self.recordZoneIDs.remove(at: index)
    //            }
    //        }
        }
        
        private func fetchRecordZoneChangesCompletionBlock(operationError: Error?) {
            if let error = operationError {
                self.subscriber?.receive(completion: .failure(error))
                return
            }
            self.subscriber?.receive(completion: .finished)
        }
        
        // MARK:- custom
        
        private func updateToken(zoneID: CKRecordZone.ID, serverChangeToken: CKServerChangeToken?) {
            // token, limit, fields (nil = all, [] = no user fields)
            let options = self.publisher.optionsByRecordZoneID[zoneID] ?? CKFetchRecordZoneChangesOperation.ZoneOptions()
            options.previousServerChangeToken = serverChangeToken
            self.publisher.optionsByRecordZoneID[zoneID] = options
        }
        
        fileprivate  func fetch() {
            let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: self.publisher.recordZoneIDs, optionsByRecordZoneID: self.publisher.optionsByRecordZoneID)
            operation.fetchAllChanges = true
            operation.qualityOfService = QualityOfService.userInitiated
            operation.recordChangedBlock = self.recordChangedBlock
            operation.recordWithIDWasDeletedBlock = self.recordWithIDWasDeletedBlock
            operation.recordZoneChangeTokensUpdatedBlock = self.recordZoneChangeTokensUpdatedBlock
            operation.recordZoneFetchCompletionBlock = self.recordZoneFetchCompletionBlock
            operation.fetchRecordZoneChangesCompletionBlock = self.fetchRecordZoneChangesCompletionBlock
            self.publisher.database.add(operation)
        }
        
    }
    
}
