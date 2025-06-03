import Foundation
import XcodeProj
import MCP
import PathKit

public struct AddTargetTool: Sendable {
    private let pathUtility: PathUtility
    
    public init(pathUtility: PathUtility) {
        self.pathUtility = pathUtility
    }
    
    public func tool() -> Tool {
        Tool(
            name: "add_target",
            description: "Create a new target",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "project_path": .object([
                        "type": .string("string"),
                        "description": .string("Path to the .xcodeproj file")
                    ]),
                    "target_name": .object([
                        "type": .string("string"),
                        "description": .string("Name of the target to create")
                    ]),
                    "product_type": .object([
                        "type": .string("string"),
                        "description": .string("Product type (app, framework, staticLibrary, dynamicLibrary, unitTestBundle, uiTestBundle)")
                    ]),
                    "bundle_identifier": .object([
                        "type": .string("string"),
                        "description": .string("Bundle identifier for the target")
                    ]),
                    "platform": .object([
                        "type": .string("string"),
                        "description": .string("Platform (iOS, macOS, tvOS, watchOS) - optional, defaults to iOS)")
                    ]),
                    "deployment_target": .object([
                        "type": .string("string"),
                        "description": .string("Deployment target version (optional)")
                    ])
                ]),
                "required": .array([.string("project_path"), .string("target_name"), .string("product_type"), .string("bundle_identifier")])
            ])
        )
    }
    
    public func execute(arguments: [String: Value]) throws -> CallTool.Result {
        guard case let .string(projectPath) = arguments["project_path"],
              case let .string(targetName) = arguments["target_name"],
              case let .string(productTypeString) = arguments["product_type"],
              case let .string(bundleIdentifier) = arguments["bundle_identifier"] else {
            throw MCPError.invalidParams("project_path, target_name, product_type, and bundle_identifier are required")
        }
        
        let platform: String
        if case let .string(plat) = arguments["platform"] {
            platform = plat
        } else {
            platform = "iOS"
        }
        
        let deploymentTarget: String?
        if case let .string(target) = arguments["deployment_target"] {
            deploymentTarget = target
        } else {
            deploymentTarget = nil
        }
        
        // Map product type string to PBXProductType
        let productType: PBXProductType
        switch productTypeString.lowercased() {
        case "app", "application":
            productType = .application
        case "framework":
            productType = .framework
        case "staticlibrary", "static_library":
            productType = .staticLibrary
        case "dynamiclibrary", "dynamic_library":
            productType = .dynamicLibrary
        case "unittestbundle", "unit_test_bundle":
            productType = .unitTestBundle
        case "uitestbundle", "ui_test_bundle":
            productType = .uiTestBundle
        default:
            throw MCPError.invalidParams("Invalid product type: \(productTypeString)")
        }
        
        do {
            // Resolve and validate the project path
            let resolvedProjectPath = try pathUtility.resolvePath(from: projectPath)
            let projectURL = URL(fileURLWithPath: resolvedProjectPath)
            
            let xcodeproj = try XcodeProj(path: Path(projectURL.path))
        
        // Check if target already exists
        if xcodeproj.pbxproj.nativeTargets.contains(where: { $0.name == targetName }) {
            return CallTool.Result(
                content: [
                    .text("Target '\(targetName)' already exists in project")
                ]
            )
        }
        
        // Create build configurations for target
        let targetDebugConfig = XCBuildConfiguration(name: "Debug", buildSettings: [
            "PRODUCT_NAME": .string(targetName),
            "BUNDLE_IDENTIFIER": .string(bundleIdentifier),
            "INFOPLIST_FILE": .string("\(targetName)/Info.plist"),
            "SWIFT_VERSION": .string("5.0"),
            "TARGETED_DEVICE_FAMILY": .string(platform == "iOS" ? "1,2" : "1"),
        ])
        
        let targetReleaseConfig = XCBuildConfiguration(name: "Release", buildSettings: [
            "PRODUCT_NAME": .string(targetName),
            "BUNDLE_IDENTIFIER": .string(bundleIdentifier),
            "INFOPLIST_FILE": .string("\(targetName)/Info.plist"),
            "SWIFT_VERSION": .string("5.0"),
            "TARGETED_DEVICE_FAMILY": .string(platform == "iOS" ? "1,2" : "1"),
        ])
        
        // Add deployment target if specified
        if let deploymentTarget = deploymentTarget {
            let deploymentKey = platform == "iOS" ? "IPHONEOS_DEPLOYMENT_TARGET" : 
                               platform == "macOS" ? "MACOSX_DEPLOYMENT_TARGET" :
                               platform == "tvOS" ? "TVOS_DEPLOYMENT_TARGET" : 
                               "WATCHOS_DEPLOYMENT_TARGET"
            targetDebugConfig.buildSettings[deploymentKey] = .string(deploymentTarget)
            targetReleaseConfig.buildSettings[deploymentKey] = .string(deploymentTarget)
        }
        
        xcodeproj.pbxproj.add(object: targetDebugConfig)
        xcodeproj.pbxproj.add(object: targetReleaseConfig)
        
        // Create target configuration list
        let targetConfigurationList = XCConfigurationList(
            buildConfigurations: [targetDebugConfig, targetReleaseConfig],
            defaultConfigurationName: "Release"
        )
        xcodeproj.pbxproj.add(object: targetConfigurationList)
        
        // Create build phases
        let sourcesBuildPhase = PBXSourcesBuildPhase()
        xcodeproj.pbxproj.add(object: sourcesBuildPhase)
        
        let resourcesBuildPhase = PBXResourcesBuildPhase()
        xcodeproj.pbxproj.add(object: resourcesBuildPhase)
        
        let frameworksBuildPhase = PBXFrameworksBuildPhase()
        xcodeproj.pbxproj.add(object: frameworksBuildPhase)
        
        // Create target
        let target = PBXNativeTarget(
            name: targetName,
            buildConfigurationList: targetConfigurationList,
            buildPhases: [sourcesBuildPhase, frameworksBuildPhase, resourcesBuildPhase],
            productType: productType
        )
        target.productName = targetName
        xcodeproj.pbxproj.add(object: target)
        
        // Add target to project
        if let project = xcodeproj.pbxproj.rootObject {
            project.targets.append(target)
        }
        
        // Create target folder in main group
        if let project = try xcodeproj.pbxproj.rootProject(),
           let mainGroup = project.mainGroup {
            let targetGroup = PBXGroup(sourceTree: .group, name: targetName)
            xcodeproj.pbxproj.add(object: targetGroup)
            mainGroup.children.append(targetGroup)
        }
        
            // Save project
            try xcodeproj.write(path: Path(projectURL.path))
            
            return CallTool.Result(
                content: [
                    .text("Successfully created target '\(targetName)' with product type '\(productTypeString)' and bundle identifier '\(bundleIdentifier)'")
                ]
            )
        } catch {
            throw MCPError.internalError("Failed to create target in Xcode project: \(error.localizedDescription)")
        }
    }
}

extension PBXProductType {
    var fileExtension: String? {
        switch self {
        case .application:
            return "app"
        case .framework:
            return "framework"
        case .staticLibrary:
            return "a"
        case .dynamicLibrary:
            return "dylib"
        case .unitTestBundle, .uiTestBundle:
            return "xctest"
        default:
            return nil
        }
    }
}