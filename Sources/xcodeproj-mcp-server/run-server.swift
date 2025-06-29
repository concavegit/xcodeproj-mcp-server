import Foundation
import Logging
import XcodeProjectMCP

@main
struct XcodeprojMCPServer {
    static func main() async throws {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = .debug
            return handler
        }

        let logger = Logger(label: "org.giginet.xcodeproj-mcp-server")

        // Get base path from command line arguments or use current directory
        let arguments = CommandLine.arguments
        let basePath: String
        if arguments.count > 1 {
            basePath = arguments[1]
        } else {
            basePath = FileManager.default.currentDirectoryPath
        }

        let server = XcodeProjectMCPServer(basePath: basePath, logger: logger)
        try await server.run()
    }
}
