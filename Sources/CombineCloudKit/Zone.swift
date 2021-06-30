//
//  Zone.swift
//  
//
//  Created by Maxim Volgin on 30/06/2021.
//

import CloudKit

@available(macOS 10, iOS 13, *)
/*public*/ class Zone {
    
    public static func id(name: String) -> CKRecordZone.ID {
        return CKRecordZone.ID(zoneName: name, ownerName: CKCurrentUserDefaultName)
    }
    
    public static func create(zoneID: CKRecordZone.ID) -> CKRecordZone {
        let zone = CKRecordZone(zoneID: zoneID)
        return zone
    }
    
    public static func create(name: String) -> CKRecordZone {
        let zone = CKRecordZone(zoneName: name)
        return zone
    }
    
}
