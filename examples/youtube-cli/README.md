# TubeMaster - YouTube Media Suite

A professional-grade YouTube media management CLI tool that serves as your personal YouTube media library manager.

## Overview

Build a comprehensive YouTube download and management tool with:

- Smart download engine with queue management
- Local media library with organization
- Metadata extraction and management
- Watch history and favorites

## Running with RalphLoop

```bash
# Run with 10 iterations (path is relative to /workspace inside container)
RALPH_PROMPT_FILE=/workspace/examples/youtube-cli/prompt.md npm run container:run 10

# Or set RALPH_PROMPT directly from the file
RALPH_PROMPT="$(cat examples/youtube-cli/prompt.md)" npm run container:run 10
```

> **Note:** `RALPH_PROMPT_FILE` paths are relative to `/workspace` inside the container.

## Key Features

### Download Engine

- Intelligent queue with automatic retry
- Format selection (video, audio, quality)
- Playlist and channel downloads
- Bandwidth control and scheduling

### Library Management

- SQLite database for tracking downloads
- Organized file structure by channel/playlist
- Metadata extraction and storage
- Smart caching to skip duplicates

### Media Tools

- Audio extraction (MP3, AAC, FLAC, etc.)
- Subtitle download and management
- Watch history tracking
- Favorites and playlists

## Files

- `prompt.md` - Complete project specification for RalphLoop
