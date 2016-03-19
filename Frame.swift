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
    
    var frameDelegate : FrameDelegateProtocol?
    
    var lastMessage: Int = -1
    
    var frameBuffer : NSMutableData = NSMutableData(length:0)!
    
    var frameBoundaryHasBeenFound : Bool = false
    
    mutating func add(message: Message) {
        
        if frameBoundaryHasBeenFound == true {
            if message.seqId != lastMessage + 1 {
                
                RLog("**** missing sequence id: \(lastMessage + 1) ****")
                
                let keys = Receiver.sharedInstance.realtimeMessageBuffer.keys
                
                for key in keys {
                    let item = Receiver.sharedInstance.realtimeMessageBuffer[key]!
                    let buf1 = item.buffer1.keys.sort(>)
                    let buf2 = item.buffer2.keys.sort(>)
                    
                    print("\(key): buf1 = \(buf1), buf2 = \(buf2)")
                }
                
                
                ConnectionManager.sharedInstance.framingError()
            }
        }
        
        lastMessage = message.seqId
        
        if frameBoundaryHasBeenFound == false {
            
            let currentFrame = (message.seqId * kMessageSize) / kFrameSize
            
            if message.seqId * kMessageSize % kFrameSize == 0 {
                
                frameBuffer.appendData(message.data)
                
                frameBoundaryHasBeenFound = true
                
                print("found frameBoundary at \(message.seqId).0")
                
                frameIndex = currentFrame
                
            } else {
                
                let nextFrame = currentFrame + 1
                
                let nextFrameStart = (nextFrame * kFrameSize) - (message.seqId * kMessageSize)
                
                if nextFrameStart < kMessageSize {
                    
                    let offset = nextFrameStart
                    
                    let data = message.data.subdataWithRange(NSMakeRange(offset, message.data.length - offset))
                    
                    frameBuffer.appendData(data)
                    
                    frameBoundaryHasBeenFound = true
                    
                    //                    print("found frameBoundary at \(message.seqId).\(offset)")
                    
                    frameIndex = nextFrame
                    
                }
                
            }
            
            
        } else {
            
            frameBuffer.appendData(message.data)
            
            if frameBuffer.length >= kFrameSize {
                
                let thisFrame = frameBuffer.subdataWithRange(NSMakeRange(0,kFrameSize))
                let nextFrame = frameBuffer.subdataWithRange(NSMakeRange(kFrameSize,frameBuffer.length - kFrameSize))
                
                frameDelegate?.appendFrame(frameIndex, thisFrame)
                
                frameBuffer.setData(nextFrame)
                frameIndex++
            }
        }
    }
    
    mutating func reset() {
        
        frameIndex = 0
        
        lastMessage = -1
        
        frameBuffer = NSMutableData(length:0)!
        
        frameBoundaryHasBeenFound = false
    }
    
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
