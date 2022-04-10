//
//  Cache.swift
//
//
//  Created by Maxim Volgin on 30/06/2021.
//

import os.log
import Foundation
import Combine
import CloudKit
import UIKit

@available(iOS 13, *)
public protocol CacheDelegate {
    // private db
    func cache(record: CKRecord)
    func deleteCache(for recordID: CKRecord.ID)
    func deleteCache(in zoneID: CKRecordZone.ID)
    // any db (via subscription)
    func query(notification: CKQueryNotification, fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
}

@available(iOS 13, *)
public final class Cache {
    static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    static let privateSubscriptionID = "\(appName).privateDatabaseSubscriptionID"
    static let sharedSubscriptionID = "\(appName).sharedDatabaseSubscriptionID"
    static let privateTokenKey = "\(appName).privateDatabaseTokenKey"
    static let sharedTokenKey = "\(appName).sharedDatabaseTokenKey"
    static let zoneTokenMapKey = "\(appName).zoneTokenMapKey"

    public let cloud = Cloud()
    public let zoneIDs: [String]
    public let local = Local()

    private let delegate: CacheDelegate
    private var cancellableSet = Set<AnyCancellable>()
    private var cachedZoneIDs: [CKRecordZone.ID] = []
//    private var missingZoneIDs: [CKRecordZoneID] = []

    public init(delegate: CacheDelegate, zoneIDs: [String]) {
        self.delegate = delegate
        self.zoneIDs = zoneIDs
    }
    
    // MARK: - standard
    
    public func applicationDidFinishLaunching(fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void = { _ in }) {
        let zones = zoneIDs.map({ Zone.create(name: $0) })

        cloud
            .privateDB
            .modifyPublisher(recordZonesToSave: zones, recordZoneIDsToDelete: nil)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    os_log("error: %@", log: Log.cache, type: .error, error.localizedDescription)
                case .finished:
                    os_log("saved", log: Log.cache, type: .info)
                }
            }, receiveValue: { (saved, deleted) in
                // no-op
            })
            .store(in: &self.cancellableSet)

        if let subscriptionId = self.local.subscriptionID(for: Cache.privateSubscriptionID) {
//            cloud
//                .privateDB
//                .rx
//                .fetch(with: subscriptionId)
            // TODO
            //                        let subscription = CKDatabaseSubscription.init(subscriptionID: Cache.privateSubscriptionID)
        } else {
            let subscription = CKDatabaseSubscription()
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo

#warning ("TODO")
// TODO:
//            cloud
//                .privateDB
//                .modify(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil).subscribe { event in
//                    switch event {
//                    case .success(let (saved, deleted)):
//                        os_log("saved", log: Log.cache, type: .info)
//                        if let subscriptions = saved {
//                            for subscription in subscriptions {
//                                self.local.save(subscriptionID: subscription.subscriptionID, for: Cache.privateSubscriptionID)
//                            }
//                        }
//                    case .error(let error):
//                        os_log("error: %@", log: Log.cache, type: .error, error.localizedDescription)
//                    }
//                }
            //        .sink()
            //        .store(in: &self.cancellableSet)
        }

        // TODO same for shared

        //let createZoneGroup = DispatchGroup()
        //createZoneGroup.enter()
        //self.createZoneGroup.leave()
//        createZoneGroup.notify(queue: DispatchQueue.global()) {
//        }

        self.fetchDatabaseChanges(fetchCompletionHandler: completionHandler)
    }

    public func applicationDidReceiveRemoteNotification(userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let dict = userInfo as! [String: NSObject]
        let notification = CKNotification(fromRemoteNotificationDictionary: dict)
        guard let notificationType = notification?.notificationType else { return }
        
        switch notificationType {
        case .query:
            let queryNotification = notification as! CKQueryNotification
            self.delegate.query(notification: queryNotification, fetchCompletionHandler: completionHandler)
        case .database:
            self.fetchDatabaseChanges(fetchCompletionHandler: completionHandler)
        case .readNotification:
            // TODO
            break
        case .recordZone:
            // TODO
            break
        default:
            // TODO
            break
        }
    }
    
    // MARK: - custom

    public func fetchDatabaseChanges(fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let token = self.local.token(for: Cache.privateTokenKey)

        cloud
            .privateDB
            .fetchChangesPublisher(previousServerChangeToken: token)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    os_log("error: %@", log: Log.cache, type: .error, error.localizedDescription)
                    completionHandler(.failed)
                case .finished:
                    if self.cachedZoneIDs.count == 0 {
                        completionHandler(.noData)
                    }
                }
            }, receiveValue: { zoneEvent in
                switch zoneEvent {
                case .changed(let zoneID):
                    os_log("changed: %@", log: Log.cache, type: .info, zoneID)
                    self.cacheChanged(zoneID: zoneID)
                case .deleted(let zoneID):
                    os_log("deleted: %@", log: Log.cache, type: .info, zoneID)
                    self.delegate.deleteCache(in: zoneID)
                case .token(let token):
                    os_log("token: %@", log: Log.cache, type: .info, token)
                    self.local.save(token: token, for: Cache.privateTokenKey)
                    self.processAndPurgeCachedZones(fetchCompletionHandler: completionHandler)
                }
            })
            .store(in: &self.cancellableSet)
    }
    
    public func fetchZoneChanges(recordZoneIDs: [CKRecordZone.ID], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        var optionsByRecordZoneID: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions] = [:]

        let tokenMap = self.local.zoneTokenMap(for: Cache.zoneTokenMapKey)
        for recordZoneID in recordZoneIDs {
            if let token = tokenMap[recordZoneID] {
                let options = CKFetchRecordZoneChangesOperation.ZoneOptions()
                options.previousServerChangeToken = token
                optionsByRecordZoneID[recordZoneID] = options
            }
        }

        cloud
            .privateDB
            .fetchChangesPublisher(recordZoneIDs: recordZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    os_log("error: %@", log: Log.cache, type: .error, error.localizedDescription)
                    completionHandler(.failed)
                case .finished:
                    completionHandler(.newData)
                }
            }, receiveValue: { recordEvent in
                switch recordEvent {
                case .changed(let record):
                    os_log("changed: %@", log: Log.cache, type: .info, record)
                    self.delegate.cache(record: record)
                case .deleted(let recordID):
                    os_log("deleted: %@", log: Log.cache, type: .info, recordID)
                    self.delegate.deleteCache(for: recordID)
                case .token(let (zoneID, token)):
                    os_log("token: %@", log: Log.cache, type: .info, "\(zoneID)->\(token)")
                    self.local.save(zoneID: zoneID, token: token, for: Cache.zoneTokenMapKey)
                }
            })
            .store(in: &self.cancellableSet)
    }
 
    public func processAndPurgeCachedZones(fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard !self.cachedZoneIDs.isEmpty else {
            completionHandler(.noData)
            return
        }

        let recordZoneIDs = self.cachedZoneIDs
        self.cachedZoneIDs = []
        self.fetchZoneChanges(recordZoneIDs: recordZoneIDs, fetchCompletionHandler: completionHandler)
    }

    public func cacheChanged(zoneID: CKRecordZone.ID) {
        self.cachedZoneIDs.append(zoneID)
    }
    
}
