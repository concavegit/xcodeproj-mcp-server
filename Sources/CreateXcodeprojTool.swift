import Foundation
import ModelContextProtocol
import XcodeProj

struct CreateXcodeprojTool: Tool {
    let name = "create_xcodeproj"
    let description = "Create a new Xcode project file (.xcodeproj)"
    
    let inputSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "project_name": [
                "type": "string",
                "description": "Name of the Xcode project"
            ],
            "path": [
                "type": "string", 
                "description": "Directory path where the project will be created"
            ],
            "organization_name": [
                "type": "string",
                "description": "Organization name for the project",
                "default": ""
            ],
            "bundle_identifier": [
                "type": "string",
                "description": "Bundle identifier prefix",
                "default": "com.example"
            ]
        ],
        "required": ["project_name", "path"]
    ]
    
    func execute(arguments: [String: Any]) async throws -> ToolResult {
        guard let projectName = arguments["project_name"] as? String,
              let pathString = arguments["path"] as? String else {
            throw ToolError.invalidArguments("project_name and path are required")
        }
        
        let organizationName = arguments["organization_name"] as? String ?? ""
        let bundleIdentifier = arguments["bundle_identifier"] as? String ?? "com.example"
        
        let projectPath = URL(fileURLWithPath: pathString).appendingPathComponent("\(projectName).xcodeproj")
        
        // Create new Xcode project
        let project = PBXProject(name: projectName, buildSettings: BuildSettingsDictionary())
        let pbxproj = PBXProj(project: project)
        
        // Add main target
        let target = PBXNativeTarget(
            name: projectName,
            buildConfigurationList: nil,
            buildPhases: [],
            buildRules: [],
            dependencies: [],
            productName: projectName,
            product: nil,
            productType: .application
        )
        
        // Create build configurations
        let debugConfig = XCBuildConfiguration(
            name: "Debug",
            buildSettings: [
                "PRODUCT_NAME": projectName,
                "PRODUCT_BUNDLE_IDENTIFIER": "\(bundleIdentifier).\(projectName)",
                "ORGANIZATION_NAME": organizationName,
                "DEVELOPMENT_TEAM": "",
                "CODE_SIGN_STYLE": "Automatic",
                "TARGETED_DEVICE_FAMILY": "1,2"
            ]
        )
        
        let releaseConfig = XCBuildConfiguration(
            name: "Release", 
            buildSettings: [
                "PRODUCT_NAME": projectName,
                "PRODUCT_BUNDLE_IDENTIFIER": "\(bundleIdentifier).\(projectName)",
                "ORGANIZATION_NAME": organizationName,
                "DEVELOPMENT_TEAM": "",
                "CODE_SIGN_STYLE": "Automatic",
                "TARGETED_DEVICE_FAMILY": "1,2"
            ]
        )
        
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfig, releaseConfig],
            defaultConfigurationName: "Release"
        )
        
        target.buildConfigurationList = configurationList
        
        // Add target to project
        project.targets.append(target)
        
        // Create XcodeProj
        let xcodeproj = XcodeProj(pbxproj: pbxproj)
        
        do {
            try xcodeproj.write(path: projectPath)
            
            return ToolResult(
                content: [
                    TextContent(text: "Successfully created Xcode project at: \(projectPath.path)")
                ]
            )
        } catch {
            throw ToolError.executionFailed("Failed to create Xcode project: \(error.localizedDescription)")
        }
    }
}

enum ToolError: Error {
    case invalidArguments(String)
    case executionFailed(String)
}