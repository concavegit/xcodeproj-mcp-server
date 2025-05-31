import Testing
import Foundation
import MCP
import XcodeProj
import PathKit
@testable import XcodeProjectMCP

struct ListBuildConfigurationsToolTests {
    
    @Test func testListBuildConfigurationsToolCreation() {
        let tool = ListBuildConfigurationsTool()
        let toolDefinition = tool.tool()
        
        #expect(toolDefinition.name == "list_build_configurations")
        #expect(toolDefinition.description == "List all build configurations in an Xcode project")
    }
    
    @Test func testListBuildConfigurationsWithMissingProjectPath() throws {
        let tool = ListBuildConfigurationsTool()
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [:])
        }
    }
    
    @Test func testListBuildConfigurationsWithInvalidProjectPath() throws {
        let tool = ListBuildConfigurationsTool()
        let arguments: [String: Value] = [
            "project_path": .string("/nonexistent/path.xcodeproj")
        ]
        
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: arguments)
        }
    }
    
    @Test func testListBuildConfigurationsWithValidProject() throws {
        let tool = ListBuildConfigurationsTool()
        
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Create a minimal project structure manually
        let projectPath = tempDir.appendingPathComponent("TestProject.xcodeproj")
        try FileManager.default.createDirectory(at: projectPath, withIntermediateDirectories: true)
        
        let pbxprojPath = projectPath.appendingPathComponent("project.pbxproj")
        let pbxprojContent = """
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXProject section */
		ABCD1234567890123456 /* Project object */ = {
			isa = PBXProject;
			attributes = {
			};
			buildConfigurationList = EFGH1234567890123456 /* Build configuration list for PBXProject "TestProject" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = IJKL1234567890123456;
			projectDirPath = "";
			projectRoot = "";
			targets = (
			);
		};
/* End PBXProject section */

/* Begin PBXGroup section */
		IJKL1234567890123456 = {
			isa = PBXGroup;
			children = (
			);
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin XCBuildConfiguration section */
		MNOP1234567890123456 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
			};
			name = Debug;
		};
		QRST1234567890123456 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		EFGH1234567890123456 /* Build configuration list for PBXProject "TestProject" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				MNOP1234567890123456 /* Debug */,
				QRST1234567890123456 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = ABCD1234567890123456 /* Project object */;
}
"""
        try pbxprojContent.write(to: pbxprojPath, atomically: true, encoding: .utf8)
        
        // List build configurations in the created project
        let listArguments: [String: Value] = [
            "project_path": .string(projectPath.path)
        ]
        
        let result = try tool.execute(arguments: listArguments)
        
        #expect(result.content.count == 1)
        if case let .text(content) = result.content[0] {
            #expect(content.contains("TestProject.xcodeproj"))
            #expect(content.contains("Debug") || content.contains("Release"))
        } else {
            Issue.record("Expected text content")
        }
    }
}