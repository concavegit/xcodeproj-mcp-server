import Foundation
import XcodeProjectMCP
import Logging

@main
struct XcodeprojMCPServer {
    static func main() async throws {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return handler
        }
        
        let logger = Logger(label: "org.giginet.xcodeproj-mcp-server")
        
        let server = XcodeProjectMCPServer(logger: logger)
        try await server.run()
    }
}
