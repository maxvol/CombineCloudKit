//
//  Fetcher.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
final class RecordFetcher<S> where S: Subscriber, S.Failure == Error, S.Input == CKRecord {
    
    private let subscriber: S
    private let database: CKDatabase
    private let limit: Int
    
    init(subscriber: S, database: CKDatabase, query: CKQuery, limit: Int) {
        self.subscriber = subscriber
        self.database = database
        self.limit = limit
        self.fetch(query: query)
    }
    
    private func recordFetchedBlock(record: CKRecord) {
        _ = self.subscriber.receive(record)
    }
    
    private func queryCompletionBlock(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            subscriber.receive(completion: .failure(error))
            return
        }
        if let cursor = cursor {
            let operation = CKQueryOperation(cursor: cursor)
            self.setupAndAdd(operation: operation)
            return
        }
        subscriber.receive(completion: .finished)
    }
    
    private func fetch(query: CKQuery) {
        let operation = CKQueryOperation(query: query)
        self.setupAndAdd(operation: operation)

    }
    
    private func setupAndAdd(operation: CKQueryOperation) {
        operation.resultsLimit = self.limit
        operation.recordFetchedBlock = self.recordFetchedBlock
        operation.queryCompletionBlock = self.queryCompletionBlock
        self.database.add(operation)
    }

}

