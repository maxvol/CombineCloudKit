//
//  CKRecord+Combine.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
public extension CKRecord {
/*
    func save(in database: CKDatabase) -> Maybe<CKRecord> {
        return Maybe<CKRecord>.create { maybe in
            database.save(self.base) { (result, error) in
                if let error = error {
                    maybe(.error(error))
                    return
                }
                guard result != nil else {
                    maybe(.completed)
                    return
                }
                maybe(.success(result!))
            }
            return Disposables.create()
        }
    }

    static func fetch(with recordID: CKRecord.ID, in database: CKDatabase) -> Maybe<CKRecord> {
        return Maybe<CKRecord>.create { maybe in
            database.fetch(withRecordID: recordID) { (record, error) in
                if let error = error {
                    maybe(.error(error))
                    return
                }
                guard record != nil else {
                    maybe(.completed)
                    return
                }
                maybe(.success(record!))
            }
            return Disposables.create()
        }
    }

    static func delete(with recordID: CKRecord.ID, in database: CKDatabase) -> Maybe<CKRecord.ID> {
        return Maybe<CKRecord.ID>.create { maybe in
            database.delete(withRecordID: recordID) { (recordID, error) in
                if let error = error {
                    maybe(.error(error))
                    return
                }
                guard recordID != nil else {
                    maybe(.completed)
                    return
                }
                maybe(.success(recordID!))
            }
            return Disposables.create()
        }
    }
*/
    internal static func fetch(recordType: String,
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
    
/*
    static func fetchChanges(recordZoneIDs: [CKRecordZone.ID], optionsByRecordZoneID: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions]? = nil, in database: CKDatabase) -> Observable<RecordEvent> {
        return Observable.create { observer in
            _ = RecordChangeFetcher(observer: observer, database: database, recordZoneIDs: recordZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
            return Disposables.create()
        }
    }
    
    static func modify(recordsToSave records: [CKRecord]?, recordIDsToDelete recordIDs: [CKRecord.ID]?, in database: CKDatabase) -> Observable<RecordModifyEvent> {
        return Observable.create { observer in
            _ = RecordModifier(observer: observer, database: database, recordsToSave: records, recordIDsToDelete: recordIDs)
            return Disposables.create()
        }
    }
*/
}
