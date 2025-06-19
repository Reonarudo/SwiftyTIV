import XCTest
@testable import SwiftyTIV

final class SwiftyTIVTests: XCTestCase {
    func testANSIColor24Bit() {
        let colorString = ANSIColor.color(flags: [.foreground, .mode24Bit], red: 255, green: 100, blue: 50)
        XCTAssertEqual(colorString, "\u{001b}[38;2;255;100;50m")
    }
    
    func testANSIColor256() {
        let colorString = ANSIColor.color(flags: [.foreground, .mode256], red: 255, green: 100, blue: 50)
        XCTAssertTrue(colorString.hasPrefix("\u{001b}[38;5;"))
        XCTAssertTrue(colorString.hasSuffix("m"))
    }
    
    func testBlockCharacterCreation() {
        // Create a simple 4x8 pixel array (32 pixels * 4 bytes = 128 bytes)
        let testData = Array(repeating: UInt8(255), count: 128)  // All white pixels
        
        let blockChar = BlockCharacter(pixelData: testData, startPosition: 0, scanWidth: 16)
        
        // The character should be valid
        XCTAssertTrue(blockChar.character != Character("\0"))
        
        // Colors should be in valid range
        XCTAssertTrue(blockChar.foregroundColor.red >= 0 && blockChar.foregroundColor.red <= 255)
        XCTAssertTrue(blockChar.backgroundColor.red >= 0 && blockChar.backgroundColor.red <= 255)
    }
    
    func testImageDataCreation() {
        // Create a simple 8x8 RGBA image
        let width = 8
        let height = 8
        let pixelCount = width * height
        var testData = [UInt8]()
        
        // Create a gradient pattern
        for y in 0..<height {
            for x in 0..<width {
                let intensity = UInt8((x + y) * 255 / (width + height - 2))
                testData.append(intensity)     // R
                testData.append(intensity)     // G
                testData.append(intensity)     // B
                testData.append(255)           // A
            }
        }
        
        let imageData = ImageData(width: width, height: height, data: testData)
        XCTAssertEqual(imageData.width, width)
        XCTAssertEqual(imageData.height, height)
        XCTAssertEqual(imageData.data.count, pixelCount * 4)
    }
    
    func testImageScaling() {
        // Create a simple 4x4 image
        let originalWidth = 4
        let originalHeight = 4
        let testData = Array(repeating: UInt8(128), count: originalWidth * originalHeight * 4)
        
        let imageData = ImageData(width: originalWidth, height: originalHeight, data: testData)
        let scaledData = imageData.scaled(width: 8, height: 8)
        
        XCTAssertEqual(scaledData.width, 8)
        XCTAssertEqual(scaledData.height, 8)
        XCTAssertEqual(scaledData.data.count, 8 * 8 * 4)
    }
    
    func testRenderOutput() {
        // Create a simple 8x8 image
        let width = 8
        let height = 8
        let testData = Array(repeating: UInt8(128), count: width * height * 4)
        
        let imageData = ImageData(width: width, height: height, data: testData)
        let output = imageData.render(colorMode: [.mode24Bit])
        
        // Should contain ANSI escape sequences
        XCTAssertTrue(output.contains("\u{001b}"))
        // Should end with reset and newline
        XCTAssertTrue(output.hasSuffix("\u{001b}[0m\n"))
    }
}