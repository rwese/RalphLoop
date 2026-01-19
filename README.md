# RalphLoop

Autonomous development system that runs itself.

## Quick Start

```bash
# Run the autonomous loop
./ralph.sh 1

# Build and run Docker image
docker build -t ralphloop .
docker run -it --rm -v "$(pwd):/workspace" ralphloop bash ./ralph.sh 1
```

## Image

Published to GitHub Container Registry:

```
ghcr.io/<owner>/<repo>:latest
```

## License

MIT
