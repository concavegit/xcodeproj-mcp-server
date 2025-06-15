import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

@Suite("AddDependencyTool Tests")
struct AddDependencyToolTests {
    @Test("Tool creation")
    func toolCreation() {
        let tool = AddDependencyTool(pathUtility: PathUtility())
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "add_dependency")
        #expect(toolDefinition.description == "Add dependency between targets")
    }
    
    @Test("Add dependency with missing parameters")
    func addDependencyWithMissingParameters() throws {
        let tool = AddDependencyTool(pathUtility: PathUtility())
        
        // Missing project_path
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "target_name": .string("App"),
                "dependency_name": .string("Framework")
            ])
        }
        
        // Missing target_name
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": .string("/path/to/project.xcodeproj"),
                "dependency_name": .string("Framework")
            ])
        }
        
        // Missing dependency_name
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": .string("/path/to/project.xcodeproj"),
                "target_name": .string("App")
            ])
        }
    }
    
    @Test("Add dependency between targets")
    func addDependencyBetweenTargets() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "App", at: projectPath)
        
        // Add a framework target
        let addTargetTool = AddTargetTool(pathUtility: PathUtility())
        let addFrameworkArgs: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("Framework"),
            "product_type": .string("framework"),
            "bundle_identifier": .string("com.test.framework")
        ]
        _ = try addTargetTool.execute(arguments: addFrameworkArgs)
        
        // Add dependency
        let tool = AddDependencyTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("App"),
            "dependency_name": .string("Framework")
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains success message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("Successfully added dependency 'Framework' to target 'App'"))
        
        // Verify dependency was added
        let xcodeproj = try XcodeProj(path: projectPath)
        let appTarget = xcodeproj.pbxproj.nativeTargets.first { $0.name == "App" }
        #expect(appTarget != nil)
        
        let hasDependency = appTarget?.dependencies.contains { dependency in
            dependency.name == "Framework"
        } ?? false
        #expect(hasDependency == true)
    }
    
    @Test("Add duplicate dependency")
    func addDuplicateDependency() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with targets
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "App", at: projectPath)
        
        // Add a framework target
        let addTargetTool = AddTargetTool(pathUtility: PathUtility())
        let addFrameworkArgs: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("Framework"),
            "product_type": .string("framework"),
            "bundle_identifier": .string("com.test.framework")
        ]
        _ = try addTargetTool.execute(arguments: addFrameworkArgs)
        
        // Add dependency
        let tool = AddDependencyTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("App"),
            "dependency_name": .string("Framework")
        ]
        
        _ = try tool.execute(arguments: args)
        
        // Try to add the same dependency again
        let result = try tool.execute(arguments: args)
        
        // Check the result contains already exists message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("already depends on"))
    }
    
    @Test("Add dependency with non-existent target")
    func addDependencyWithNonExistentTarget() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        let tool = AddDependencyTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("NonExistentTarget"),
            "dependency_name": .string("Framework")
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains not found message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("not found"))
    }
    
    @Test("Add dependency with non-existent dependency")
    func addDependencyWithNonExistentDependency() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "App", at: projectPath)
        
        let tool = AddDependencyTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("App"),
            "dependency_name": .string("NonExistentFramework")
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains not found message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("not found"))
    }
}