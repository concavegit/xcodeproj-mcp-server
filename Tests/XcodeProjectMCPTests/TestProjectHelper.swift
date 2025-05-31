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
}