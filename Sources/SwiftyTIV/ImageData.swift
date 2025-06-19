import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public struct ImageData {
    public let width: Int
    public let height: Int
    public let data: [UInt8]  // RGBA format
    
    public init(width: Int, height: Int, data: [UInt8]) {
        self.width = width
        self.height = height
        self.data = data
    }
    
    #if canImport(CoreGraphics)
    public init?(cgImage: CGImage) {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        self.width = width
        self.height = height
        self.data = pixelData
    }
    #endif
    
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public init?(nsImage: NSImage) {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        self.init(cgImage: cgImage)
    }
    #endif
    
    #if canImport(UIKit)
    public init?(uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }
    #endif
    
    public func scaled(maxWidth: Int, maxHeight: Int) -> ImageData {
        let scale = min(Double(maxWidth) / Double(width), Double(maxHeight) / Double(height))
        
        if scale >= 1.0 {
            return self
        }
        
        let newWidth = Int(Double(width) * scale)
        let newHeight = Int(Double(height) * scale)
        
        return scaled(width: newWidth, height: newHeight)
    }
    
    public func scaled(width newWidth: Int, height newHeight: Int) -> ImageData {
        var newData = [UInt8](repeating: 0, count: newWidth * newHeight * 4)
        
        let xRatio = Double(width) / Double(newWidth)
        let yRatio = Double(height) / Double(newHeight)
        
        for y in 0..<newHeight {
            for x in 0..<newWidth {
                let srcX = Int(Double(x) * xRatio)
                let srcY = Int(Double(y) * yRatio)
                
                let srcIndex = (srcY * width + srcX) * 4
                let dstIndex = (y * newWidth + x) * 4
                
                if srcIndex + 3 < data.count && dstIndex + 3 < newData.count {
                    newData[dstIndex] = data[srcIndex]         // R
                    newData[dstIndex + 1] = data[srcIndex + 1] // G
                    newData[dstIndex + 2] = data[srcIndex + 2] // B
                    newData[dstIndex + 3] = data[srcIndex + 3] // A
                }
            }
        }
        
        return ImageData(width: newWidth, height: newHeight, data: newData)
    }
    
    public func render(colorMode: ANSIColor.Flags = [.mode24Bit], grayscale: Bool = false) -> String {
        var output = ""
        
        // Process image in 4x8 blocks
        let blockWidth = 4
        let blockHeight = 8
        let bytesPerPixel = 4
        let scanWidth = width * bytesPerPixel
        
        for y in stride(from: 0, to: height - (blockHeight - 1), by: blockHeight) {
            var lastFg = ""
            var lastBg = ""
            
            for x in stride(from: 0, to: width - (blockWidth - 1), by: blockWidth) {
                let startPos = y * scanWidth + x * bytesPerPixel
                let blockChar = BlockCharacter(pixelData: data, startPosition: startPos, scanWidth: scanWidth)
                
                let fg: String
                let bg: String
                
                if grayscale {
                    let fgGray = Int(0.299 * Double(blockChar.foregroundColor.red) + 
                                   0.587 * Double(blockChar.foregroundColor.green) + 
                                   0.114 * Double(blockChar.foregroundColor.blue))
                    let bgGray = Int(0.299 * Double(blockChar.backgroundColor.red) + 
                                   0.587 * Double(blockChar.backgroundColor.green) + 
                                   0.114 * Double(blockChar.backgroundColor.blue))
                    
                    fg = ANSIColor.color(flags: ANSIColor.Flags.foreground.union(colorMode), 
                                       red: fgGray, green: fgGray, blue: fgGray)
                    bg = ANSIColor.color(flags: ANSIColor.Flags.background.union(colorMode), 
                                       red: bgGray, green: bgGray, blue: bgGray)
                } else {
                    fg = ANSIColor.color(flags: ANSIColor.Flags.foreground.union(colorMode),
                                       red: blockChar.foregroundColor.red,
                                       green: blockChar.foregroundColor.green,
                                       blue: blockChar.foregroundColor.blue)
                    bg = ANSIColor.color(flags: ANSIColor.Flags.background.union(colorMode),
                                       red: blockChar.backgroundColor.red,
                                       green: blockChar.backgroundColor.green,
                                       blue: blockChar.backgroundColor.blue)
                }
                
                if fg != lastFg {
                    output += fg
                    lastFg = fg
                }
                if bg != lastBg {
                    output += bg
                    lastBg = bg
                }
                
                output += String(blockChar.character)
            }
            
            output += ANSIColor.reset + "\n"
        }
        
        return output
    }
}

// MARK: - File Loading Extensions

extension ImageData {
    public static func load(from path: String) throws -> ImageData {
        let url = URL(fileURLWithPath: path)
        return try load(from: url)
    }
    
    public static func load(from url: URL) throws -> ImageData {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        guard let nsImage = NSImage(contentsOf: url),
              let imageData = ImageData(nsImage: nsImage) else {
            throw ImageLoadError.invalidImage
        }
        return imageData
        #elseif canImport(UIKit)
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data),
              let imageData = ImageData(uiImage: uiImage) else {
            throw ImageLoadError.invalidImage
        }
        return imageData
        #else
        throw ImageLoadError.unsupportedPlatform
        #endif
    }
}

public enum ImageLoadError: Error, LocalizedError {
    case invalidImage
    case unsupportedPlatform
    case fileNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid or unsupported image format"
        case .unsupportedPlatform:
            return "Image loading not supported on this platform"
        case .fileNotFound:
            return "Image file not found"
        }
    }
}