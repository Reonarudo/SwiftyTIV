import Foundation

public struct BlockCharacter {
    public let character: Character
    public let foregroundColor: (red: Int, green: Int, blue: Int)
    public let backgroundColor: (red: Int, green: Int, blue: Int)
    
    private static let bitmaps: [(bitmap: UInt32, character: Character)] = [
        (0x00000000, "\u{00a0}"),  // Non-breaking space
        
        // Block graphics
        (0x0000000f, "\u{2581}"),  // lower 1/8
        (0x000000ff, "\u{2582}"),  // lower 1/4
        (0x00000fff, "\u{2583}"),
        (0x0000ffff, "\u{2584}"),  // lower 1/2
        (0x000fffff, "\u{2585}"),
        (0x00ffffff, "\u{2586}"),  // lower 3/4
        (0x0fffffff, "\u{2587}"),
        
        (0xeeeeeeee, "\u{258a}"),  // left 3/4
        (0xcccccccc, "\u{258c}"),  // left 1/2
        (0x88888888, "\u{258e}"),  // left 1/4
        
        (0x0000cccc, "\u{2596}"),  // quadrant lower left
        (0x00003333, "\u{2597}"),  // quadrant lower right
        (0xcccc0000, "\u{2598}"),  // quadrant upper left
        (0xcccc3333, "\u{259a}"),  // diagonal 1/2
        (0x33330000, "\u{259d}"),  // quadrant upper right
        
        // Line drawing subset
        (0x000ff000, "\u{2501}"),  // Heavy horizontal
        (0x66666666, "\u{2503}"),  // Heavy vertical
        
        (0x00077666, "\u{250f}"),  // Heavy down and right
        (0x000ee666, "\u{2513}"),  // Heavy down and left
        (0x66677000, "\u{2517}"),  // Heavy up and right
        (0x666ee000, "\u{251b}"),  // Heavy up and left
        
        (0x66677666, "\u{2523}"),  // Heavy vertical and right
        (0x666ee666, "\u{252b}"),  // Heavy vertical and left
        (0x000ff666, "\u{2533}"),  // Heavy down and horizontal
        (0x666ff000, "\u{253b}"),  // Heavy up and horizontal
        (0x666ff666, "\u{254b}"),  // Heavy cross
        
        (0x000cc000, "\u{2578}"),  // Bold horizontal left
        (0x00066000, "\u{2579}"),  // Bold horizontal up
        (0x00033000, "\u{257a}"),  // Bold horizontal right
        (0x00066000, "\u{257b}"),  // Bold horizontal down
        
        (0x06600660, "\u{254f}"),  // Heavy double dash vertical
        
        (0x000f0000, "\u{2500}"),  // Light horizontal
        (0x0000f000, "\u{2500}"),
        (0x44444444, "\u{2502}"),  // Light vertical
        (0x22222222, "\u{2502}"),
        
        (0x000e0000, "\u{2574}"),  // light left
        (0x0000e000, "\u{2574}"),
        (0x44440000, "\u{2575}"),  // light up
        (0x22220000, "\u{2575}"),
        (0x00030000, "\u{2576}"),  // light right
        (0x00003000, "\u{2576}"),
        (0x00004444, "\u{2577}"),  // light down
        (0x00002222, "\u{2577}"),
        
        // Misc technical
        (0x44444444, "\u{23a2}"),  // [ extension
        (0x22222222, "\u{23a5}"),  // ] extension
        
        (0x0f000000, "\u{23ba}"),  // Horizontal scanline 1
        (0x00f00000, "\u{23bb}"),  // Horizontal scanline 3
        (0x00000f00, "\u{23bc}"),  // Horizontal scanline 7
        (0x000000f0, "\u{23bd}"),  // Horizontal scanline 9
        
        // Geometrical shapes
        (0x00066000, "\u{25aa}")   // Black small square
    ]
    
    public init(pixelData: [UInt8], startPosition: Int, scanWidth: Int) {
        var minValues = [255, 255, 255]
        var maxValues = [0, 0, 0]
        var bgColor = [0, 0, 0]
        var fgColor = [0, 0, 0]
        
        // Determine min and max for each color channel in the 4x8 block
        var pos = startPosition
        for _ in 0..<8 {  // 8 rows
            for _ in 0..<4 {  // 4 columns
                for i in 0..<3 {  // RGB channels
                    let value = Int(pixelData[pos])
                    minValues[i] = min(minValues[i], value)
                    maxValues[i] = max(maxValues[i], value)
                    pos += 1
                }
                pos += 1  // Skip alpha channel
            }
            pos += scanWidth - 16  // Move to next row
        }
        
        // Find the color channel with the greatest range
        var splitIndex = 0
        var bestSplit = 0
        for i in 0..<3 {
            let range = maxValues[i] - minValues[i]
            if range > bestSplit {
                bestSplit = range
                splitIndex = i
            }
        }
        
        let splitValue = minValues[splitIndex] + bestSplit / 2
        
        // Create bitmap and compute average colors
        var bits: UInt32 = 0
        var fgCount = 0
        var bgCount = 0
        
        pos = startPosition
        for _ in 0..<8 {  // 8 rows
            for _ in 0..<4 {  // 4 columns
                bits = bits << 1
                
                let channelValue = Int(pixelData[pos + splitIndex])
                let isForeground = channelValue > splitValue
                
                if isForeground {
                    bits |= 1
                    fgCount += 1
                    for i in 0..<3 {
                        fgColor[i] += Int(pixelData[pos + i])
                    }
                } else {
                    bgCount += 1
                    for i in 0..<3 {
                        bgColor[i] += Int(pixelData[pos + i])
                    }
                }
                
                pos += 4  // Move to next pixel (skip alpha)
            }
            pos += scanWidth - 16  // Move to next row
        }
        
        // Calculate average colors
        if bgCount > 0 {
            for i in 0..<3 {
                bgColor[i] /= bgCount
            }
        }
        if fgCount > 0 {
            for i in 0..<3 {
                fgColor[i] /= fgCount
            }
        }
        
        // Find best matching character
        var bestDiff = Int.max
        var bestChar: Character = " "
        var shouldInvert = false
        
        for (bitmap, char) in Self.bitmaps {
            let diff = (bitmap ^ bits).nonzeroBitCount
            if diff < bestDiff {
                bestChar = char
                bestDiff = diff
                shouldInvert = false
            }
            
            let invertedDiff = (~bitmap ^ bits).nonzeroBitCount
            if invertedDiff < bestDiff {
                bestChar = char
                bestDiff = invertedDiff
                shouldInvert = true
            }
        }
        
        // Use shade characters for poor matches
        if bestDiff > 10 {
            let shadeChars: [Character] = [" ", "\u{2591}", "\u{2592}", "\u{2593}", "\u{2588}"]
            let shadeIndex = min(4, fgCount * 5 / 32)
            bestChar = shadeChars[shadeIndex]
            shouldInvert = false
        }
        
        // Set final values
        self.character = bestChar
        if shouldInvert {
            self.foregroundColor = (bgColor[0], bgColor[1], bgColor[2])
            self.backgroundColor = (fgColor[0], fgColor[1], fgColor[2])
        } else {
            self.foregroundColor = (fgColor[0], fgColor[1], fgColor[2])
            self.backgroundColor = (bgColor[0], bgColor[1], bgColor[2])
        }
    }
}