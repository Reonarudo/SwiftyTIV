#!/usr/bin/env swift

import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

// Create a simple test image programmatically
func createTestImage() -> Data? {
    let width = 64
    let height = 64
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    
    var imageData = Data(count: width * height * bytesPerPixel)
    
    imageData.withUnsafeMutableBytes { rawBufferPointer in
        let buffer = rawBufferPointer.bindMemory(to: UInt8.self)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                
                // Create a simple gradient pattern
                let red = UInt8((x * 255) / width)
                let green = UInt8((y * 255) / height)
                let blue = UInt8(((x + y) * 255) / (width + height))
                
                buffer[offset] = red      // R
                buffer[offset + 1] = green // G
                buffer[offset + 2] = blue  // B
                buffer[offset + 3] = 255   // A
            }
        }
    }
    
    return imageData
}

// Example usage
print("Creating test image...")
if let testImageData = createTestImage() {
    print("Test image created with \(testImageData.count) bytes")
    print("You can now test the SwiftyTIV command line tool:")
    print("swift run stiv --help")
} else {
    print("Failed to create test image")
}