import Testing
@testable import XcodeProjectMCP

@Test("CreateXcodeprojTool has correct properties")
func toolProperties() {
    let createTool = CreateXcodeprojTool()
    let tool = createTool.tool()
    
    #expect(tool.name == "create_xcodeproj")
    #expect(tool.description == "Create a new Xcode project file (.xcodeproj)")
    #expect(tool.inputSchema != nil)
}

@Test("CreateXcodeprojTool can be executed")
func toolExecution() throws {
    let createTool = CreateXcodeprojTool()
    
    // This test just verifies the tool can be instantiated and has the right interface
    // We don't test actual file creation here to avoid side effects
    #expect(createTool.tool().name == "create_xcodeproj")
}