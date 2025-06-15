import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

@Suite("AddTargetTool Tests")
struct AddTargetToolTests {
    @Test("Tool creation")
    func toolCreation() {
        let tool = AddTargetTool(pathUtility: PathUtility())
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "add_target")
        #expect(toolDefinition.description == "Create a new target")
    }
    
    @Test("Add target with missing parameters")
    func addTargetWithMissingParameters() throws {
        let tool = AddTargetTool(pathUtility: PathUtility())
        
        // Missing project_path
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "target_name": .string("NewTarget"),
                "product_type": .string("app"),
                "bundle_identifier": .string("com.test.newtarget")
            ])
        }
        
        // Missing target_name
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": .string("/path/to/project.xcodeproj"),
                "product_type": .string("app"),
                "bundle_identifier": .string("com.test.newtarget")
            ])
        }
        
        // Missing product_type
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": .string("/path/to/project.xcodeproj"),
                "target_name": .string("NewTarget"),
                "bundle_identifier": .string("com.test.newtarget")
            ])
        }
        
        // Missing bundle_identifier
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": .string("/path/to/project.xcodeproj"),
                "target_name": .string("NewTarget"),
                "product_type": .string("app")
            ])
        }
    }
    
    @Test("Add application target")
    func addApplicationTarget() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        let tool = AddTargetTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("NewApp"),
            "product_type": .string("app"),
            "bundle_identifier": .string("com.test.newapp")
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains success message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("Successfully created target 'NewApp'"))
        #expect(message.contains("product type 'app'"))
        #expect(message.contains("bundle identifier 'com.test.newapp'"))
        
        // Verify target was created
        let xcodeproj = try XcodeProj(path: projectPath)
        let target = xcodeproj.pbxproj.nativeTargets.first { $0.name == "NewApp" }
        #expect(target != nil)
        #expect(target?.productType == .application)
        
        // Verify build phases were created
        #expect(target?.buildPhases.contains { $0 is PBXSourcesBuildPhase } == true)
        #expect(target?.buildPhases.contains { $0 is PBXResourcesBuildPhase } == true)
        #expect(target?.buildPhases.contains { $0 is PBXFrameworksBuildPhase } == true)
        
        // Verify build configurations
        let buildConfig = target?.buildConfigurationList?.buildConfigurations.first { $0.name == "Debug" }
        #expect(buildConfig?.buildSettings["BUNDLE_IDENTIFIER"]?.stringValue == "com.test.newapp")
    }
    
    @Test("Add framework target")
    func addFrameworkTarget() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        let tool = AddTargetTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("MyFramework"),
            "product_type": .string("framework"),
            "bundle_identifier": .string("com.test.myframework"),
            "platform": .string("iOS"),
            "deployment_target": .string("15.0")
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains success message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("Successfully created target 'MyFramework'"))
        
        // Verify target was created
        let xcodeproj = try XcodeProj(path: projectPath)
        let target = xcodeproj.pbxproj.nativeTargets.first { $0.name == "MyFramework" }
        #expect(target != nil)
        #expect(target?.productType == .framework)
        
        // Verify deployment target
        let buildConfig = target?.buildConfigurationList?.buildConfigurations.first { $0.name == "Debug" }
        #expect(buildConfig?.buildSettings["IPHONEOS_DEPLOYMENT_TARGET"]?.stringValue == "15.0")
    }
    
    @Test("Add unit test target")
    func addUnitTestTarget() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        let tool = AddTargetTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("MyAppTests"),
            "product_type": .string("unitTestBundle"),
            "bundle_identifier": .string("com.test.myapptests")
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains success message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("Successfully created target 'MyAppTests'"))
        
        // Verify target was created
        let xcodeproj = try XcodeProj(path: projectPath)
        let target = xcodeproj.pbxproj.nativeTargets.first { $0.name == "MyAppTests" }
        #expect(target != nil)
        #expect(target?.productType == .unitTestBundle)
    }
    
    @Test("Add duplicate target")
    func addDuplicateTarget() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with existing target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "TestApp", at: projectPath)
        
        let tool = AddTargetTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("TestApp"),
            "product_type": .string("app"),
            "bundle_identifier": .string("com.test.testapp")
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains already exists message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("already exists"))
    }
    
    @Test("Add target with invalid product type")
    func addTargetWithInvalidProductType() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        let tool = AddTargetTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("NewTarget"),
            "product_type": .string("invalid_type"),
            "bundle_identifier": .string("com.test.newtarget")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: args)
        }
    }
}