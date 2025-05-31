import Foundation
import MCP
import XcodeProj
import PathKit

public struct ListFilesTool: Sendable {
    public func tool() -> Tool {
        Tool(
            name: "list_files",
            description: "List all files in an Xcode project",
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
            let fileReferences = xcodeproj.pbxproj.fileReferences
            
            var fileList: [String] = []
            for fileRef in fileReferences {
                if let path = fileRef.path {
                    let fileInfo = "- \(path)"
                    fileList.append(fileInfo)
                } else if let name = fileRef.name {
                    let fileInfo = "- \(name)"
                    fileList.append(fileInfo)
                }
            }
            
            let result = fileList.isEmpty ? "No files found in the project." : fileList.joined(separator: "\n")
            
            return CallTool.Result(
                content: [
                    .text("Files in \(projectURL.lastPathComponent):\n\(result)")
                ]
            )
        } catch {
            throw MCPError.internalError("Failed to read Xcode project: \(error.localizedDescription)")
        }
    }
}