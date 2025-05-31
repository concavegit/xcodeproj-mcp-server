import Foundation
import XcodeProj
import PathKit

struct TestProjectHelper {
    static func createTestProject(name: String, at path: Path) throws {
        // Create the .pbxproj file using XcodeProj
        let pbxproj = PBXProj()
        
        // Create project groups
        let mainGroup = PBXGroup(sourceTree: .group)
        pbxproj.add(object: mainGroup)
        let productsGroup = PBXGroup(children: [], sourceTree: .group, name: "Products")
        pbxproj.add(object: productsGroup)
        
        // Create build configurations
        let debugConfig = XCBuildConfiguration(name: "Debug", buildSettings: [:])
        let releaseConfig = XCBuildConfiguration(name: "Release", buildSettings: [:])
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
            name: name,
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
        try xcodeproj.write(path: path)
    }
    
    static func createTestProjectWithTarget(name: String, targetName: String, at path: Path) throws {
        // Create the .pbxproj file using XcodeProj
        let pbxproj = PBXProj()
        
        // Create project groups
        let mainGroup = PBXGroup(sourceTree: .group)
        pbxproj.add(object: mainGroup)
        let productsGroup = PBXGroup(children: [], sourceTree: .group, name: "Products")
        pbxproj.add(object: productsGroup)
        
        // Create build configurations for project
        let debugConfig = XCBuildConfiguration(name: "Debug", buildSettings: [:])
        let releaseConfig = XCBuildConfiguration(name: "Release", buildSettings: [:])
        pbxproj.add(object: debugConfig)
        pbxproj.add(object: releaseConfig)
        
        // Create configuration list for project
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfig, releaseConfig],
            defaultConfigurationName: "Release"
        )
        pbxproj.add(object: configurationList)
        
        // Create target build configurations
        let targetDebugConfig = XCBuildConfiguration(name: "Debug", buildSettings: [
            "PRODUCT_NAME": .string(targetName),
            "BUNDLE_IDENTIFIER": .string("com.example.\(targetName)")
        ])
        let targetReleaseConfig = XCBuildConfiguration(name: "Release", buildSettings: [
            "PRODUCT_NAME": .string(targetName),
            "BUNDLE_IDENTIFIER": .string("com.example.\(targetName)")
        ])
        pbxproj.add(object: targetDebugConfig)
        pbxproj.add(object: targetReleaseConfig)
        
        // Create target configuration list
        let targetConfigurationList = XCConfigurationList(
            buildConfigurations: [targetDebugConfig, targetReleaseConfig],
            defaultConfigurationName: "Release"
        )
        pbxproj.add(object: targetConfigurationList)
        
        // Create target
        let target = PBXNativeTarget(
            name: targetName,
            buildConfigurationList: targetConfigurationList,
            productType: .application
        )
        pbxproj.add(object: target)
        
        // Create project
        let project = PBXProject(
            name: name,
            buildConfigurationList: configurationList,
            compatibilityVersion: "Xcode 14.0",
            preferredProjectObjectVersion: 56,
            minimizedProjectReferenceProxies: 0,
            mainGroup: mainGroup,
            developmentRegion: "en",
            knownRegions: ["en", "Base"],
            productsGroup: productsGroup,
            targets: [target]
        )
        pbxproj.add(object: project)
        pbxproj.rootObject = project
        
        // Create workspace
        let workspaceData = XCWorkspaceData(children: [])
        let workspace = XCWorkspace(data: workspaceData)
        
        // Create xcodeproj
        let xcodeproj = XcodeProj(workspace: workspace, pbxproj: pbxproj)
        
        // Write project
        try xcodeproj.write(path: path)
    }
}