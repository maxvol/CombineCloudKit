//
//  ZoneFetcher.swift
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
final class ZoneChangeFetcher<S> where S: Subscriber, S.Failure == Error, S.Input == ZoneEvent {
    
    private let subscriber: S
    private let database: CKDatabase
    private let limit: Int
    
    private var serverChangeToken: CKServerChangeToken?
    
    init(subscriber: S, database: CKDatabase, previousServerChangeToken: CKServerChangeToken?, limit: Int) {
        self.subscriber = subscriber
        self.database = database
        self.limit = limit
        self.serverChangeToken = previousServerChangeToken
        self.fetch()
    }
    
    // MARK:- callbacks
    
    private func recordZoneWithIDChangedBlock(zoneID: CKRecordZone.ID) {
        _ = self.subscriber.receive(.changed(zoneID))
    }
    
    private func recordZoneWithIDWasDeletedBlock(zoneID: CKRecordZone.ID) {
        _ = self.subscriber.receive(.deleted(zoneID))
    }
    
    private func changeTokenUpdatedBlock(serverChangeToken: CKServerChangeToken) {
        self.serverChangeToken = serverChangeToken
        _ = self.subscriber.receive(.token(serverChangeToken))
    }
    
    private func fetchDatabaseChangesCompletionBlock(serverChangeToken: CKServerChangeToken?, moreComing: Bool, error: Error?) {
        self.serverChangeToken = serverChangeToken
        if let error = error {
            subscriber.receive(completion: .failure(error)) // special handling for CKErrorChangeTokenExpired (purge local cache, fetch with token=nil)
            return
        }
        if moreComing {
            self.fetch()
            return
        }
        subscriber.receive(completion: .finished)
    }
    
    // MARK:- custom
    
    private func fetch() {
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: self.serverChangeToken)
        operation.resultsLimit = self.limit
        operation.fetchAllChanges = true
        operation.qualityOfService = .userInitiated
        operation.changeTokenUpdatedBlock = self.changeTokenUpdatedBlock
        operation.recordZoneWithIDChangedBlock = self.recordZoneWithIDChangedBlock
        operation.recordZoneWithIDWasDeletedBlock = self.recordZoneWithIDWasDeletedBlock
        self.database.add(operation)
    }
    
}
