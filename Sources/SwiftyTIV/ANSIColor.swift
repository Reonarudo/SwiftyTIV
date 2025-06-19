import Foundation

public struct ANSIColor {
    public static let reset = "\u{001b}[0m"
    
    public struct Flags: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let foreground = Flags(rawValue: 1)
        public static let background = Flags(rawValue: 2)
        public static let mode256 = Flags(rawValue: 4)
        public static let mode24Bit = Flags(rawValue: 8)
    }
    
    private static let colorSteps: [Int] = [0, 0x5f, 0x87, 0xaf, 0xd7, 0xff]
    private static let grayscaleSteps: [Int] = [
        0x08, 0x12, 0x1c, 0x26, 0x30, 0x3a, 0x44, 0x4e, 0x58, 0x62, 0x6c, 0x76,
        0x80, 0x8a, 0x94, 0x9e, 0xa8, 0xb2, 0xbc, 0xc6, 0xd0, 0xda, 0xe4, 0xee
    ]
    
    private static func clamp(_ value: Int, min: Int = 0, max: Int = 255) -> Int {
        return Swift.min(Swift.max(value, min), max)
    }
    
    private static func bestIndex(_ value: Int, in options: [Int]) -> Int {
        guard let index = options.firstIndex(where: { $0 >= value }) else {
            return options.count - 1
        }
        
        if index == 0 {
            return 0
        }
        
        let val0 = options[index - 1]
        let val1 = options[index]
        
        return (value - val0 < val1 - value) ? index - 1 : index
    }
    
    private static func square(_ value: Int) -> Int {
        return value * value
    }
    
    public static func color(flags: Flags, red: Int, green: Int, blue: Int) -> String {
        let r = clamp(red)
        let g = clamp(green)
        let b = clamp(blue)
        
        let isBackground = flags.contains(.background)
        
        if !flags.contains(.mode256) {
            // 24-bit mode
            let prefix = isBackground ? "\u{001b}[48;2;" : "\u{001b}[38;2;"
            return "\(prefix)\(r);\(g);\(b)m"
        }
        
        // 256-color mode
        let rIdx = bestIndex(r, in: colorSteps)
        let gIdx = bestIndex(g, in: colorSteps)
        let bIdx = bestIndex(b, in: colorSteps)
        
        let rQ = colorSteps[rIdx]
        let gQ = colorSteps[gIdx]
        let bQ = colorSteps[bIdx]
        
        let gray = Int(Float(r) * 0.2989 + Float(g) * 0.5870 + Float(b) * 0.1140)
        let grayIdx = bestIndex(gray, in: grayscaleSteps)
        let grayQ = grayscaleSteps[grayIdx]
        
        let colorIndex: Int
        let colorError = 0.3 * Double(square(rQ - r)) + 0.59 * Double(square(gQ - g)) + 0.11 * Double(square(bQ - b))
        let grayError = 0.3 * Double(square(grayQ - r)) + 0.59 * Double(square(grayQ - g)) + 0.11 * Double(square(grayQ - b))
        
        if colorError < grayError {
            colorIndex = 16 + 36 * rIdx + 6 * gIdx + bIdx
        } else {
            colorIndex = 232 + grayIdx
        }
        
        let prefix = isBackground ? "\u{001b}[48;5;" : "\u{001b}[38;5;"
        return "\(prefix)\(colorIndex)m"
    }
}