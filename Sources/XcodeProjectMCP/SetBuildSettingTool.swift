import Foundation
import XcodeProj
import MCP
import PathKit

public struct SetBuildSettingTool: Sendable {
    public func tool() -> Tool {
        Tool(
            name: "set_build_setting",
            description: "Modify build settings for a target",
            inputSchema: .object([
                "project_path": .object([
                    "type": .string("string"),
                    "description": .string("Path to the .xcodeproj file")
                ]),
                "target_name": .object([
                    "type": .string("string"),
                    "description": .string("Name of the target to modify")
                ]),
                "configuration": .object([
                    "type": .string("string"),
                    "description": .string("Build configuration name (Debug, Release, or All)")
                ]),
                "setting_name": .object([
                    "type": .string("string"),
                    "description": .string("Name of the build setting to modify")
                ]),
                "setting_value": .object([
                    "type": .string("string"),
                    "description": .string("New value for the build setting")
                ])
            ])
        )
    }
    
    public func execute(arguments: [String: Value]) throws -> CallTool.Result {
        guard case let .string(projectPath) = arguments["project_path"],
              case let .string(targetName) = arguments["target_name"],
              case let .string(configuration) = arguments["configuration"],
              case let .string(settingName) = arguments["setting_name"],
              case let .string(settingValue) = arguments["setting_value"] else {
            throw MCPError.invalidParams("project_path, target_name, configuration, setting_name, and setting_value are required")
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let xcodeproj = try XcodeProj(path: Path(projectURL.path))
        
        // Find the target
        guard let target = xcodeproj.pbxproj.nativeTargets.first(where: { $0.name == targetName }) else {
            return CallTool.Result(
                content: [
                    .text("Target '\(targetName)' not found in project")
                ]
            )
        }
        
        // Get the build configuration list for the target
        guard let configList = target.buildConfigurationList else {
            return CallTool.Result(
                content: [
                    .text("Target '\(targetName)' has no build configuration list")
                ]
            )
        }
        
        var modifiedConfigurations: [String] = []
        
        // Handle "All" configuration
        if configuration.lowercased() == "all" {
            for config in configList.buildConfigurations {
                config.buildSettings[settingName] = .string(settingValue)
                modifiedConfigurations.append(config.name)
            }
        } else {
            // Find specific configuration
            guard let config = configList.buildConfigurations.first(where: { $0.name == configuration }) else {
                return CallTool.Result(
                    content: [
                        .text("Configuration '\(configuration)' not found for target '\(targetName)'")
                    ]
                )
            }
            
            config.buildSettings[settingName] = .string(settingValue)
            modifiedConfigurations.append(config.name)
        }
        
        // Save project
        try xcodeproj.write(pathString: projectURL.path, override: true)
        
        let configurationsText = modifiedConfigurations.joined(separator: ", ")
        return CallTool.Result(
            content: [
                .text("Successfully set '\(settingName)' to '\(settingValue)' for target '\(targetName)' in configuration(s): \(configurationsText)")
            ]
        )
    }
}