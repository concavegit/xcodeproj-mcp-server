import Foundation
import MCP
import PathKit
import XcodeProj

public struct ListGroupsTool: Sendable {
    private let pathUtility: PathUtility

    public init(pathUtility: PathUtility) {
        self.pathUtility = pathUtility
    }

    public func tool() -> Tool {
        Tool(
            name: "list_groups",
            description: "List all groups in an Xcode project, optionally filtered by target",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "project_path": .object([
                        "type": .string("string"),
                        "description": .string(
                            "Path to the .xcodeproj file (relative to current directory)"),
                    ]),
                    "target_name": .object([
                        "type": .string("string"),
                        "description": .string(
                            "Name of the target to filter groups by (optional)"),
                    ]),
                ]),
                "required": .array([.string("project_path")]),
            ])
        )
    }

    public func execute(arguments: [String: Value]) throws -> CallTool.Result {
        guard case let .string(projectPath) = arguments["project_path"] else {
            throw MCPError.invalidParams("project_path is required")
        }

        let targetName: String?
        if case let .string(target) = arguments["target_name"] {
            targetName = target
        } else {
            targetName = nil
        }

        do {
            // Resolve and validate the path
            let resolvedPath = try pathUtility.resolvePath(from: projectPath)
            let projectURL = URL(filePath: resolvedPath)

            let xcodeproj = try XcodeProj(path: Path(projectURL.path))

            // Get the root project and main group
            guard let project = try xcodeproj.pbxproj.rootProject(),
                let mainGroup = project.mainGroup
            else {
                throw MCPError.internalError("Main group not found in project")
            }

            var groupList: [String] = []

            if let targetName = targetName {
                // Find the target by name
                guard
                    let target = xcodeproj.pbxproj.nativeTargets.first(where: {
                        $0.name == targetName
                    })
                else {
                    throw MCPError.invalidParams("Target '\(targetName)' not found in project")
                }

                // Get all file references from target's build phases
                let targetFileReferences = getFileReferencesFromTarget(target)

                // Find groups that contain these files
                let targetGroups = findGroupsContainingFiles(
                    targetFileReferences, in: xcodeproj.pbxproj)

                // Traverse only the groups that are related to this target
                for group in targetGroups {
                    traverseGroup(group, path: "", groupList: &groupList)
                }

                // Remove duplicates while preserving order
                groupList = Array(NSOrderedSet(array: groupList)) as! [String]
            } else {
                // Recursively traverse groups starting from main group
                traverseGroup(mainGroup, path: "", groupList: &groupList)

                // Also include the products group if it exists and is not already included
                if let productsGroup = project.productsGroup,
                    !groupList.contains(where: { $0.contains("Products") })
                {
                    traverseGroup(productsGroup, path: "", groupList: &groupList)
                }
            }

            let result =
                groupList.isEmpty
                ? targetName != nil
                    ? "No groups found for target '\(targetName!)'."
                    : "No groups found in project."
                : groupList.joined(separator: "\n")

            let titleMessage =
                targetName != nil
                ? "Groups in target '\(targetName!)':\n\(result)"
                : "Groups in project:\n\(result)"

            return CallTool.Result(
                content: [
                    .text(titleMessage)
                ]
            )
        } catch {
            throw MCPError.internalError(
                "Failed to read Xcode project: \(error.localizedDescription)")
        }
    }

    private func traverseGroup(_ group: PBXGroup, path: String, groupList: inout [String]) {
        // Get the group name - use name if available, otherwise use path
        let groupName = group.name ?? group.path ?? "Unnamed Group"

        // Build the full path for this group
        let currentPath = path.isEmpty ? groupName : "\(path)/\(groupName)"

        // Add this group to the list if it has a meaningful name
        // Skip only if it's the root group with no name or path
        let shouldInclude = group.name != nil || group.path != nil
        if shouldInclude {
            groupList.append("- \(currentPath)")
        }

        // Recursively process child groups
        for child in group.children {
            if let childGroup = child as? PBXGroup {
                // For child groups, use current path if this group should be included, otherwise use the parent path
                let childPath = shouldInclude ? currentPath : path
                traverseGroup(childGroup, path: childPath, groupList: &groupList)
            }
        }
    }

    private func getFileReferencesFromTarget(_ target: PBXNativeTarget) -> Set<PBXFileElement> {
        var fileReferences = Set<PBXFileElement>()

        // Get files from all build phases
        for buildPhase in target.buildPhases {
            if let sourcesBuildPhase = buildPhase as? PBXSourcesBuildPhase {
                for file in sourcesBuildPhase.files ?? [] {
                    if let fileRef = file.file {
                        fileReferences.insert(fileRef)
                    }
                }
            } else if let resourcesBuildPhase = buildPhase as? PBXResourcesBuildPhase {
                for file in resourcesBuildPhase.files ?? [] {
                    if let fileRef = file.file {
                        fileReferences.insert(fileRef)
                    }
                }
            } else if let frameworksBuildPhase = buildPhase as? PBXFrameworksBuildPhase {
                for file in frameworksBuildPhase.files ?? [] {
                    if let fileRef = file.file {
                        fileReferences.insert(fileRef)
                    }
                }
            } else if let headersBuildPhase = buildPhase as? PBXHeadersBuildPhase {
                for file in headersBuildPhase.files ?? [] {
                    if let fileRef = file.file {
                        fileReferences.insert(fileRef)
                    }
                }
            }
        }

        return fileReferences
    }

    private func findGroupsContainingFiles(
        _ fileReferences: Set<PBXFileElement>, in pbxproj: PBXProj
    ) -> Set<PBXGroup> {
        var targetGroups = Set<PBXGroup>()

        // Find all groups that contain any of the target's files
        for group in pbxproj.groups {
            if containsAnyFile(group: group, fileReferences: fileReferences) {
                targetGroups.insert(group)

                // Also include parent groups for proper hierarchy
                addParentGroups(of: group, to: &targetGroups, in: pbxproj)
            }
        }

        return targetGroups
    }

    private func containsAnyFile(group: PBXGroup, fileReferences: Set<PBXFileElement>) -> Bool {
        for child in group.children {
            if fileReferences.contains(child) {
                return true
            }
            // Recursively check child groups
            if let childGroup = child as? PBXGroup {
                if containsAnyFile(group: childGroup, fileReferences: fileReferences) {
                    return true
                }
            }
        }
        return false
    }

    private func addParentGroups(
        of group: PBXGroup, to targetGroups: inout Set<PBXGroup>, in pbxproj: PBXProj
    ) {
        // Find parent groups by checking which groups contain this group as a child
        for parentGroup in pbxproj.groups {
            if parentGroup.children.contains(group) {
                targetGroups.insert(parentGroup)
                // Recursively add parent's parents
                addParentGroups(of: parentGroup, to: &targetGroups, in: pbxproj)
            }
        }
    }
}
