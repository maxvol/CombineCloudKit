//
//  CKRecord+Modify.swift
//  
//
//  Created by Maxim Volgin on 30/09/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
public enum RecordModifyEvent {
    case progress(CKRecord, Double) // save progress
    case result(CKRecord, Error?) // save result
    case changed([CKRecord])
    case deleted([CKRecord.ID])
}

@available(macOS 10, iOS 13, *)
extension CKRecord {
    
    struct ModifyPublisher: Publisher {
        typealias Output = RecordModifyEvent
        typealias Failure = Error

        let database: CKDatabase
        let recordsToSave: [CKRecord]?
        let recordIDsToDelete: [CKRecord.ID]?
        
        init(database: CKDatabase, recordsToSave records: [CKRecord]? = nil, recordIDsToDelete recordIDs: [CKRecord.ID]? = nil) {
            self.database = database
            self.recordsToSave = records
            self.recordIDsToDelete = recordIDs
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = ModifySubscription<S>(subscriber: subscriber, publisher: self)
            subscriber.receive(subscription: subscription)
            subscription.batch(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        }
        
    }
    
    final class ModifySubscription<Target: Subscriber>: Subscription where Target.Input == RecordModifyEvent, Target.Failure == Error {
        
        private var index = 0
        private var chunk = 400
        
        private var subscriber: Target?
        private var publisher: ModifyPublisher
        
        init(subscriber: Target, publisher: ModifyPublisher) {
            self.subscriber = subscriber
            self.publisher = publisher
        }
        
        func request(_ demand: Subscribers.Demand) {}
        
        func cancel() { subscriber = nil }

        // MARK: - custom

        fileprivate func batch(recordsToSave records: [CKRecord]?, recordIDsToDelete recordIDs: [CKRecord.ID]?) {
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: recordIDs)
            operation.perRecordProgressBlock = self.perRecordProgressBlock
            operation.perRecordCompletionBlock = self.perRecordCompletionBlock
            operation.modifyRecordsCompletionBlock = self.modifyRecordsCompletionBlock
            publisher.database.add(operation)
        }
        
        private func batch() {
            let tuple = self.tuple()
            self.batch(recordsToSave: tuple.0, recordIDsToDelete: tuple.1)
        }
        
        private var count: Int {
            Swift.max(self.publisher.recordsToSave?.count ?? 0, self.publisher.recordIDsToDelete?.count ?? 0)
        }
        
        private func until() -> Int {
            index + chunk
        }
        
        private func tuple() -> ([CKRecord]?, [CKRecord.ID]?) {
            let until = self.until()
            return (self.publisher.recordsToSave == nil ? nil : Array(self.publisher.recordsToSave![index..<until]), self.publisher.recordIDsToDelete == nil ? nil : Array(self.publisher.recordIDsToDelete![index..<until]))
        }
        
        // MARK:- callbacks
        
        // save progress
        private func perRecordProgressBlock(record: CKRecord, progress: Double) {
            _ = subscriber?.receive(.progress(record, progress))
        }
        
        // save result
        private func perRecordCompletionBlock(record: CKRecord, error: Error?) {
           _ = subscriber?.receive(.result(record, error))
        }
        
        private func modifyRecordsCompletionBlock(records: [CKRecord]?, recordIDs: [CKRecord.ID]?, error: Error?) {
            if let error = error {
                if let ckError = error as? CKError {
                    switch ckError.code {
                    case .limitExceeded:
                        self.chunk = Int(self.chunk / 2)
                        self.batch()
                        return
                    default:
                        break
                    }
                }
                subscriber?.receive(completion: .failure(error))
                return
            }
            if let records = records {
                _ = subscriber?.receive(.changed(records))
            }
            if let recordIDs = recordIDs {
                _ = subscriber?.receive(.deleted(recordIDs))
            }
            if self.until() < self.count {
                self.index += self.chunk
                self.batch()
            } else {
                subscriber?.receive(completion: .finished)
            }
        }
        
    }
        
}
