//
//  CKRecord+Combine.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
extension CKRecord {
    
    func savePublisher(in database: CKDatabase) -> AnyPublisher<CKRecord?, Error> {
        return Deferred {
            Future<CKRecord?, Error> { promise in
                database.save(self) { (record, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(record))
                    }
                }
            }
            
        }
        .eraseToAnyPublisher()
    }

    static func fetchPublisher(with recordID: CKRecord.ID, in database: CKDatabase) -> AnyPublisher<CKRecord?, Error> {
        return Deferred {
            Future<CKRecord?, Error> { promise in
                database.fetch(withRecordID: recordID) { (record, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(record))
                    }
                }
            }
            
        }
        .eraseToAnyPublisher()
    }

    static func deletePublisher(with recordID: CKRecord.ID, in database: CKDatabase) -> AnyPublisher<CKRecord.ID?, Error> {
        return Deferred {
            Future<CKRecord.ID?, Error> { promise in
                database.delete(withRecordID: recordID) { (recordID, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(recordID))
                    }
                }
            }
            
        }
        .eraseToAnyPublisher()
    }

    static func fetchPublisher(recordType: String,
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
