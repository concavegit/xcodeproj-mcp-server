import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

struct ListFilesToolTests {
    
    @Test func testListFilesToolCreation() {
        let tool = ListFilesTool(pathUtility: PathUtility(basePath: "/workspace"))
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "list_files")
        #expect(toolDefinition.description == "List all files in an Xcode project")
    }
    
    @Test func testListFilesWithMissingProjectPath() throws {
        let tool = ListFilesTool(pathUtility: PathUtility(basePath: "/workspace"))

        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [:])
        }
    }
    
    @Test func testListFilesWithInvalidProjectPath() throws {
        let tool = ListFilesTool(pathUtility: PathUtility(basePath: "/workspace"))
        let arguments: [String: Value] = [
            "project_path": Value.string("/nonexistent/path.xcodeproj")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: arguments)
        }
    }
    
    @Test func testListFilesWithEmptyProject() throws {
        let tool = ListFilesTool(pathUtility: PathUtility(basePath: "/workspace"))
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a test project using XcodeProj
        let projectPath = Path(tempDir.path) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)
        
        // List files in the created project
        let listArguments: [String: Value] = [
            "project_path": Value.string(projectPath.string)
        ]
        
        let result = try tool.execute(arguments: listArguments)
        
        #expect(result.content.count == 1)
        if case let .text(content) = result.content[0] {
            #expect(content.contains("TestProject.xcodeproj"))
            #expect(content.contains("No files found"))
        } else {
            Issue.record("Expected text content")
        }
    }
}
