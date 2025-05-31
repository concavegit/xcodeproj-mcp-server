import Foundation
import ModelContextProtocol
import XcodeProj

@main
struct XcodeprojMCPServer {
    static func main() async throws {
        let server = MCPServer()
        
        // Register tools
        server.registerTool(CreateXcodeprojTool())
        
        try await server.run()
    }
}
