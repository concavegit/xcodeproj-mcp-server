import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

struct GetBuildSettingsToolTests {
    
    @Test func testGetBuildSettingsToolCreation() {
        let tool = GetBuildSettingsTool()
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "get_build_settings")
        #expect(toolDefinition.description == "Get build settings for a specific target in an Xcode project")
    }
    
    @Test func testGetBuildSettingsWithMissingProjectPath() throws {
        let tool = GetBuildSettingsTool()
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: ["target_name": .string("TestTarget")])
        }
    }
    
    @Test func testGetBuildSettingsWithMissingTargetName() throws {
        let tool = GetBuildSettingsTool()
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: ["project_path": .string("/path/to/project.xcodeproj")])
        }
    }
    
    @Test func testGetBuildSettingsWithInvalidProjectPath() throws {
        let tool = GetBuildSettingsTool()
        let arguments: [String: Value] = [
            "project_path": .string("/nonexistent/path.xcodeproj"),
            "target_name": .string("TestTarget")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: arguments)
        }
    }
    
    @Test func testGetBuildSettingsWithNonexistentTarget() throws {
        let tool = GetBuildSettingsTool()
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project using XcodeProj
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        // Try to get build settings for non-existent target
        let arguments: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("NonexistentTarget")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: arguments)
        }
    }
    
    @Test func testGetBuildSettingsWithValidTarget() throws {
        let tool = GetBuildSettingsTool()
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with a target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "TestApp", at: projectPath)
        
        // Get build settings
        let arguments: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("TestApp")
        ]
        
        let result = try tool.execute(arguments: arguments)
        
        #expect(result.content.count == 1)
        if case let .text(content) = result.content[0] {
            #expect(content.contains("Build settings for target 'TestApp'"))
            #expect(content.contains("PRODUCT_NAME") || content.contains("BUNDLE_IDENTIFIER"))
        } else {
            Issue.record("Expected text content")
        }
    }
    
    @Test func testGetBuildSettingsWithSpecificConfiguration() throws {
        let tool = GetBuildSettingsTool()
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with a target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "TestApp", at: projectPath)
        
        // Get build settings for Release configuration
        let arguments: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("TestApp"),
            "configuration": .string("Release")
        ]
        
        let result = try tool.execute(arguments: arguments)
        
        #expect(result.content.count == 1)
        if case let .text(content) = result.content[0] {
            #expect(content.contains("Build settings for target 'TestApp' (Release)"))
        } else {
            Issue.record("Expected text content")
        }
    }
}