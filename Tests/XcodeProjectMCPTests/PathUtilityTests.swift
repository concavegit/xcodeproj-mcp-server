import Foundation
import Testing
@testable import XcodeProjectMCP

struct PathUtilityTests {
    
    @Test func testRelativePathResolution() throws {
        // Simulate Docker mount path
        let basePath = "/workspace"
        let pathUtility = PathUtility(basePath: basePath)
        
        // Test relative path resolution
        let relativePath = "MyApp.xcodeproj"
        let resolved = try pathUtility.resolvePath(from: relativePath)
        
        #expect(resolved == "/workspace/MyApp.xcodeproj")
    }
    
    @Test func testNestedRelativePathResolution() throws {
        let basePath = "/workspace"
        let pathUtility = PathUtility(basePath: basePath)
        
        let nestedPath = "Projects/MyApp.xcodeproj"
        let resolved = try pathUtility.resolvePath(from: nestedPath)
        
        #expect(resolved == "/workspace/Projects/MyApp.xcodeproj")
    }
    
    @Test func testAbsolutePathWithinWorkspace() throws {
        let basePath = "/workspace"
        let pathUtility = PathUtility(basePath: basePath)
        
        let absolutePath = "/workspace/MyApp.xcodeproj"
        let resolved = try pathUtility.resolvePath(from: absolutePath)
        
        #expect(resolved == "/workspace/MyApp.xcodeproj")
    }
    
    @Test func testPathOutsideWorkspaceThrows() throws {
        let basePath = "/workspace"
        let pathUtility = PathUtility(basePath: basePath)
        
        let outsidePath = "/etc/passwd"
        
        #expect(throws: PathError.self) {
            _ = try pathUtility.resolvePath(from: outsidePath)
        }
    }
    
    @Test func testDotDotPathResolution() throws {
        let basePath = "/workspace/projects"
        let pathUtility = PathUtility(basePath: basePath)
        
        // This should resolve to /workspace/projects/MyApp.xcodeproj
        let dotPath = "./MyApp.xcodeproj"
        let resolved = try pathUtility.resolvePath(from: dotPath)
        
        #expect(resolved == "/workspace/projects/MyApp.xcodeproj")
    }
    
    @Test func testCurrentDirectoryPath() throws {
        let basePath = "/workspace"
        let pathUtility = PathUtility(basePath: basePath)
        
        // Just a dot should resolve to the base path
        let currentDir = "."
        let resolved = try pathUtility.resolvePath(from: currentDir)
        
        #expect(resolved == "/workspace")
    }
}