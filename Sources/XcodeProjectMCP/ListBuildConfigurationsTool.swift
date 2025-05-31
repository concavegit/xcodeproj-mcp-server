import Foundation
import MCP
import XcodeProj
import PathKit

public struct ListBuildConfigurationsTool: Sendable {
    public func tool() -> Tool {
        Tool(
            name: "list_build_configurations",
            description: "List all build configurations in an Xcode project",
            inputSchema: .object([
                "project_path": .object([
                    "type": .string("string"),
                    "description": .string("Path to the .xcodeproj file")
                ])
            ])
        )
    }
    
    public func execute(arguments: [String: Value]) throws -> CallTool.Result {
        guard case let .string(projectPath) = arguments["project_path"] else {
            throw MCPError.invalidParams("project_path is required")
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        
        do {
            let xcodeproj = try XcodeProj(path: Path(projectURL.path))
            let buildConfigurations = xcodeproj.pbxproj.buildConfigurations
            
            var configList: [String] = []
            for config in buildConfigurations {
                let configInfo = "- \(config.name)"
                configList.append(configInfo)
            }
            
            let result = configList.isEmpty ? "No build configurations found in the project." : configList.joined(separator: "\n")
            
            return CallTool.Result(
                content: [
                    .text("Build configurations in \(projectURL.lastPathComponent):\n\(result)")
                ]
            )
        } catch {
            throw MCPError.internalError("Failed to read Xcode project: \(error.localizedDescription)")
        }
    }
}