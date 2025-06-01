import Foundation
import MCP
import XcodeProj
import PathKit

public struct OpenXcodeprojTool: Sendable {
    public func tool() -> Tool {
        Tool(
            name: "open_xcodeproj",
            description: "Open an Xcode project in Xcode using the xed command",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "project_path": .object([
                        "type": .string("string"),
                        "description": .string("Path to the .xcodeproj file")
                    ]),
                    "wait": .object([
                        "type": .string("boolean"),
                        "description": .string("Whether to wait for Xcode to close before returning (default: false)")
                    ])
                ]),
                "required": .array([.string("project_path")])
            ])
        )
    }
    
    public func execute(arguments: [String: Value]) throws -> CallTool.Result {
        guard case let .string(projectPath) = arguments["project_path"] else {
            throw MCPError.invalidParams("project_path is required")
        }
        
        let wait: Bool
        if case let .bool(waitValue) = arguments["wait"] {
            wait = waitValue
        } else {
            wait = false
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        
        guard FileManager.default.fileExists(atPath: projectURL.path) else {
            throw MCPError.invalidParams("Project file not found: \(projectPath)")
        }
        
        guard projectURL.pathExtension == "xcodeproj" else {
            throw MCPError.invalidParams("Project file must have .xcodeproj extension")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xed")
        
        var processArguments = [projectURL.path]
        if wait {
            processArguments.append("--wait")
        }
        process.arguments = processArguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw MCPError.internalError("Failed to open Xcode: \(errorOutput)")
            }
            
            return CallTool.Result(
                content: [
                    .text("Successfully opened \(projectURL.lastPathComponent) in Xcode")
                ]
            )
        } catch {
            throw MCPError.internalError("Failed to execute xed command: \(error.localizedDescription)")
        }
    }
}