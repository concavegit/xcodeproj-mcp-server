# GitHub Container Registry (GHCR) Setup Instructions

Since this is a forked repository, you'll need to set up GitHub Container Registry access for the Docker workflow to work properly.

## Prerequisites

- GitHub repository with Actions enabled
- Admin access to the repository settings

## Setup Steps

### 1. Enable GitHub Container Registry

The workflow is already configured to use GitHub Container Registry (`ghcr.io`) with these settings:
- Registry: `ghcr.io`
- Image name: `{owner}/{repository-name}` (automatically derived from `github.repository`)

### 2. Configure Repository Settings

1. Go to your repository settings
2. Navigate to **Settings** → **Actions** → **General**
3. Under "Workflow permissions", ensure either:
   - **Read and write permissions** is selected, OR
   - **Read repository contents and packages permissions** is selected

### 3. Package Permissions (if needed)

If you encounter permission issues:

1. Go to your GitHub profile
2. Click **Packages** tab
3. Find your package (it will be created after the first successful build)
4. Click on the package name
5. Go to **Package settings**
6. Under **Manage Actions access**, ensure your repository has write access

### 4. Current Workflow Configuration

The workflow in `.github/workflows/docker-publish.yml` is configured to:

- **Trigger on**: pushes to `main` branch and version tags (`*.*.*`)
- **Registry**: `ghcr.io` (GitHub Container Registry)  
- **Authentication**: Uses `GITHUB_TOKEN` (automatically provided)
- **Image name**: `ghcr.io/{owner}/{repo}` where `{owner}/{repo}` comes from `github.repository`
- **Platforms**: Now builds for both `linux/amd64` and `linux/arm64`

### 5. Image Tags

The workflow automatically creates these tags:
- `latest` (for main branch)
- Branch name (for pushes to branches)
- Version tags (for semver releases like `v1.0.0`)

### 6. Manual Configuration (Alternative)

If you need to hardcode the registry settings, you can modify the `env` section in `.github/workflows/docker-publish.yml`:

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ghcr.io/yourusername/xcodeproj-mcp-server
```

Replace `yourusername` with your actual GitHub username.

### 7. Testing the Setup

1. Push to the `main` branch or create a version tag
2. Check the **Actions** tab in your repository
3. Monitor the "Docker" workflow execution
4. Once successful, check **Packages** in your GitHub profile to see the published images

### 8. Using the Images

After successful build, you can pull images for both architectures:

```bash
# Pull latest (multi-arch, Docker will select appropriate platform)
docker pull ghcr.io/yourusername/xcodeproj-mcp-server:latest

# Pull specific architecture
docker pull --platform linux/amd64 ghcr.io/yourusername/xcodeproj-mcp-server:latest
docker pull --platform linux/arm64 ghcr.io/yourusername/xcodeproj-mcp-server:latest
```

## Troubleshooting

- **403 Forbidden**: Check repository workflow permissions
- **Package not found**: Ensure the workflow has run successfully at least once
- **Authentication failed**: Verify `GITHUB_TOKEN` has proper permissions

The `GITHUB_TOKEN` is automatically provided by GitHub Actions and doesn't need manual configuration.