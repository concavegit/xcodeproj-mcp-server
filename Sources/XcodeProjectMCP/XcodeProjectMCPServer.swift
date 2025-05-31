import Foundation
import MCP

public struct XcodeProjectMCPServer {
    public init() {}
    
    public func run() async throws {
        let server = Server(name: "xcodeproj-mcp-server", version: "1.0.0")
        let createXcodeprojTool = CreateXcodeprojTool()
        let listTargetsTool = ListTargetsTool()
        let listBuildConfigurationsTool = ListBuildConfigurationsTool()
        
        // Register tools/list handler
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: [
                createXcodeprojTool.tool(),
                listTargetsTool.tool(),
                listBuildConfigurationsTool.tool()
            ])
        }
        
        // Register tools/call handler
        await server.withMethodHandler(CallTool.self) { params in
            switch params.name {
            case "create_xcodeproj":
                return try createXcodeprojTool.execute(arguments: params.arguments ?? [:])
            case "list_targets":
                return try listTargetsTool.execute(arguments: params.arguments ?? [:])
            case "list_build_configurations":
                return try listBuildConfigurationsTool.execute(arguments: params.arguments ?? [:])
            default:
                throw MCPError.methodNotFound("Unknown tool: \(params.name)")
            }
        }
        
        // Use stdio transport
        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}