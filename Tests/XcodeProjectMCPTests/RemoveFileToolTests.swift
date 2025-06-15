import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

@Suite("RemoveFileTool Tests")
struct RemoveFileToolTests {
    @Test("Tool creation")
    func toolCreation() {
        let tool = RemoveFileTool(pathUtility: PathUtility())
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "remove_file")
        #expect(toolDefinition.description == "Remove a file from the Xcode project")
    }
    
    @Test("Remove file with missing project path")
    func removeFileWithMissingProjectPath() throws {
        let tool = RemoveFileTool(pathUtility: PathUtility())
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: ["file_path": .string("test.swift")])
        }
    }
    
    @Test("Remove file with missing file path")
    func removeFileWithMissingFilePath() throws {
        let tool = RemoveFileTool(pathUtility: PathUtility())
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: ["project_path": .string("/path/to/project.xcodeproj")])
        }
    }
    
    @Test("Remove file from project")
    func removeFile() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "TestApp", at: projectPath)
        
        // First add a file to remove
        let addTool = AddFileTool(pathUtility: PathUtility())
        let testFilePath = tempDir.appendingPathComponent("TestFile.swift").path
        try "// Test file".write(toFile: testFilePath, atomically: true, encoding: .utf8)
        
        let addArgs: [String: Value] = [
            "project_path": .string(projectPath.string),
            "file_path": .string(testFilePath),
            "target_name": .string("TestApp")
        ]
        _ = try addTool.execute(arguments: addArgs)
        
        // Now remove the file
        let removeTool = RemoveFileTool(pathUtility: PathUtility())
        let removeArgs: [String: Value] = [
            "project_path": .string(projectPath.string),
            "file_path": .string(testFilePath),
            "remove_from_disk": .bool(false)
        ]
        
        let result = try removeTool.execute(arguments: removeArgs)
        
        // Check the result contains success message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("Successfully removed"))
        
        // Verify file was removed from project
        let xcodeproj = try XcodeProj(path: projectPath)
        let target = xcodeproj.pbxproj.nativeTargets.first { $0.name == "TestApp" }
        let sourcesBuildPhase = target?.buildPhases.first { $0 is PBXSourcesBuildPhase } as? PBXSourcesBuildPhase
        
        let fileStillExists = sourcesBuildPhase?.files?.contains { buildFile in
            if let fileRef = buildFile.file as? PBXFileReference {
                return fileRef.path == testFilePath || fileRef.name == "TestFile.swift"
            }
            return false
        } ?? false
        
        #expect(fileStillExists == false)
        
        // Verify file still exists on disk (remove_from_disk was false)
        #expect(FileManager.default.fileExists(atPath: testFilePath) == true)
    }
    
    @Test("Remove file from disk")
    func removeFileFromDisk() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "TestApp", at: projectPath)
        
        // First add a file to remove
        let addTool = AddFileTool(pathUtility: PathUtility())
        let testFilePath = tempDir.appendingPathComponent("TestFileToDelete.swift").path
        try "// Test file".write(toFile: testFilePath, atomically: true, encoding: .utf8)
        
        let addArgs: [String: Value] = [
            "project_path": .string(projectPath.string),
            "file_path": .string(testFilePath),
            "target_name": .string("TestApp")
        ]
        _ = try addTool.execute(arguments: addArgs)
        
        // Now remove the file with remove_from_disk = true
        let removeTool = RemoveFileTool(pathUtility: PathUtility())
        let removeArgs: [String: Value] = [
            "project_path": .string(projectPath.string),
            "file_path": .string(testFilePath),
            "remove_from_disk": .bool(true)
        ]
        
        let result = try removeTool.execute(arguments: removeArgs)
        
        // Check the result contains success message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("Successfully removed"))
        #expect(FileManager.default.fileExists(atPath: testFilePath) == false)
    }
    
    @Test("Remove non-existent file")
    func removeNonExistentFile() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        let removeTool = RemoveFileTool(pathUtility: PathUtility())
        let removeArgs: [String: Value] = [
            "project_path": .string(projectPath.string),
            "file_path": .string("/path/to/nonexistent.swift"),
            "remove_from_disk": .bool(false)
        ]
        
        let result = try removeTool.execute(arguments: removeArgs)
        
        // Check the result contains not found message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("File not found"))
    }
}