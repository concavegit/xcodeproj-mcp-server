import Foundation
import XcodeProj
import MCP
import PathKit

public struct CreateGroupTool: Sendable {
    private let pathUtility: PathUtility
    
    public init(pathUtility: PathUtility) {
        self.pathUtility = pathUtility
    }
    
    public func tool() -> Tool {
        Tool(
            name: "create_group",
            description: "Create a new group in the project navigator",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "project_path": .object([
                        "type": .string("string"),
                        "description": .string("Path to the .xcodeproj file")
                    ]),
                    "group_name": .object([
                        "type": .string("string"),
                        "description": .string("Name of the group to create")
                    ]),
                    "parent_group": .object([
                        "type": .string("string"),
                        "description": .string("Name of the parent group (optional, defaults to main group)")
                    ]),
                    "path": .object([
                        "type": .string("string"),
                        "description": .string("Relative path for the group (optional)")
                    ])
                ]),
                "required": .array([.string("project_path"), .string("group_name")])
            ])
        )
    }
    
    public func execute(arguments: [String: Value]) throws -> CallTool.Result {
        guard case let .string(projectPath) = arguments["project_path"],
              case let .string(groupName) = arguments["group_name"] else {
            throw MCPError.invalidParams("project_path and group_name are required")
        }
        
        let parentGroupName: String?
        if case let .string(parent) = arguments["parent_group"] {
            parentGroupName = parent
        } else {
            parentGroupName = nil
        }
        
        let groupPath: String?
        if case let .string(path) = arguments["path"] {
            groupPath = path
        } else {
            groupPath = nil
        }
        
        do {
            // Resolve and validate the project path
            let resolvedProjectPath = try pathUtility.resolvePath(from: projectPath)
            let projectURL = URL(fileURLWithPath: resolvedProjectPath)
            
            let xcodeproj = try XcodeProj(path: Path(projectURL.path))
        
        // Check if group already exists
        if xcodeproj.pbxproj.groups.contains(where: { $0.name == groupName }) {
            return CallTool.Result(
                content: [
                    .text("Group '\(groupName)' already exists in project")
                ]
            )
        }
        
        // Create new group
        let newGroup = PBXGroup(sourceTree: .group, name: groupName, path: groupPath)
        xcodeproj.pbxproj.add(object: newGroup)
        
        // Find parent group
        let parentGroup: PBXGroup
        if let parentGroupName = parentGroupName {
            // Find specified parent group
            if let foundGroup = xcodeproj.pbxproj.groups.first(where: { $0.name == parentGroupName }) {
                parentGroup = foundGroup
            } else {
                throw MCPError.invalidParams("Parent group '\(parentGroupName)' not found in project")
            }
        } else {
            // Use main group
            guard let project = try xcodeproj.pbxproj.rootProject(),
                  let mainGroup = project.mainGroup else {
                throw MCPError.internalError("Main group not found in project")
            }
            parentGroup = mainGroup
        }
        
        // Add new group to parent
        parentGroup.children.append(newGroup)
        
            // Save project
            try xcodeproj.write(path: Path(projectURL.path))
            
            return CallTool.Result(
                content: [
                    .text("Successfully created group '\(groupName)' in \(parentGroupName ?? "main group")")
                ]
            )
        } catch {
            throw MCPError.internalError("Failed to create group in Xcode project: \(error.localizedDescription)")
        }
    }
}