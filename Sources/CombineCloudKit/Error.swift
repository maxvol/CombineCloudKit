//
//  Error.swift
//  
//
//  Created by Maxim Volgin on 30/06/2021.
//

@available(macOS 10, iOS 13, *)
public enum SerializationError: Error {
    case structRequired
    case unknownEntity(name: String)
    case unsupportedSubType(label: String?)
}
