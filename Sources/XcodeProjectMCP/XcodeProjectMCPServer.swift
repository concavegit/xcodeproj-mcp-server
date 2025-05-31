import Foundation
import MCP

public struct XcodeProjectMCPServer {
    public init() {}
    
    public func run() async throws {
        let server = Server(name: "xcodeproj-mcp-server", version: "1.0.0")
        let createXcodeprojTool = CreateXcodeprojTool()
        let listTargetsTool = ListTargetsTool()
        let listBuildConfigurationsTool = ListBuildConfigurationsTool()
        let listFilesTool = ListFilesTool()
        let getBuildSettingsTool = GetBuildSettingsTool()
        let addFileTool = AddFileTool()
        let removeFileTool = RemoveFileTool()
        let moveFileTool = MoveFileTool()
        let createGroupTool = CreateGroupTool()
        let addTargetTool = AddTargetTool()
        let removeTargetTool = RemoveTargetTool()
        let addDependencyTool = AddDependencyTool()
        let setBuildSettingTool = SetBuildSettingTool()
        
        // Register tools/list handler
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: [
                createXcodeprojTool.tool(),
                listTargetsTool.tool(),
                listBuildConfigurationsTool.tool(),
                listFilesTool.tool(),
                getBuildSettingsTool.tool(),
                addFileTool.tool(),
                removeFileTool.tool(),
                moveFileTool.tool(),
                createGroupTool.tool(),
                addTargetTool.tool(),
                removeTargetTool.tool(),
                addDependencyTool.tool(),
                setBuildSettingTool.tool()
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
            case "list_files":
                return try listFilesTool.execute(arguments: params.arguments ?? [:])
            case "get_build_settings":
                return try getBuildSettingsTool.execute(arguments: params.arguments ?? [:])
            case "add_file":
                return try addFileTool.execute(arguments: params.arguments ?? [:])
            case "remove_file":
                return try removeFileTool.execute(arguments: params.arguments ?? [:])
            case "move_file":
                return try moveFileTool.execute(arguments: params.arguments ?? [:])
            case "create_group":
                return try createGroupTool.execute(arguments: params.arguments ?? [:])
            case "add_target":
                return try addTargetTool.execute(arguments: params.arguments ?? [:])
            case "remove_target":
                return try removeTargetTool.execute(arguments: params.arguments ?? [:])
            case "add_dependency":
                return try addDependencyTool.execute(arguments: params.arguments ?? [:])
            case "set_build_setting":
                return try setBuildSettingTool.execute(arguments: params.arguments ?? [:])
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