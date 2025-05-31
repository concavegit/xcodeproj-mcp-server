import Foundation
import XcodeProjectMCP

struct XcodeprojMCPServer {
    static func main() async throws {
        let server = XcodeProjectMCPServer()
        try await server.run()
    }
}
