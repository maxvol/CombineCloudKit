//
//  RecordChangeFetcher.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
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
final class RecordChangeFetcher<S> where S: Subscriber, S.Failure == Error, S.Input == RecordEvent {
    
    private let subscriber: S
    private let database: CKDatabase
    
    private let recordZoneIDs: [CKRecordZone.ID]
    private var optionsByRecordZoneID: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions]
    
    init(subscriber: S, database: CKDatabase, recordZoneIDs: [CKRecordZone.ID], optionsByRecordZoneID: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions]? = nil) {
        self.subscriber = subscriber
        self.database = database
        self.recordZoneIDs = recordZoneIDs
        self.optionsByRecordZoneID = optionsByRecordZoneID ?? [:]
        self.fetch()
    }
    
    // MARK:- callbacks
    
    private func recordChangedBlock(record: CKRecord) {
        self.subscriber.receive(.changed(record))
    }
    
    private func recordWithIDWasDeletedBlock(recordID: CKRecord.ID, undocumented: String) {
        print("\(recordID)|\(undocumented)") // TEMP undocumented?
        self.subscriber.receive(.deleted(recordID))
    }
    
    private func recordZoneChangeTokensUpdatedBlock(zoneID: CKRecordZone.ID, serverChangeToken: CKServerChangeToken?, clientChangeTokenData: Data?) {
        self.updateToken(zoneID: zoneID, serverChangeToken: serverChangeToken)
        
        if let token = serverChangeToken {
            self.subscriber.receive(.token(zoneID, token))
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
            self.subscriber.receive(.token(zoneID, token))
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
            subscriber.receive(completion: .failure(error))
            return
        }
        subscriber.receive(completion: .finished)
    }
    
    // MARK:- custom
    
    private func updateToken(zoneID: CKRecordZone.ID, serverChangeToken: CKServerChangeToken?) {
        // token, limit, fields (nil = all, [] = no user fields)
        let options = self.optionsByRecordZoneID[zoneID] ?? CKFetchRecordZoneChangesOperation.ZoneOptions()
        options.previousServerChangeToken = serverChangeToken
        self.optionsByRecordZoneID[zoneID] = options
    }
    
    private func fetch() {
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: self.recordZoneIDs, optionsByRecordZoneID: self.optionsByRecordZoneID)
        operation.fetchAllChanges = true
        operation.qualityOfService = .userInitiated
        operation.recordChangedBlock = self.recordChangedBlock
        operation.recordWithIDWasDeletedBlock = self.recordWithIDWasDeletedBlock
        operation.recordZoneChangeTokensUpdatedBlock = self.recordZoneChangeTokensUpdatedBlock
        operation.recordZoneFetchCompletionBlock = self.recordZoneFetchCompletionBlock
        operation.fetchRecordZoneChangesCompletionBlock = self.fetchRecordZoneChangesCompletionBlock
        self.database.add(operation)
    }
    
}
