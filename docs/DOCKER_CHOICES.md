# Dockerfile Quick Reference

## Quick Decision Matrix

| Your Need                | Recommended Dockerfile  | Build Time | Image Size | Best For                    |
| ------------------------ | ----------------------- | ---------- | ---------- | --------------------------- |
| **Standard development** | `Dockerfile.minimal`    | Fast       | ~200 MB    | Daily coding, most projects |
| **Full IDE replacement** | `Dockerfile.full`       | Medium     | ~1.5 GB    | Complete dev environment    |
| **Minimal footprint**    | `Dockerfile.alpine`     | Fast       | ~100 MB    | CI/CD, containers, servers  |
| **Production deploy**    | `Dockerfile.production` | Slow       | ~150 MB    | Minimal production image    |

## File Summary

### Dockerfile.minimal (RECOMMENDED)

**Use when:** You need a reliable development environment without bloat.

**Includes:**

- Ubuntu 24.04 base
- Go 1.23.4
- Gastown (gt)
- Beads (bd)
- Git, vim, nano
- curl, ca-certificates

**Commands:**

```bash
docker build -f Dockerfile.minimal -t gastown:minimal .
docker run -it --rm -v $(pwd):/workspace gastown:minimal
```

### Dockerfile.full

**Use when:** You want all tools in one place, including Python, Node.js, Docker.

**Includes:**

- Ubuntu 24.04 base
- Go 1.23.4 with pyenv
- Python 3.12 with uv
- Node.js LTS with nvm
- Docker CLI
- Full development tools (ripgrep, fd, jq, yq, htop, tree)

**Commands:**

```bash
docker build -f Dockerfile.full -t gastown:full .
docker run -it --rm -v $(pwd):/workspace gastown:full
```

### Dockerfile.alpine

**Use when:** Image size is critical and you only need Go/Git.

**Includes:**

- Alpine 3.19 base (5 MB!)
- Go 1.23.4
- Gastown (gt)
- Beads (bd)
- Git, vim, bash

**Commands:**

```bash
docker build -f Dockerfile.alpine -t gastown:alpine .
docker run -it --rm -v $(pwd):/workspace gastown:alpine
```

### Dockerfile.production

**Use when:** Building for production, minimal attack surface required.

**Includes:**

- Multi-stage build
- Final image: Alpine + binaries only
- No build tools in final image
- ~150 MB final size

**Commands:**

```bash
docker build -f Dockerfile.production -t gastown:production .
docker run -it --rm gastown:production gt --help
```

## Size Comparison

```
Alpine:      [==========] ~100 MB
Minimal:     [====================] ~200 MB
Production:  [================] ~150 MB
Full:        [========================================] ~1.5 GB
```

## Customization Examples

### Add Your Own Tools

**To minimal Dockerfile:**

```dockerfile
# Add after line 25
RUN apt-get install -y --no-install-recommends \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*
```

**To full Dockerfile:**

```dockerfile
# Add after Python installation
RUN . "$NVM_DIR/nvm.sh" && \
    nvm install 20 && \
    nvm use 20 && \
    npm install -g typescript eslint
```

### Change Go Version

**For all Dockerfiles, change the ARG:**

```dockerfile
ARG GO_VERSION=1.23.4  # Change to your version
```

### Add Custom User

**To any Dockerfile:**

```dockerfile
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID developer && \
    useradd -u $UID -g $GID -m -s /bin/bash developer
USER developer
```

## Common Patterns

### Development with Hot Reload

```bash
# Use volume mount for live code changes
docker run -it --rm \
  -v $(pwd):/workspace \
  -v gastown_cache:/root/.cache \
  gastown:minimal

# In container, run your dev server
gt mayor attach
```

### CI/CD Pipeline

```yaml
# .gitlab-ci.yml example
build:
  image: gastown:production
  script:
    - gt install --git
    - gt rig add myproject
    - cd myproject/crew/yourname
    - gt mayor attach
```

### Docker Compose

```yaml
# docker-compose.yml
version: "3.8"
services:
  gastown:
    build:
      context: .
      dockerfile: Dockerfile.minimal
    volumes:
      - .:/workspace
      - gastown_data:/root/.local
    user: "1000:1000"
    working_dir: /workspace

volumes:
  gastown_data:
```

## Migration Between Versions

### From minimal to full:

```bash
# Stop using minimal
docker stop gastown_container

# Build full version
docker build -f Dockerfile.full -t gastown:full .

# Run full version with same volumes
docker run -it --rm \
  -v $(pwd):/workspace \
  -v gastown_data:/root/.local \
  gastown:full
```

### From full to minimal:

```bash
# Build minimal version
docker build -f Dockerfile.minimal -t gastown:minimal .

# Your data is preserved in volumes
docker run -it --rm \
  -v $(pwd):/workspace \
  -v gastown_data:/root/.local \
  gastown:minimal
```

## Performance Tips

1. **Use BuildKit for faster builds:**

   ```bash
   DOCKER_BUILDKIT=1 docker build -f Dockerfile.minimal -t gastown:minimal .
   ```

2. **Leverage Docker layer caching:**
   - Put things that change less often at the top
   - Group related commands together

3. **Use .dockerignore:**

   ```
   .git
   node_modules
   *.log
   .vscode
   ```

4. **Multi-stage for production:**
   - Always use `Dockerfile.production` for deployments
   - Keeps images small and secure

## Security Considerations

### Minimal Attack Surface

- Use Alpine or production images
- Don't include build tools in production
- Run as non-root user
- Use specific versions, not `latest`

### Scanning Images

```bash
# Install Trivy
brew install trivy

# Scan your image
trivy image gastown:minimal
```

### Regular Updates

```bash
# Rebuild with latest base
docker build -f Dockerfile.minimal --pull -t gastown:minimal .
```

## Quick Commands Reference

```bash
# Build all versions
docker build -f Dockerfile.minimal -t gastown:minimal .
docker build -f Dockerfile.full -t gastown:full .
docker build -f Dockerfile.alpine -t gastown:alpine .
docker build -f Dockerfile.production -t gastown:production .

# Run with podman (same syntax)
podman build -f Dockerfile.minimal -t gastown:minimal .
podman run -it --rm -v $(pwd):/workspace gastown:minimal

# Run with user namespace mapping
docker run -it --rm --user $(id -u):$(id -g) -v $(pwd):/workspace gastown:minimal

# Interactive shell
docker run -it --rm gastown:minimal /bin/bash

# Check image sizes
docker images | grep gastown

# Remove old images
docker rmi $(docker images -f "reference=gastown:*" -q)
```

## Troubleshooting

### Build Fails

```bash
# Enable BuildKit and debug
DOCKER_BUILDKIT=1 docker build --progress=plain -f Dockerfile.minimal -t gastown:minimal .
```

### Permission Denied

```bash
# Check user mapping
id

# Run with explicit user
docker run -it --rm --user 1000:1000 gastown:minimal
```

### Out of Space

```bash
# Clean up
docker system prune -a

# Check disk usage
docker system df
```

## Next Steps

1. **Choose your Dockerfile** based on the matrix above
2. **Customize** the file for your specific needs
3. **Build** the image: `docker build -f <file> -t gastown:<tag> .`
4. **Test** the container: `docker run -it --rm gastown:<tag>`
5. **Integrate** into your workflow with volumes and compose

For complete setup instructions, see [SETUP.md](./SETUP.md).
