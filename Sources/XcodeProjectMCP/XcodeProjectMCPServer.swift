import Foundation
import MCP

public enum ToolName: String, CaseIterable {
    case createXcodeproj = "create_xcodeproj"
    case listTargets = "list_targets"
    case listBuildConfigurations = "list_build_configurations"
    case listFiles = "list_files"
    case getBuildSettings = "get_build_settings"
    case addFile = "add_file"
    case removeFile = "remove_file"
    case moveFile = "move_file"
    case createGroup = "create_group"
    case addTarget = "add_target"
    case removeTarget = "remove_target"
    case addDependency = "add_dependency"
    case setBuildSetting = "set_build_setting"
    case addFramework = "add_framework"
    case addBuildPhase = "add_build_phase"
    case duplicateTarget = "duplicate_target"
    case openXcodeproj = "open_xcodeproj"
}

public struct XcodeProjectMCPServer {
    public init() {}
    
    public func run() async throws {
        let server = Server(
            name: "xcodeproj-mcp-server",
            version: "1.0.0",
            capabilities: .init(tools: .init())
        )
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
        let addFrameworkTool = AddFrameworkTool()
        let addBuildPhaseTool = AddBuildPhaseTool()
        let duplicateTargetTool = DuplicateTargetTool()
        let openXcodeprojTool = OpenXcodeprojTool()
        
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
                setBuildSettingTool.tool(),
                addFrameworkTool.tool(),
                addBuildPhaseTool.tool(),
                duplicateTargetTool.tool(),
                openXcodeprojTool.tool()
            ])
        }
        
        // Register tools/call handler
        await server.withMethodHandler(CallTool.self) { params in
            guard let toolName = ToolName(rawValue: params.name) else {
                throw MCPError.methodNotFound("Unknown tool: \(params.name)")
            }
            
            switch toolName {
            case .createXcodeproj:
                return try createXcodeprojTool.execute(arguments: params.arguments ?? [:])
            case .listTargets:
                return try listTargetsTool.execute(arguments: params.arguments ?? [:])
            case .listBuildConfigurations:
                return try listBuildConfigurationsTool.execute(arguments: params.arguments ?? [:])
            case .listFiles:
                return try listFilesTool.execute(arguments: params.arguments ?? [:])
            case .getBuildSettings:
                return try getBuildSettingsTool.execute(arguments: params.arguments ?? [:])
            case .addFile:
                return try addFileTool.execute(arguments: params.arguments ?? [:])
            case .removeFile:
                return try removeFileTool.execute(arguments: params.arguments ?? [:])
            case .moveFile:
                return try moveFileTool.execute(arguments: params.arguments ?? [:])
            case .createGroup:
                return try createGroupTool.execute(arguments: params.arguments ?? [:])
            case .addTarget:
                return try addTargetTool.execute(arguments: params.arguments ?? [:])
            case .removeTarget:
                return try removeTargetTool.execute(arguments: params.arguments ?? [:])
            case .addDependency:
                return try addDependencyTool.execute(arguments: params.arguments ?? [:])
            case .setBuildSetting:
                return try setBuildSettingTool.execute(arguments: params.arguments ?? [:])
            case .addFramework:
                return try addFrameworkTool.execute(arguments: params.arguments ?? [:])
            case .addBuildPhase:
                return try addBuildPhaseTool.execute(arguments: params.arguments ?? [:])
            case .duplicateTarget:
                return try duplicateTargetTool.execute(arguments: params.arguments ?? [:])
            case .openXcodeproj:
                return try openXcodeprojTool.execute(arguments: params.arguments ?? [:])
            }
        }
        
        // Use stdio transport
        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}