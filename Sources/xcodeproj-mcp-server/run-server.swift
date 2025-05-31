import Foundation
import XcodeProjectMCP

@main
struct XcodeprojMCPServer {
    static func main() async throws {
        let server = XcodeProjectMCPServer()
        try await server.run()
    }
}
