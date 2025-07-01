import Foundation
import MCP
import PathKit
import Testing
import XcodeProj

@testable import XcodeProjectMCP

struct ListGroupsToolTests {
    let tempDir: String
    let pathUtility: PathUtility

    init() {
        self.tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ListGroupsToolTests-\(UUID().uuidString)")
            .path
        self.pathUtility = PathUtility(basePath: tempDir)
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    }

    @Test("Tool has correct properties")
    func toolProperties() {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        #expect(tool.tool().name == "list_groups")
        #expect(
            tool.tool().description
                == "List all groups and folder references in an Xcode project, optionally filtered by target")

        let schema = tool.tool().inputSchema
        if case let .object(schemaDict) = schema {
            if case let .object(props) = schemaDict["properties"] {
                #expect(props["project_path"] != nil)
                #expect(props["target_name"] != nil)
            }

            if case let .array(required) = schemaDict["required"] {
                #expect(required.count == 1)
                #expect(required.contains(.string("project_path")))
            }
        }
    }

    @Test("Validates required parameters")
    func validateRequiredParameters() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Missing project_path
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [:])
        }

        // Invalid parameter types
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": Value.bool(true)
            ])
        }
    }

    @Test("Lists groups from project")
    func listsGroupsFromProject() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Create a test project
        let projectPath = Path(tempDir) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)

        // Execute the tool
        let result = try tool.execute(arguments: [
            "project_path": Value.string(projectPath.string)
        ])

        // Verify the result
        if case let .text(message) = result.content.first {
            #expect(message.contains("Groups and folder references in project:"))
            // The default project should contain at least a Products group
            #expect(message.contains("Products"))
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("Lists nested groups correctly")
    func listsNestedGroupsCorrectly() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Create a test project
        let projectPath = Path(tempDir) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)

        // Load the project and add nested groups
        let xcodeproj = try XcodeProj(path: projectPath)

        // Create a top-level group
        let topLevelGroup = PBXGroup(children: [], sourceTree: .group, name: "TopLevel")
        xcodeproj.pbxproj.add(object: topLevelGroup)

        // Create a nested group
        let nestedGroup = PBXGroup(children: [], sourceTree: .group, name: "Nested")
        xcodeproj.pbxproj.add(object: nestedGroup)
        topLevelGroup.children.append(nestedGroup)

        // Create a deeply nested group
        let deeplyNestedGroup = PBXGroup(children: [], sourceTree: .group, name: "DeeplyNested")
        xcodeproj.pbxproj.add(object: deeplyNestedGroup)
        nestedGroup.children.append(deeplyNestedGroup)

        // Add the top-level group to main group
        if let mainGroup = try xcodeproj.pbxproj.rootProject()?.mainGroup {
            mainGroup.children.append(topLevelGroup)
        }

        try xcodeproj.write(path: projectPath)

        // Execute the tool
        let result = try tool.execute(arguments: [
            "project_path": Value.string(projectPath.string)
        ])

        // Verify the result
        if case let .text(message) = result.content.first {
            #expect(message.contains("Groups and folder references in project:"))
            #expect(message.contains("- TopLevel"))
            #expect(message.contains("- TopLevel/Nested"))
            #expect(message.contains("- TopLevel/Nested/DeeplyNested"))
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("Handles project with no custom groups")
    func handlesProjectWithNoCustomGroups() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Create a minimal test project
        let projectPath = Path(tempDir) + "MinimalProject.xcodeproj"

        // Create a minimal project structure
        let pbxproj = PBXProj()

        // Create main group with no children except products
        let mainGroup = PBXGroup(sourceTree: .group)
        pbxproj.add(object: mainGroup)

        let productsGroup = PBXGroup(children: [], sourceTree: .group, name: "Products")
        pbxproj.add(object: productsGroup)
        mainGroup.children.append(productsGroup)

        // Create build configuration
        let buildConfig = XCBuildConfiguration(name: "Debug")
        pbxproj.add(object: buildConfig)

        let configList = XCConfigurationList(
            buildConfigurations: [buildConfig], defaultConfigurationName: "Debug")
        pbxproj.add(object: configList)

        // Create project
        let project = PBXProject(
            name: "MinimalProject",
            buildConfigurationList: configList,
            compatibilityVersion: "Xcode 14.0",
            preferredProjectObjectVersion: 56,
            minimizedProjectReferenceProxies: 0,
            mainGroup: mainGroup,
            developmentRegion: "en",
            knownRegions: ["en", "Base"],
            productsGroup: productsGroup
        )
        pbxproj.add(object: project)
        pbxproj.rootObject = project

        // Create workspace and xcodeproj
        let workspaceData = XCWorkspaceData(children: [])
        let workspace = XCWorkspace(data: workspaceData)
        let xcodeproj = XcodeProj(workspace: workspace, pbxproj: pbxproj)
        try xcodeproj.write(path: projectPath)

        // Execute the tool
        let result = try tool.execute(arguments: [
            "project_path": Value.string(projectPath.string)
        ])

        // Verify the result
        if case let .text(message) = result.content.first {
            #expect(message.contains("Groups and folder references in project:"))
            #expect(message.contains("- Products"))
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("Fails when project does not exist")
    func failsWhenProjectDoesNotExist() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Try to list groups from a non-existent project
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": Value.string("/path/that/does/not/exist.xcodeproj")
            ])
        }
    }

    @Test("Handles groups with path but no name")
    func handlesGroupsWithPathButNoName() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Create a test project
        let projectPath = Path(tempDir) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)

        // Load the project and add a group with path but no name
        let xcodeproj = try XcodeProj(path: projectPath)

        let groupWithPath = PBXGroup(children: [], sourceTree: .group, path: "Sources")
        xcodeproj.pbxproj.add(object: groupWithPath)

        if let mainGroup = try xcodeproj.pbxproj.rootProject()?.mainGroup {
            mainGroup.children.append(groupWithPath)
        }

        try xcodeproj.write(path: projectPath)

        // Execute the tool
        let result = try tool.execute(arguments: [
            "project_path": Value.string(projectPath.string)
        ])

        // Verify the result
        if case let .text(message) = result.content.first {
            #expect(message.contains("Groups and folder references in project:"))
            #expect(message.contains("- Sources"))
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("Lists groups for specific target")
    func listsGroupsForSpecificTarget() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Create a test project with a target
        let projectPath = Path(tempDir) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(
            name: "TestProject", targetName: "TestTarget", at: projectPath)

        // Load the project and add some files to groups for the target
        let xcodeproj = try XcodeProj(path: projectPath)

        // Create a group for source files
        let sourcesGroup = PBXGroup(children: [], sourceTree: .group, name: "Sources")
        xcodeproj.pbxproj.add(object: sourcesGroup)

        // Create a file reference
        let fileRef = PBXFileReference(
            sourceTree: .group, name: "TestFile.swift", path: "TestFile.swift")
        xcodeproj.pbxproj.add(object: fileRef)
        sourcesGroup.children.append(fileRef)

        // Add the sources group to main group
        if let mainGroup = try xcodeproj.pbxproj.rootProject()?.mainGroup {
            mainGroup.children.append(sourcesGroup)
        }

        // Add the file to the target
        if let target = xcodeproj.pbxproj.nativeTargets.first(where: { $0.name == "TestTarget" }) {
            let buildFile = PBXBuildFile(file: fileRef)
            xcodeproj.pbxproj.add(object: buildFile)

            if let sourcesBuildPhase = target.buildPhases.first(where: {
                $0 is PBXSourcesBuildPhase
            }) as? PBXSourcesBuildPhase {
                sourcesBuildPhase.files?.append(buildFile)
            }
        }

        try xcodeproj.write(path: projectPath)

        // Execute the tool with target filter
        let result = try tool.execute(arguments: [
            "project_path": Value.string(projectPath.string),
            "target_name": Value.string("TestTarget"),
        ])

        // Verify the result
        if case let .text(message) = result.content.first {
            #expect(message.contains("Groups and folder references in target 'TestTarget':"))
            #expect(message.contains("- Sources"))
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("Handles non-existent target")
    func handlesNonExistentTarget() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Create a test project
        let projectPath = Path(tempDir) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProject(name: "TestProject", at: projectPath)

        // Try to list groups for a non-existent target
        #expect(throws: MCPError.self) {
            try tool.execute(arguments: [
                "project_path": Value.string(projectPath.string),
                "target_name": Value.string("NonExistentTarget"),
            ])
        }
    }

    @Test("Shows no groups message for target with no files")
    func showsNoGroupsMessageForTargetWithNoFiles() throws {
        let tool = ListGroupsTool(pathUtility: pathUtility)

        // Create a test project with a target but no files
        let projectPath = Path(tempDir) + "TestProject.xcodeproj"
        try TestProjectHelper.createTestProjectWithTarget(
            name: "TestProject", targetName: "EmptyTarget", at: projectPath)

        // Execute the tool with target filter
        let result = try tool.execute(arguments: [
            "project_path": Value.string(projectPath.string),
            "target_name": Value.string("EmptyTarget"),
        ])

        // Verify the result
        if case let .text(message) = result.content.first {
            #expect(message.contains("Groups and folder references in target 'EmptyTarget':"))
            #expect(message.contains("No groups or folder references found for target 'EmptyTarget'."))
        } else {
            Issue.record("Expected text result")
        }
    }
}
