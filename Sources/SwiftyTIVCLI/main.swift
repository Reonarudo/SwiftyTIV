import Foundation
import ArgumentParser
import SwiftyTIV

@main
struct SwiftyTIVCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stiv",
        abstract: "SwiftyTIV - Display images in terminal using Unicode block graphics",
        discussion: """
        SwiftyTIV is a Swift port of TerminalImageViewer that displays images in the terminal 
        using RGB ANSI codes and Unicode block graphics characters.
        
        The program enhances resolution by mapping 4x8 pixel cells to different Unicode 
        characters using a color-based bitmap algorithm.
        """
    )
    
    @Argument(help: "Image file path(s) to display")
    var imagePaths: [String] = []
    
    @Option(name: .shortAndLong, help: "Maximum width in characters (default: 80)")
    var width: Int = 80
    
    @Option(name: .shortAndLong, help: "Maximum height in characters (default: 24)")
    var height: Int = 24
    
    @Option(name: .shortAndLong, help: "Number of columns for multiple images (default: 4)")
    var columns: Int = 4
    
    @Flag(name: .long, help: "Use 256-color mode instead of 24-bit")
    var mode256: Bool = false
    
    @Flag(name: .long, help: "Convert to grayscale")
    var grayscale: Bool = false
    
    @Flag(name: .long, help: "Read image paths from stdin")
    var stdin: Bool = false
    
    @Flag(name: .long, help: "Show help information")
    var help: Bool = false
    
    func run() throws {
        if help {
            print(SwiftyTIVCommand.helpMessage())
            return
        }
        
        var pathsToProcess: [String] = []
        
        if stdin {
            // Read paths from stdin
            while let line = readLine() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    pathsToProcess.append(trimmed)
                }
            }
        } else {
            pathsToProcess = imagePaths
        }
        
        guard !pathsToProcess.isEmpty else {
            print("Error: No image files specified.")
            print("Use --help for usage information.")
            throw ExitCode.failure
        }
        
        let colorMode: ANSIColor.Flags = mode256 ? [.mode256] : [.mode24Bit]
        
        do {
            if pathsToProcess.count == 1 {
                // Single image
                let result = try SwiftyTIV.render(
                    imagePath: pathsToProcess[0],
                    maxWidth: width,
                    maxHeight: height,
                    colorMode: colorMode,
                    grayscale: grayscale
                )
                print(result, terminator: "")
            } else {
                // Multiple images - thumbnail mode
                let result = try SwiftyTIV.renderMultipleImages(
                    imagePaths: pathsToProcess,
                    maxWidth: width,
                    maxHeight: height,
                    columns: columns,
                    colorMode: colorMode,
                    grayscale: grayscale
                )
                print(result, terminator: "")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

extension SwiftyTIVCommand {
    static func helpMessage() -> String {
        return """
        SwiftyTIV - Terminal Image Viewer
        
        A Swift port of TerminalImageViewer that displays images in the terminal using 
        RGB ANSI codes and Unicode block graphics characters.
        
        USAGE:
            stiv [OPTIONS] <image-file> [<image-file>...]
            stiv [OPTIONS] --stdin
        
        ARGUMENTS:
            <image-file>    Path to image file(s) to display
        
        OPTIONS:
            -w, --width <width>         Maximum width in characters (default: 80)
            -h, --height <height>       Maximum height in characters (default: 24)
            -c, --columns <columns>     Number of columns for multiple images (default: 4)
            --mode256                   Use 256-color mode instead of 24-bit
            --grayscale                 Convert images to grayscale
            --stdin                     Read image paths from standard input
            --help                      Show this help message
        
        EXAMPLES:
            stiv image.jpg                          # Display single image
            stiv *.jpg                              # Display multiple images as thumbnails
            stiv -w 120 -h 30 image.png             # Custom dimensions
            stiv --mode256 --grayscale image.jpg    # 256-color grayscale mode
            find . -name "*.jpg" | stiv --stdin     # Process from stdin
        
        NOTES:
            - Supports common image formats (JPEG, PNG, GIF, BMP, TIFF)
            - Uses 4x8 pixel blocks mapped to Unicode characters for enhanced resolution
            - Multiple images are displayed as thumbnails with filenames
            - Requires a terminal with Unicode and color support for best results
        """
    }
}