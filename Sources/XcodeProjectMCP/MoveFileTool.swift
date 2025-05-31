import Foundation
import XcodeProj
import MCP
import PathKit

public struct MoveFileTool: Sendable {
    public func tool() -> Tool {
        Tool(
            name: "move_file",
            description: "Move or rename a file within the project",
            inputSchema: .object([
                "project_path": .object([
                    "type": .string("string"),
                    "description": .string("Path to the .xcodeproj file")
                ]),
                "old_path": .object([
                    "type": .string("string"),
                    "description": .string("Current path of the file to move")
                ]),
                "new_path": .object([
                    "type": .string("string"),
                    "description": .string("New path for the file")
                ]),
                "move_on_disk": .object([
                    "type": .string("boolean"),
                    "description": .string("Whether to also move the file on disk (optional, defaults to false)")
                ])
            ])
        )
    }
    
    public func execute(arguments: [String: Value]) throws -> CallTool.Result {
        guard case let .string(projectPath) = arguments["project_path"],
              case let .string(oldPath) = arguments["old_path"],
              case let .string(newPath) = arguments["new_path"] else {
            throw MCPError.invalidParams("project_path, old_path, and new_path are required")
        }
        
        let moveOnDisk: Bool
        if case let .bool(move) = arguments["move_on_disk"] {
            moveOnDisk = move
        } else {
            moveOnDisk = false
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let xcodeproj = try XcodeProj(pathString: projectURL.path)
        
        let oldFileName = URL(fileURLWithPath: oldPath).lastPathComponent
        let newFileName = URL(fileURLWithPath: newPath).lastPathComponent
        var fileMoved = false
        
        // Find and update file references
        for fileRef in xcodeproj.pbxproj.fileReferences {
            if fileRef.path == oldPath || fileRef.name == oldFileName || fileRef.path == oldFileName {
                // Update the file reference
                fileRef.path = newPath
                fileRef.name = newFileName
                fileMoved = true
            }
        }
        
        if fileMoved {
            try xcodeproj.write(pathString: projectURL.path, override: true)
            
            // Optionally move on disk
            if moveOnDisk {
                let oldURL = URL(fileURLWithPath: oldPath)
                let newURL = URL(fileURLWithPath: newPath)
                
                // Create parent directory if needed
                let newParentDir = newURL.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: newParentDir.path) {
                    try FileManager.default.createDirectory(at: newParentDir, withIntermediateDirectories: true)
                }
                
                // Move the file
                if FileManager.default.fileExists(atPath: oldURL.path) {
                    try FileManager.default.moveItem(at: oldURL, to: newURL)
                }
            }
            
            return CallTool.Result(
                content: [
                    .text("Successfully moved \(oldFileName) to \(newPath)")
                ]
            )
        } else {
            return CallTool.Result(
                content: [
                    .text("File not found in project: \(oldFileName)")
                ]
            )
        }
    }
}