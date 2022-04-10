//
//  CKRecordZone+Combine.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
extension CKRecordZone {
    
    static func fetchPublisher(with recordZoneID: CKRecordZone.ID, in database: CKDatabase) -> AnyPublisher<CKRecordZone?, Error> {
        Deferred {
            Future<CKRecordZone?, Error> { promise in
                database.fetch(withRecordZoneID: recordZoneID) { (zone, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(zone))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
/*

    static func modify(recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete: [CKRecordZone.ID]?, in database: CKDatabase) -> Single<([CKRecordZone]?, [CKRecordZone.ID]?)> {
        return Single<([CKRecordZone]?, [CKRecordZone.ID]?)>.create { single in
            let operation = CKModifyRecordZonesOperation(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
            operation.qualityOfService = .userInitiated
            operation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                if let error = error {
                    single(.error(error))
                    return
                }
                single(.success((saved, deleted)))
            }
            database.add(operation)
            return Disposables.create()
        }
    }


*/
    
    static func fetchChangesPublisher(previousServerChangeToken: CKServerChangeToken?, limit: Int = 400, in database: CKDatabase) -> FetchChangesPublisher {
        FetchChangesPublisher(
            database: database,
            limit: limit,
            previousServerChangeToken: previousServerChangeToken
        )
    }

}
