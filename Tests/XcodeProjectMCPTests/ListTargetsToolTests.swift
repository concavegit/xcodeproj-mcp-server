import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

struct ListTargetsToolTests {
    
    @Test func testListTargetsToolCreation() {
        let tool = ListTargetsTool()
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "list_targets")
        #expect(toolDefinition.description == "List all targets in an Xcode project")
    }
    
    @Test func testListTargetsWithMissingProjectPath() throws {
        let tool = ListTargetsTool()
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [:])
        }
    }
    
    @Test func testListTargetsWithInvalidProjectPath() throws {
        let tool = ListTargetsTool()
        let arguments: [String: Value] = [
            "project_path": .string("/nonexistent/path.xcodeproj")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: arguments)
        }
    }
    
    @Test func testListTargetsWithEmptyProject() throws {
        let tool = ListTargetsTool()
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project using XcodeProj
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        // List targets in the created project
        let listArguments: [String: Value] = [
            "project_path": .string(projectPath.string)
        ]
        
        let result = try tool.execute(arguments: listArguments)
        
        #expect(result.content.count == 1)
        if case let .text(content) = result.content[0] {
            #expect(content.contains("TestProject.xcodeproj"))
            #expect(content.contains("No targets found"))
        } else {
            Issue.record("Expected text content")
        }
    }
}