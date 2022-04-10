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
        Deferred {
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
        Deferred {
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
        Deferred {
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
                      in database: CKDatabase) -> FetchPublisher {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors        
        return FetchPublisher(
            database: database,
            query: query,
            limit: limit
        )
    }
    
    static func fetchChangesPublisher(recordZoneIDs: [CKRecordZone.ID], optionsByRecordZoneID: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions]? = nil, in database: CKDatabase) -> FetchChangesPublisher {
        FetchChangesPublisher(
            database: database,
            recordZoneIDs: recordZoneIDs,
            optionsByRecordZoneID: optionsByRecordZoneID
        )
    }
    
    static func modifyPublisher(recordsToSave records: [CKRecord]?, recordIDsToDelete recordIDs: [CKRecord.ID]?, in database: CKDatabase) -> ModifyPublisher {
        ModifyPublisher(
            database: database,
            recordsToSave: records,
            recordIDsToDelete: recordIDs
        )
    }

}
