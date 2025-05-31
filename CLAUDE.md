# xcodeproj-mcp-server

A Model Context Protocol (MCP) server for manipulating Xcode project files (.xcodeproj) using Swift.

## Overview

This project provides an MCP server that enables interaction with Xcode projects through a standardized protocol. It leverages the [tuist/xcodeproj](https://github.com/tuist/xcodeproj) library for project manipulation and the [modelcontextprotocol/swift-sdk](https://github.com/modelcontextprotocol/swift-sdk) for MCP functionality.

## Architecture

- **Language**: Swift
- **Platform**: macOS 13+
- **Dependencies**:
  - ModelContextProtocol (MCP Swift SDK)
  - XcodeProj (Xcode project manipulation)

## Available Tools

### Core Operations
- `create_xcodeproj` - Create a new Xcode project with basic configuration
- `list_targets` - List all targets in an Xcode project
- `list_build_configurations` - List all build configurations
- `list_files` - List all files in the project
- `get_build_settings` - Get build settings for a specific target

### File Management
- `add_file` - Add a file to the Xcode project
- `remove_file` - Remove a file from the Xcode project
- `move_file` - Move or rename a file within the project
- `create_group` - Create a new group in the project navigator

### Target Management
- `add_target` - Create a new target
- `remove_target` - Remove an existing target
- `add_dependency` - Add dependency between targets
- `set_build_setting` - Modify build settings for a target

### Advanced Operations
- `add_framework` - Add framework dependencies
- `add_build_phase` - Add custom build phases
- `duplicate_target` - Duplicate an existing target

## Implementation Status

✅ **Completed**:
- Project initialization
- Package.swift with dependencies
- Basic MCP server structure
- CreateXcodeprojTool implementation

🚧 **Planned**:
- Implementation of remaining tools
- Error handling and validation
- Unit tests
- Documentation

## Building and Running

```bash
# Build the project
swift build

# Run the MCP server
swift run xcodeproj-mcp-server
```

## Usage Example

The server responds to MCP tool calls. Example of creating a new Xcode project:

```json
{
  "tool": "create_xcodeproj",
  "arguments": {
    "project_name": "MyApp",
    "path": "/path/to/projects",
    "organization_name": "My Company",
    "bundle_identifier": "com.mycompany"
  }
}
```

## Development Notes

- Each tool is implemented as a separate Swift file in the Sources directory
- Tools conform to the `Tool` protocol from ModelContextProtocol
- XcodeProj library handles the low-level .xcodeproj file manipulation
- Error handling uses custom ToolError enum for consistent error reporting