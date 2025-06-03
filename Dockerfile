# Build stage
FROM swift:6.1 AS builder

# Set the working directory
WORKDIR /app

# Copy package files first for better caching
COPY Package.swift Package.resolved ./

# Fetch dependencies (separate layer for caching)
RUN swift package resolve

# Copy source code
COPY Sources/ Sources/
COPY Tests/ Tests/

# Build the project in release mode
RUN swift build -c release --static-swift-stdlib

# Runtime stage
FROM swift:6.1-slim

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcurl4 \
    libxml2 \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash xcodeproj

# Set the working directory
WORKDIR /app

# Copy only the built binary from builder stage
COPY --from=builder /app/.build/release/xcodeproj-mcp-server /app/

# Change ownership
RUN chown -R xcodeproj:xcodeproj /app

# Switch to non-root user
USER xcodeproj

# Set the entrypoint to run the MCP server
ENTRYPOINT ["/app/xcodeproj-mcp-server"]