//
//  CKDatabase+Combine.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
public extension CKDatabase {
/*
    // MARK:- zones

    func fetch(with recordZoneID: CKRecordZone.ID) -> Maybe<CKRecordZone> {
        return CKRecordZone.rx.fetch(with: recordZoneID, in: self.base)
    }

    func modify(recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete: [CKRecordZone.ID]?) -> Single<([CKRecordZone]?, [CKRecordZone.ID]?)> {
        return CKRecordZone.rx.modify(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete, in: self.base)
    }
    
    func fetchChanges(previousServerChangeToken: CKServerChangeToken?, limit: Int = 99) -> Observable<ZoneEvent> {
        return CKRecordZone.rx.fetchChanges(previousServerChangeToken: previousServerChangeToken, limit: limit, in: self.base)
    }
*/
    // MARK:- records

    func savePublisher(record: CKRecord) -> AnyPublisher<CKRecord?, Error> {
        return record
            .savePublisher(in: self)
    }

    func fetchPublisher(with recordID: CKRecord.ID) -> AnyPublisher<CKRecord?, Error> {
        return CKRecord
            .fetchPublisher(with: recordID, in: self)
    }

    func deletePublisher(with recordID: CKRecord.ID) -> AnyPublisher<CKRecord.ID?, Error> {
        return CKRecord
            .deletePublisher(with: recordID, in: self)
    }

    func fetchPublisher(recordType: String, predicate: NSPredicate = NSPredicate(value: true), sortDescriptors: [NSSortDescriptor]? = nil, limit: Int = 400) -> AnyPublisher<CKRecord, Error> {
        return CKRecord
            .fetchPublisher(recordType: recordType, predicate: predicate, sortDescriptors: sortDescriptors, limit: limit, in: self)
            .eraseToAnyPublisher()
    }

    //
/*
    @available(iOS 10.0, *)
    func fetchChanges(recordZoneIDs: [CKRecordZone.ID], optionsByRecordZoneID: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions]? = nil) -> Observable<RecordEvent> {
        return CKRecord.rx.fetchChanges(recordZoneIDs: recordZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID, in: self.base)
    }
    
    func modify(recordsToSave records: [CKRecord]?, recordIDsToDelete recordIDs: [CKRecord.ID]?) -> Observable<RecordModifyEvent> {
        return CKRecord.rx.modify(recordsToSave: records, recordIDsToDelete: recordIDs, in: self.base)
    }

    // MARK:- subscriptions

    func save(subscription: CKSubscription) -> Maybe<CKSubscription> {
        return subscription.rx.save(in: self.base)
    }

    func fetch(with subscriptionID: String) -> Maybe<CKSubscription> {
        return CKSubscription.rx.fetch(with: subscriptionID, in: self.base)
    }

    func delete(with subscriptionID: String) -> Maybe<String> {
        return CKSubscription.rx.delete(with: subscriptionID, in: self.base)
    }

    func modify(subscriptionsToSave: [CKSubscription]?, subscriptionIDsToDelete: [String]?) -> Single<([CKSubscription]?, [String]?)> {
        return CKSubscription.rx.modify(subscriptionsToSave: subscriptionsToSave, subscriptionIDsToDelete: subscriptionIDsToDelete, in: self.base)
    }
*/
}

