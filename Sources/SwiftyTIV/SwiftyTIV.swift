import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public struct SwiftyTIV {
    public static func render(imagePath: String, 
                            maxWidth: Int = 80, 
                            maxHeight: Int = 24,
                            colorMode: ANSIColor.Flags = [.mode24Bit],
                            grayscale: Bool = false) throws -> String {
        
        let imageData = try ImageData.load(from: imagePath)
        let scaledData = imageData.scaled(maxWidth: maxWidth * 4, maxHeight: maxHeight * 8)
        return scaledData.render(colorMode: colorMode, grayscale: grayscale)
    }
    
    public static func render(imageData: ImageData,
                            maxWidth: Int = 80,
                            maxHeight: Int = 24,
                            colorMode: ANSIColor.Flags = [.mode24Bit],
                            grayscale: Bool = false) -> String {
        
        let scaledData = imageData.scaled(maxWidth: maxWidth * 4, maxHeight: maxHeight * 8)
        return scaledData.render(colorMode: colorMode, grayscale: grayscale)
    }
    
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public static func render(nsImage: NSImage,
                            maxWidth: Int = 80,
                            maxHeight: Int = 24,
                            colorMode: ANSIColor.Flags = [.mode24Bit],
                            grayscale: Bool = false) -> String? {
        
        guard let imageData = ImageData(nsImage: nsImage) else { return nil }
        return render(imageData: imageData, maxWidth: maxWidth, maxHeight: maxHeight, 
                     colorMode: colorMode, grayscale: grayscale)
    }
    #endif
    
    #if canImport(UIKit)
    public static func render(uiImage: UIImage,
                            maxWidth: Int = 80,
                            maxHeight: Int = 24,
                            colorMode: ANSIColor.Flags = [.mode24Bit],
                            grayscale: Bool = false) -> String? {
        
        guard let imageData = ImageData(uiImage: uiImage) else { return nil }
        return render(imageData: imageData, maxWidth: maxWidth, maxHeight: maxHeight,
                     colorMode: colorMode, grayscale: grayscale)
    }
    #endif
    
    public static func renderMultipleImages(imagePaths: [String],
                                          maxWidth: Int = 80,
                                          maxHeight: Int = 24,
                                          columns: Int = 4,
                                          colorMode: ANSIColor.Flags = [.mode24Bit],
                                          grayscale: Bool = false) throws -> String {
        
        var output = ""
        let thumbnailWidth = (maxWidth - 2 * (columns - 1)) / columns
        let thumbnailPixelWidth = thumbnailWidth * 4
        
        var index = 0
        while index < imagePaths.count {
            var combinedData = [UInt8]()
            var labels = [String]()
            var actualWidth = 0
            
            // Process up to 'columns' images for this row
            for col in 0..<columns {
                guard index + col < imagePaths.count else { break }
                
                let imagePath = imagePaths[index + col]
                do {
                    let imageData = try ImageData.load(from: imagePath)
                    let aspectRatio = Double(imageData.height) / Double(imageData.width)
                    let thumbnailHeight = Int(Double(thumbnailPixelWidth) * aspectRatio)
                    let scaledImage = imageData.scaled(width: thumbnailPixelWidth, height: thumbnailHeight)
                    
                    // Add to combined data (simplified - would need proper image composition)
                    if col == 0 {
                        combinedData = scaledImage.data
                        actualWidth = scaledImage.width
                    }
                    
                    let fileName = URL(fileURLWithPath: imagePath).lastPathComponent
                    labels.append(fileName)
                } catch {
                    // Skip invalid images
                    continue
                }
            }
            
            // Render the combined thumbnail row
            if !combinedData.isEmpty {
                let combinedImage = ImageData(width: actualWidth, height: combinedData.count / (actualWidth * 4), data: combinedData)
                output += combinedImage.render(colorMode: colorMode, grayscale: grayscale)
                output += labels.joined(separator: "  ") + "\n\n"
            }
            
            index += columns
        }
        
        return output
    }
}