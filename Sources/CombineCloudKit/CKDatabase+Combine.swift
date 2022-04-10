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
    // MARK:- zones

    /*
    func fetch(with recordZoneID: CKRecordZone.ID) -> Maybe<CKRecordZone> {
        return CKRecordZone.rx.fetch(with: recordZoneID, in: self.base)
    }

    func modify(recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete: [CKRecordZone.ID]?) -> Single<([CKRecordZone]?, [CKRecordZone.ID]?)> {
        return CKRecordZone.rx.modify(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete, in: self.base)
    }
     */

    func fetchChangesPublisher(previousServerChangeToken: CKServerChangeToken?, limit: Int = 99) -> AnyPublisher<ZoneEvent, Error> {
        CKRecordZone
            .fetchChangesPublisher(previousServerChangeToken: previousServerChangeToken, limit: limit, in: self)
            .eraseToAnyPublisher()
    }
    
    // MARK:- records

    func savePublisher(record: CKRecord) -> AnyPublisher<CKRecord?, Error> {
        record.savePublisher(in: self)
    }

    func fetchPublisher(with recordID: CKRecord.ID) -> AnyPublisher<CKRecord?, Error> {
        CKRecord.fetchPublisher(with: recordID, in: self)
    }

    func deletePublisher(with recordID: CKRecord.ID) -> AnyPublisher<CKRecord.ID?, Error> {
        CKRecord.deletePublisher(with: recordID, in: self)
    }

    func fetchPublisher(recordType: String, predicate: NSPredicate = NSPredicate(value: true), sortDescriptors: [NSSortDescriptor]? = nil, limit: Int = 400) -> AnyPublisher<CKRecord, Error> {
        CKRecord
            .fetchPublisher(recordType: recordType, predicate: predicate, sortDescriptors: sortDescriptors, limit: limit, in: self)
            .eraseToAnyPublisher()
    }

    func fetchChangesPublisher(recordZoneIDs: [CKRecordZone.ID], optionsByRecordZoneID: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions]? = nil) -> AnyPublisher<RecordEvent, Error> {
        CKRecord
            .fetchChangesPublisher(recordZoneIDs: recordZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID, in: self)
            .eraseToAnyPublisher()
    }
    
    func modifyPublisher(recordsToSave records: [CKRecord]?, recordIDsToDelete recordIDs: [CKRecord.ID]?) -> AnyPublisher<RecordModifyEvent, Error> {
        CKRecord
            .modifyPublisher(recordsToSave: records, recordIDsToDelete: recordIDs, in: self)
            .eraseToAnyPublisher()
    }

/*

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

