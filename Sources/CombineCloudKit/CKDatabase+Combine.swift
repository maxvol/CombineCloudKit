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

    func fetchPublisher(with recordZoneID: CKRecordZone.ID) -> AnyPublisher<CKRecordZone?, Error> {
        return CKRecordZone.fetchPublisher(with: recordZoneID, in: self)
    }

    func modifyPublisher(recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete: [CKRecordZone.ID]?) -> AnyPublisher<([CKRecordZone]?, [CKRecordZone.ID]?), Error> {
        return CKRecordZone.modifyPublisher(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete, in: self)
    }

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

    // MARK:- subscriptions

    func savePublisher(subscription: CKSubscription) -> AnyPublisher<CKSubscription?, Error> {
        return subscription.savePublisher(in: self)
    }

    func fetchPublisher(with subscriptionID: String) -> AnyPublisher<CKSubscription?, Error> {
        return CKSubscription.fetchPublisher(with: subscriptionID, in: self)
    }

    func deletePublisher(with subscriptionID: String) -> AnyPublisher<String?, Error> {
        return CKSubscription.deletePublisher(with: subscriptionID, in: self)
    }

    func modifyPublisher(subscriptionsToSave: [CKSubscription]?, subscriptionIDsToDelete: [String]?) -> AnyPublisher<([CKSubscription]?, [String]?), Error> {
        return CKSubscription.modifyPublisher(subscriptionsToSave: subscriptionsToSave, subscriptionIDsToDelete: subscriptionIDsToDelete, in: self)
    }

}

