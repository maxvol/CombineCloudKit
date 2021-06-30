//
//  Log.swift
//  
//
//  Created by Maxim Volgin on 30/06/2021.
//

import os.log

@available(macOS 10, iOS 13, *)
struct Log {
    fileprivate static let subsystem: String = "CombineCloudKit"
    
    static let cache = OSLog(subsystem: subsystem, category: "cache")
}
