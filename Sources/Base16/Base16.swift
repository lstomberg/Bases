//
//  Base16.swift
//  Bases
//
//  Created by Matt Rubin on 4/27/16.
//  Copyright © 2016 Matt Rubin. All rights reserved.
//

import Foundation

private typealias Byte = UInt8
private typealias EncodedChar = UInt8

public enum Base16 {
    /// The size of a block before encoding, measured in bytes.
    private static let unencodedBlockSize = 1
    /// The size of a block after encoding, measured in bytes.
    private static let encodedBlockSize = 2

    private static let encodingTable: [EncodedChar] = [48, 49, 50, 51, 52, 53, 54, 55,
                                                       56, 57, 65, 66, 67, 68, 68, 70]
    private static let __: Byte? = nil
    private static let decodingTable: [Byte?] =
        [__, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __,
         __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __,
         __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __,
          0,  1,  2,  3,  4,  5,  6,  7,  8,  9, __, __, __, __, __, __,
         __, 10, 11, 12, 13, 14, 15, __, __, __, __, __, __, __, __, __,
         __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __,
         __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __,
         __, __, __, __, __, __, __, __, __, __, __, __, __, __, __, __]

    public static func encode(_ data: Data) -> String {
        let unencodedLength = data.count

        let encodedLength = unencodedLength * encodedBlockSize
        let encodedBytes = UnsafeMutablePointer<EncodedChar>.allocate(capacity: encodedLength)

        data.withUnsafeBytes { (unencodedBytes: UnsafePointer<Byte>) in
        var encodedWriteOffset = 0
        for unencodedReadOffset in stride(from: 0, to: unencodedLength, by: unencodedBlockSize) {
            let nextUnencodedByte = unencodedBytes[unencodedReadOffset]

            let bigNibble = (nextUnencodedByte & 0b11110000) >> 4
            let littleNibble = nextUnencodedByte & 0b00001111
            let bigChar = encodingTable[Int(bigNibble)]
            let littleChar = encodingTable[Int(littleNibble)]
            encodedBytes[encodedWriteOffset + 0] = bigChar
            encodedBytes[encodedWriteOffset + 1] = littleChar

            encodedWriteOffset += encodedBlockSize
        }
        }

        // The NSData object takes ownership of the allocated bytes and will handle deallocation.
        let encodedData = Data(bytesNoCopy: encodedBytes, count: encodedLength, deallocator: .free)
        let encodedString = String(data: encodedData, encoding: String.Encoding.ascii)!
        return encodedString
    }

    public static func decode(_ string: String) -> Data? {
        guard let encodedData = string.data(using: String.Encoding.ascii) else {
            return nil
        }
        let encodedLength = encodedData.count

        guard let decodedLength = unencodedLength(encodedLength: encodedLength) else {
            return nil
        }
        let decodedBytes = UnsafeMutablePointer<Byte>.allocate(capacity: decodedLength)

        encodedData.withUnsafeBytes { (encodedBytes: UnsafePointer<Byte>) in
        var decodedWriteOffset = 0
        for encodedReadOffset in stride(from: 0, to: encodedLength, by: encodedBlockSize) {
            let bigChar = encodedBytes[encodedReadOffset]
            let littleChar = encodedBytes[encodedReadOffset + 1]

            let bigNibble = decodingTable[Int(bigChar)]!
            let littleNibble = decodingTable[Int(littleChar)]!

            let decodedByte = ((bigNibble & 0b00001111) << 4) | (littleNibble & 0b00001111)
            decodedBytes[decodedWriteOffset] = decodedByte

            decodedWriteOffset += unencodedBlockSize
        }
        }

        // The NSData object takes ownership of the allocated bytes and will handle deallocation.
        let decodedData = Data(bytesNoCopy: decodedBytes, count: decodedLength, deallocator: .free)
        return decodedData
    }

    private static func unencodedLength(encodedLength: Int) -> Int? {
        guard encodedLength % encodedBlockSize == 0 else {
            return nil
        }
        return (encodedLength / encodedBlockSize) * unencodedBlockSize
    }
}
