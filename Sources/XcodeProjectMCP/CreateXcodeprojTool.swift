import Foundation
import MCP
import XcodeProj

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
        
        // Note: bundleIdentifier could be used in future enhancements
        _ = bundleIdentifier
        
        let projectPath = URL(fileURLWithPath: pathString).appendingPathComponent("\(projectName).xcodeproj")
        
        do {
            // Create a minimal xcodeproj structure
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: projectPath, withIntermediateDirectories: true)
            
            let pbxprojPath = projectPath.appendingPathComponent("project.pbxproj")
            
            // Create minimal project.pbxproj content
            let pbxprojContent = """
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
		
/* Begin PBXProject section */
		\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)) /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
				};
			};
			buildConfigurationList = \(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)) /* Build configuration list for PBXProject "\(projectName)" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = \(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24));
			projectDirPath = "";
			projectRoot = "";
			targets = (
			);
		};
/* End PBXProject section */

/* Begin XCBuildConfiguration section */
		\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)) /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ORGANIZATION_NAME = "\(organizationName)";
			};
			name = Debug;
		};
		\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)) /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ORGANIZATION_NAME = "\(organizationName)";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)) /* Build configuration list for PBXProject "\(projectName)" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)) /* Debug */,
				\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)) /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = \(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24)) /* Project object */;
}
"""
            
            try pbxprojContent.write(to: pbxprojPath, atomically: true, encoding: .utf8)
            
            return CallTool.Result(
                content: [
                    .text("Successfully created Xcode project at: \(projectPath.path)")
                ]
            )
        } catch {
            throw MCPError.internalError("Failed to create Xcode project: \(error.localizedDescription)")
        }
    }
}

