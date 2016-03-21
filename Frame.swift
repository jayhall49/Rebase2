//
//  Frame.swift
//  RDS Demo
//
//  Created by Jay Hall on 2/14/16.
//  Copyright © 2016 RhythmDiagnosticSystems. All rights reserved.
//

import Foundation

enum SampleType : Int {
    
    case ECG = 12
    case PPG = 3
    case ACC = 9
    case TMP = 2
    
    static let allValues  = [ECG, PPG, ACC, TMP]
    
    var groupLength : Int {
        return rawValue
    }
}

// each element corresponds to a contiguous group of samples of type SampleType and of length groupLength
//
let frameSequence : [SampleType]  = [
    .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ACC,
    .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ACC, .TMP,
    .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ACC,
    .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ACC, .TMP,
    .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ACC,
    .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ACC, .TMP,
    .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ACC,
    .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ECG, .PPG, .ACC, .TMP,
]

struct Frame {
    
    var frameIndex : Int = 0
    
    var frameData  : NSData!
    
      
    func sampleData() -> [SampleType : NSData] {
    
        var tmp = [SampleType : NSMutableData]()
        
        for sampleType in SampleType.allValues {
            tmp[sampleType] = NSMutableData(length: 0)
        }
        
        var location = 0
        
        for sampleType in frameSequence {
            let data = self.frameData.subdataWithRange(NSMakeRange(location, sampleType.groupLength))
            tmp[sampleType]!.appendData(data)
            location += sampleType.groupLength
        }
    
        var result = [SampleType : NSData]()
        
        for (sampleType, data) in tmp {
            result[sampleType] = NSData(data: data)
        }
        return result
    }
    
    func decodedSamples()->[SampleType:[UInt16]] {
        
        var tmp = [SampleType : [UInt16]]()
        
        for sampleType in SampleType.allValues {
            tmp[sampleType] = [UInt16]()
        }
        
        let data = self.sampleData()
        
        for (sampleType, data) in data {
            if sampleType == .TMP { continue }
            var location = 0
            var samples = [UInt16]()
            while location < data.length {
                let range = NSMakeRange(location, 3)
                let packedSamples   = data.subdataWithRange(range)
                samples += self.unpack(packedSamples)
                location += 3
            }
            tmp[sampleType] = samples
        }
        
        return tmp
    }
    
    func unpack(data: NSData)->[UInt16] {
        
        var bytes = [UInt8](count: data.length, repeatedValue: 0)
        
        data.getBytes(&bytes, length:data.length)
        
        let x_lo = bytes[0]
        let y_lo = bytes[2]
            
        let x_hi = bytes[1] & 0b00001111
        let y_hi = bytes[1] & 0b11110000
            
        let x : UInt16 = (UInt16(x_hi) << 8) + UInt16(x_lo)
        let y : UInt16 = (UInt16(y_hi) << 4) + UInt16(y_lo)
            
        return [x, y]
    }
    
}
