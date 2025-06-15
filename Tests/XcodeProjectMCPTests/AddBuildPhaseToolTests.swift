import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

@Suite("AddBuildPhaseTool Tests")
struct AddBuildPhaseToolTests {
    @Test("Tool creation")
    func toolCreation() {
        let tool = AddBuildPhaseTool(pathUtility: PathUtility())
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "add_build_phase")
        #expect(toolDefinition.description == "Add custom build phases")
    }
    
    @Test("Add build phase with missing parameters")
    func addBuildPhaseWithMissingParameters() throws {
        let tool = AddBuildPhaseTool(pathUtility: PathUtility())
        
        // Missing project_path
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "target_name": .string("App"),
                "phase_name": .string("Custom Script"),
                "phase_type": .string("run_script")
            ])
        }
        
        // Missing target_name
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": .string("/path/to/project.xcodeproj"),
                "phase_name": .string("Custom Script"),
                "phase_type": .string("run_script")
            ])
        }
        
        // Missing phase_name
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": .string("/path/to/project.xcodeproj"),
                "target_name": .string("App"),
                "phase_type": .string("run_script")
            ])
        }
        
        // Missing phase_type
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": .string("/path/to/project.xcodeproj"),
                "target_name": .string("App"),
                "phase_name": .string("Custom Script")
            ])
        }
    }
    
    @Test("Add run script build phase")
    func addRunScriptBuildPhase() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "App", at: projectPath)
        
        // Add run script phase
        let tool = AddBuildPhaseTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("App"),
            "phase_name": .string("SwiftLint"),
            "phase_type": .string("run_script"),
            "script": .string("if which swiftlint >/dev/null; then\n  swiftlint\nelse\n  echo \"warning: SwiftLint not installed\"\nfi")
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains success message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("Successfully added run_script build phase 'SwiftLint'"))
        
        // Verify script phase was added
        let xcodeproj = try XcodeProj(path: projectPath)
        let target = xcodeproj.pbxproj.nativeTargets.first { $0.name == "App" }
        
        let hasScriptPhase = target?.buildPhases.contains { phase in
            if let scriptPhase = phase as? PBXShellScriptBuildPhase {
                return scriptPhase.name == "SwiftLint"
            }
            return false
        } ?? false
        
        #expect(hasScriptPhase == true)
    }
    
    @Test("Add copy files build phase")
    func addCopyFilesBuildPhase() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "App", at: projectPath)
        
        // Add a file to the project first
        let addFileTool = AddFileTool(pathUtility: PathUtility())
        let testFilePath = tempDir.appendingPathComponent("config.plist").path
        try "<plist></plist>".write(toFile: testFilePath, atomically: true, encoding: .utf8)
        
        _ = try addFileTool.execute(arguments: [
            "project_path": .string(projectPath.string),
            "file_path": .string(testFilePath)
        ])
        
        // Add copy files phase
        let tool = AddBuildPhaseTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("App"),
            "phase_name": .string("Copy Config Files"),
            "phase_type": .string("copy_files"),
            "destination": .string("resources"),
            "files": .array([.string(testFilePath)])
        ]
        
        let result = try tool.execute(arguments: args)
        
        // Check the result contains success message
        guard case let .text(message) = result.content.first else {
            Issue.record("Expected text result")
            return
        }
        #expect(message.contains("Successfully added copy_files build phase"))
        
        // Verify copy files phase was added
        let xcodeproj = try XcodeProj(path: projectPath)
        let target = xcodeproj.pbxproj.nativeTargets.first { $0.name == "App" }
        
        let hasCopyPhase = target?.buildPhases.contains { phase in
            if let copyPhase = phase as? PBXCopyFilesBuildPhase {
                return copyPhase.name == "Copy Config Files" && copyPhase.dstSubfolderSpec == .resources
            }
            return false
        } ?? false
        
        #expect(hasCopyPhase == true)
    }
    
    @Test("Add run script phase without script")
    func addRunScriptPhaseWithoutScript() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "App", at: projectPath)
        
        let tool = AddBuildPhaseTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("App"),
            "phase_name": .string("Script"),
            "phase_type": .string("run_script")
            // Missing script parameter
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: args)
        }
    }
    
    @Test("Add copy files phase without destination")
    func addCopyFilesPhaseWithoutDestination() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "App", at: projectPath)
        
        let tool = AddBuildPhaseTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("App"),
            "phase_name": .string("Copy Files"),
            "phase_type": .string("copy_files")
            // Missing destination parameter
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: args)
        }
    }
    
    @Test("Add build phase with invalid phase type")
    func addBuildPhaseWithInvalidPhaseType() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project with target
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(name: "TestProject", targetName: "App", at: projectPath)
        
        let tool = AddBuildPhaseTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("App"),
            "phase_name": .string("Invalid Phase"),
            "phase_type": .string("invalid_type")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: args)
        }
    }
    
    @Test("Add build phase to non-existent target")
    func addBuildPhaseToNonExistentTarget() throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        let tool = AddBuildPhaseTool(pathUtility: PathUtility())
        let args: [String: Value] = [
            "project_path": .string(projectPath.string),
            "target_name": .string("NonExistentTarget"),
            "phase_name": .string("Script"),
            "phase_type": .string("run_script"),
            "script": .string("echo Hello")
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
