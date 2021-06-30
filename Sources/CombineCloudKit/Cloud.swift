//
//  Cloud.swift
//  
//
//  Created by Maxim Volgin on 30/06/2021.
//

import CloudKit

@available(macOS 10, iOS 13, *)
public class Cloud {
    
    public let container: CKContainer
    public let privateDB: CKDatabase
    public let sharedDB: CKDatabase
    public let publicDB: CKDatabase
    
    public init() {
        self.container = CKContainer.default()
        self.privateDB = container.privateCloudDatabase
        self.sharedDB = container.sharedCloudDatabase
        self.publicDB = container.publicCloudDatabase
    }
    
}
