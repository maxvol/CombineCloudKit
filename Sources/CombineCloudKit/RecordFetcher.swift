//
//  Fetcher.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import Combine
import CloudKit

@available(macOS 10, iOS 13, *)
final class RecordFetcher {
    
    typealias Observer = AnyObserver<CKRecord>
    
    private let observer: Observer
    private let database: CKDatabase
    private let limit: Int
    
    init(observer: Observer, database: CKDatabase, query: CKQuery, limit: Int) {
        self.observer = observer
        self.database = database
        self.limit = limit
        self.fetch(query: query)
    }
    
    private func recordFetchedBlock(record: CKRecord) {
        self.observer.on(.next(record))
    }
    
    private func queryCompletionBlock(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            observer.on(.error(error))
            return
        }
        if let cursor = cursor {
            let operation = CKQueryOperation(cursor: cursor)
            self.setupAndAdd(operation: operation)
            return
        }
        observer.on(.completed)
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

