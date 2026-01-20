# Docker Hub Publishing

This document explains how to publish the RalphLoop Docker image to Docker Hub.

## Setup

### 1. Create Docker Hub Access Token

1. Go to [Docker Hub Settings](https://hub.docker.com/settings/security)
2. Click "New Access Token"
3. Give it a descriptive name (e.g., "github-actions-ralphloop")
4. Copy the token value

### 2. Add Secrets to GitHub Repository

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:
   - **Name:** `DOCKER_USERNAME`
     **Value:** Your Docker Hub username

   - **Name:** `DOCKER_PASSWORD`
     **Value:** Your Docker Hub access token (not your password)

### 3. Verify GitHub Container Registry (Default)

The workflow automatically pushes to GitHub Container Registry (GHCR) as `ghcr.io/<owner>/<repo>:tag`.

## Image References

### GitHub Container Registry (Default)

```bash
# Pull from GHCR
podman pull ghcr.io/<your-username>/ralphloop:latest

# Or with Docker
docker pull ghcr.io/<your-username>/ralphloop:latest
```

### Docker Hub (After Setup)

```bash
# Pull from Docker Hub
podman pull <your-username>/ralphloop:latest

# Or with Docker
docker pull <your-username>/ralphloop:latest
```

## Running the Image

### With Podman

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  ghcr.io/<your-username>/ralphloop:latest bash ./ralph 1
```

### With Docker

```bash
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  ghcr.io/<your-username>/ralphloop:latest bash ./ralph 1
```

## Troubleshooting

### Manifest Not Found Error

If you see:

```
no matching manifest for linux/amd64 in the manifest list entries
```

Ensure you're using the correct image reference. The image must be built for your architecture.

### Authentication Issues

- Verify GitHub secrets are set correctly
- Ensure access token has correct permissions
- Check that repository is public for GHCR, or configure `packages: read` permission

### Multi-Platform Build Issues

If builds fail for certain platforms:

- Check GitHub Actions runner availability
- Verify Docker Buildx is properly set up in the workflow
- Some platforms may require additional QEMU emulation setup
