import Foundation
import MCP
import PathKit
import XcodeProj

public struct RemoveSwiftPackageTool: Sendable {
  private let pathUtility: PathUtility

  public init(pathUtility: PathUtility) {
    self.pathUtility = pathUtility
  }

  public func tool() -> Tool {
    Tool(
      name: "remove_swift_package",
      description: "Remove a Swift Package dependency from an Xcode project",
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
          "project_path": .object([
            "type": .string("string"),
            "description": .string("Path to the .xcodeproj file (relative to current directory)"),
          ]),
          "package_url": .object([
            "type": .string("string"),
            "description": .string("URL of the Swift Package repository to remove"),
          ]),
          "remove_from_targets": .object([
            "type": .string("boolean"),
            "description": .string("Whether to remove package from all targets (default: true)"),
          ]),
        ]),
        "required": .array([.string("project_path"), .string("package_url")]),
      ])
    )
  }

  public func execute(arguments: [String: Value]) throws -> CallTool.Result {
    guard case let .string(projectPath) = arguments["project_path"],
      case let .string(packageURL) = arguments["package_url"]
    else {
      throw MCPError.invalidParams("project_path and package_url are required")
    }

    let removeFromTargets: Bool
    if case let .bool(remove) = arguments["remove_from_targets"] {
      removeFromTargets = remove
    } else {
      removeFromTargets = true
    }

    do {
      // Resolve and validate the project path
      let resolvedProjectPath = try pathUtility.resolvePath(from: projectPath)
      let projectURL = URL(fileURLWithPath: resolvedProjectPath)

      let xcodeproj = try XcodeProj(path: Path(projectURL.path))

      guard let project = try xcodeproj.pbxproj.rootProject() else {
        throw MCPError.internalError("Unable to access project root")
      }

      // Find the package to remove
      guard
        let packageIndex = project.remotePackages.firstIndex(where: {
          $0.repositoryURL == packageURL
        })
      else {
        return CallTool.Result(
          content: [
            .text("Swift Package '\(packageURL)' not found in project")
          ]
        )
      }

      let packageRef = project.remotePackages[packageIndex]

      // Remove package product dependencies from all targets if requested
      if removeFromTargets {
        for target in xcodeproj.pbxproj.nativeTargets {
          // Find and remove product dependencies that reference this package
          if let dependencies = target.packageProductDependencies {
            let dependenciesToRemove = dependencies.filter { dependency in
              dependency.package === packageRef
            }

            for dependency in dependenciesToRemove {
              // Remove from target
              target.packageProductDependencies?.removeAll { $0 === dependency }

              // Remove from pbxproj objects
              xcodeproj.pbxproj.delete(object: dependency)
            }
          }
        }
      }

      // Remove package reference from project
      project.remotePackages.remove(at: packageIndex)

      // Remove from pbxproj objects
      xcodeproj.pbxproj.delete(object: packageRef)

      // Save project
      try xcodeproj.write(path: Path(projectURL.path))

      var message = "Successfully removed Swift Package '\(packageURL)' from project"
      if removeFromTargets {
        message += " and all targets"
      }

      return CallTool.Result(
        content: [
          .text(message)
        ]
      )
    } catch {
      throw MCPError.internalError(
        "Failed to remove Swift Package from Xcode project: \(error.localizedDescription)")
    }
  }
}