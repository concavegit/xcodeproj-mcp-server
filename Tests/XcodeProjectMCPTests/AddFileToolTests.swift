import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

struct AddFileToolTests {
    
    @Test func testAddFileToolCreation() {
        let tool = AddFileTool(pathUtility: PathUtility())
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "add_file")
        #expect(toolDefinition.description == "Add a file to an Xcode project")
    }
    
    @Test func testAddFileWithMissingProjectPath() throws {
        let tool = AddFileTool(pathUtility: PathUtility())
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: ["file_path": .string("test.swift")])
        }
    }
    
    @Test func testAddFileWithMissingFilePath() throws {
        let tool = AddFileTool(pathUtility: PathUtility())
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: ["project_path": .string("/path/to/project.xcodeproj")])
        }
    }
    
    @Test func testAddFileWithInvalidProjectPath() throws {
        let tool = AddFileTool(pathUtility: PathUtility())
        let arguments: [String: Value] = [
            "project_path": .string("/nonexistent/path.xcodeproj"),
            "file_path": .string("test.swift")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: arguments)
        }
    }
    
    @Test func testAddFileToMainGroup() throws {
        let tool = AddFileTool(pathUtility: PathUtility())
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        // Add a file
        let arguments: [String: Value] = [
            "project_path": .string(projectPath.string),
            "file_path": .string("TestFile.swift")
        ]
        
        let result = try tool.execute(arguments: arguments)
        
        #expect(result.content.count == 1)
        if case let .text(content) = result.content[0] {
            #expect(content.contains("Successfully added file 'TestFile.swift'"))
        } else {
            Issue.record("Expected text content")
        }
        
        // Verify file was added to project
        let xcodeproj = try XcodeProj(path: projectPath)
        let fileReferences = xcodeproj.pbxproj.fileReferences
        let addedFile = fileReferences.first { $0.name == "TestFile.swift" }
        #expect(addedFile != nil)
    }
    
    @Test func testAddFileToTarget() throws {
        let tool = AddFileTool(pathUtility: PathUtility())
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with a target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "TestApp", at: projectPath)
        
        // Add a Swift file to target
        let arguments: [String: Value] = [
            "project_path": .string(projectPath.string),
            "file_path": .string("TestFile.swift"),
            "target_name": .string("TestApp")
        ]
        
        let result = try tool.execute(arguments: arguments)
        
        #expect(result.content.count == 1)
        if case let .text(content) = result.content[0] {
            #expect(content.contains("Successfully added file 'TestFile.swift' to target 'TestApp'"))
        } else {
            Issue.record("Expected text content")
        }
        
        // Verify file was added to project and target
        let xcodeproj = try XcodeProj(path: projectPath)
        let fileReferences = xcodeproj.pbxproj.fileReferences
        let addedFile = fileReferences.first { $0.name == "TestFile.swift" }
        #expect(addedFile != nil)
        
        // Verify file was added to target's sources build phase
        let target = xcodeproj.pbxproj.nativeTargets.first { $0.name == "TestApp" }
        #expect(target != nil)
        
        let sourcesBuildPhase = target?.buildPhases.first { $0 is PBXSourcesBuildPhase } as? PBXSourcesBuildPhase
        #expect(sourcesBuildPhase != nil)
        
        let buildFile = sourcesBuildPhase?.files?.first { $0.file == addedFile }
        #expect(buildFile != nil)
    }
    
    @Test func testAddFileWithNonexistentTarget() throws {
        let tool = AddFileTool(pathUtility: PathUtility())
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        // Try to add file to non-existent target
        let arguments: [String: Value] = [
            "project_path": .string(projectPath.string),
            "file_path": .string("TestFile.swift"),
            "target_name": .string("NonexistentTarget")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: arguments)
        }
    }
}