# Use official Swift runtime as base image
FROM swift:6.1-jammy

# Set the working directory
WORKDIR /app

# Copy package files
COPY Package.swift Package.resolved ./

# Copy source code
COPY Sources/ Sources/
COPY Tests/ Tests/

# Build the project in release mode
RUN swift build -c release

# Create a non-root user
RUN useradd -m -s /bin/bash xcodeproj

# Change ownership of the app directory
RUN chown -R xcodeproj:xcodeproj /app

# Switch to non-root user
USER xcodeproj

# Expose the port if needed (MCP typically uses stdio)
# EXPOSE 8080

# Set the entrypoint to run the MCP server
ENTRYPOINT ["/app/.build/release/xcodeproj-mcp-server"]
CMD []