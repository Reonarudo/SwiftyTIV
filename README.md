# SwiftyTIV

*Pronounced "Steve"*

SwiftyTIV is a Swift port of Stefan Haustein's [TerminalImageViewer](https://github.com/stefanhaustein/TerminalImageViewer), providing high-quality image display in terminals using Unicode block graphics and RGB ANSI colors.

## Features

- **Enhanced Resolution**: Uses 4x8 pixel blocks mapped to Unicode characters for better image quality than traditional terminal viewers
- **Cross-Platform**: Works on macOS, iOS, and other Swift-supported platforms
- **Multiple Color Modes**: Supports both 24-bit RGB and 256-color terminal modes
- **Flexible API**: Can be used as a library or command-line tool
- **Multiple Image Support**: Displays multiple images as thumbnails with filenames

## Algorithm

SwiftyTIV implements the same core algorithm as the original TerminalImageViewer:

1. **4x8 Pixel Blocks**: Each terminal character represents a 4x8 pixel cell
2. **Color Analysis**: Finds the color channel (R, G, or B) with the biggest range in each cell
3. **Bitmap Creation**: Splits the color range and creates a bitmap for the cell
4. **Character Matching**: Compares the bitmap to Unicode block graphics characters
5. **Color Optimization**: Calculates optimal foreground and background colors

This approach provides much higher resolution than traditional methods that use single characters for larger pixel areas.

## Installation

### Swift Package Manager

Add SwiftyTIV to your project's Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SwiftyTIV", from: "1.0.0")
]
```

### Command Line Tool

Build and install the command-line tool:

```bash
git clone <repository-url>
cd SwiftyTIV
swift build -c release
cp .build/release/stiv /usr/local/bin/
```

## Usage

### Command Line

```bash
# Display a single image
stiv image.jpg

# Display with custom dimensions
stiv -w 120 -h 30 image.png

# Multiple images as thumbnails
stiv *.jpg

# Use 256-color mode
stiv --mode256 image.png

# Grayscale mode
stiv --grayscale image.jpg

# Read paths from stdin
find . -name "*.jpg" | stiv --stdin
```

### Library Usage

```swift
import SwiftyTIV

// Render an image file
do {
    let output = try SwiftyTIV.render(
        imagePath: "path/to/image.jpg",
        maxWidth: 80,
        maxHeight: 24,
        colorMode: [.mode24Bit]
    )
    print(output)
} catch {
    print("Error: \(error)")
}

// Render from image data
let imageData = ImageData(width: width, height: height, data: pixelData)
let output = SwiftyTIV.render(imageData: imageData)
print(output)

// Platform-specific image rendering
#if canImport(AppKit)
let nsImage = NSImage(contentsOfFile: "image.jpg")!
let output = SwiftyTIV.render(nsImage: nsImage)
print(output ?? "Failed to render")
#endif
```

## API Reference

### Core Types

- `SwiftyTIV`: Main interface for rendering images
- `ImageData`: Represents image pixel data in RGBA format
- `ANSIColor`: Handles ANSI color code generation
- `BlockCharacter`: Converts 4x8 pixel blocks to Unicode characters + colors

### Render Methods

```swift
// File-based rendering
static func render(imagePath: String, maxWidth: Int, maxHeight: Int, 
                  colorMode: ANSIColor.Flags, grayscale: Bool) throws -> String

// ImageData rendering
static func render(imageData: ImageData, maxWidth: Int, maxHeight: Int,
                  colorMode: ANSIColor.Flags, grayscale: Bool) -> String

// Multiple image rendering
static func renderMultipleImages(imagePaths: [String], maxWidth: Int, 
                               maxHeight: Int, columns: Int, 
                               colorMode: ANSIColor.Flags, grayscale: Bool) throws -> String
```

### Color Modes

```swift
ANSIColor.Flags.mode24Bit    // 24-bit RGB colors (default)
ANSIColor.Flags.mode256      // 256-color mode for compatibility
```

## Supported Image Formats

SwiftyTIV supports all image formats that can be loaded by the platform's native image libraries:

- **macOS**: JPEG, PNG, GIF, BMP, TIFF, and more via `NSImage`
- **iOS**: JPEG, PNG, GIF, BMP, TIFF, and more via `UIImage`
- **Other platforms**: Basic support via `CoreGraphics`

## Requirements

- Swift 5.9+
- macOS 13.0+ / iOS 16.0+ / watchOS 9.0+ / tvOS 16.0+
- Terminal with Unicode and color support

## Testing

Run the test suite:

```bash
swift test
```

## License

SwiftyTIV is available under the same dual license as the original TerminalImageViewer:

- Apache License 2.0
- GNU General Public License v3.0 or later

## Credits

- Original TerminalImageViewer by Stefan Haustein
- Swift port implementation
- Unicode block graphics character mapping
- ANSI color optimization algorithms

## Contributing

Contributions are welcome! Please feel free to submit pull requests, report bugs, or suggest features.

## Comparison with Original

This Swift port maintains full compatibility with the original TerminalImageViewer's core algorithm while providing:

- Native Swift API with modern conventions
- Cross-platform support for Apple ecosystems
- Type-safe color and image handling
- Comprehensive test coverage
- Modular architecture for library usage