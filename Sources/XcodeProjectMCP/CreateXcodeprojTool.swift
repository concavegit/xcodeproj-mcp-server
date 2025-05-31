import Foundation
import MCP
import XcodeProj
import PathKit

public struct CreateXcodeprojTool: Sendable {
    public func tool() -> Tool {
        Tool(
            name: "create_xcodeproj",
            description: "Create a new Xcode project file (.xcodeproj)",
            inputSchema: .object([
                "project_name": .object([
                    "type": .string("string"),
                    "description": .string("Name of the Xcode project")
                ]),
                "path": .object([
                    "type": .string("string"),
                    "description": "Directory path where the project will be created"
                ]),
                "organization_name": .object([
                    "type": .string("string"),
                    "description": .string("Organization name for the project")
                ]),
                "bundle_identifier": .object([
                    "type": .string("string"),
                    "description": .string("Bundle identifier prefix")
                ])
            ])
        )
    }
    
    public func execute(arguments: [String: Value]) throws -> CallTool.Result {
        guard case let .string(projectName) = arguments["project_name"],
              case let .string(pathString) = arguments["path"] else {
            throw MCPError.invalidParams("project_name and path are required")
        }
        
        let organizationName: String
        if case let .string(org) = arguments["organization_name"] {
            organizationName = org
        } else {
            organizationName = ""
        }
        
        let bundleIdentifier: String
        if case let .string(bundle) = arguments["bundle_identifier"] {
            bundleIdentifier = bundle
        } else {
            bundleIdentifier = "com.example"
        }
        
        let projectPath = Path(pathString) + "\(projectName).xcodeproj"
        
        do {
            // Create the .pbxproj file using XcodeProj
            let pbxproj = PBXProj()
            
            // Create project groups
            let mainGroup = PBXGroup(sourceTree: .group)
            pbxproj.add(object: mainGroup)
            let productsGroup = PBXGroup(children: [], sourceTree: .group, name: "Products")
            pbxproj.add(object: productsGroup)
            
            // Create build configurations
            let debugConfig = XCBuildConfiguration(name: "Debug", buildSettings: [
                "ORGANIZATION_NAME": .string(organizationName)
            ])
            let releaseConfig = XCBuildConfiguration(name: "Release", buildSettings: [
                "ORGANIZATION_NAME": .string(organizationName)
            ])
            pbxproj.add(object: debugConfig)
            pbxproj.add(object: releaseConfig)
            
            // Create configuration list
            let configurationList = XCConfigurationList(
                buildConfigurations: [debugConfig, releaseConfig],
                defaultConfigurationName: "Release"
            )
            pbxproj.add(object: configurationList)
            
            // Create project
            let project = PBXProject(
                name: projectName,
                buildConfigurationList: configurationList,
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
            
            // Create workspace
            let workspaceData = XCWorkspaceData(children: [])
            let workspace = XCWorkspace(data: workspaceData)
            
            // Create xcodeproj
            let xcodeproj = XcodeProj(workspace: workspace, pbxproj: pbxproj)
            
            // Write project
            try xcodeproj.write(path: projectPath)
            
            return CallTool.Result(
                content: [
                    .text("Successfully created Xcode project at: \(projectPath.string)")
                ]
            )
        } catch {
            throw MCPError.internalError("Failed to create Xcode project: \(error.localizedDescription)")
        }
    }
}

