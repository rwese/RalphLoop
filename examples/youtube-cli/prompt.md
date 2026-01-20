# TubeMaster - Pro YouTube Media Suite

Build a professional-grade YouTube media management CLI tool that power users would rely on daily. Think of it as your personal YouTube media library manager.

## Core Features

### Download Engine

- **Smart Downloads**: Intelligent download queue with automatic retry, resume from interruption
- **Format Selection**: Choose video, audio only, or both; select quality (4K, 1080p, 720p, 480p)
- **Audio Extraction**: Extract audio in multiple formats (MP3, AAC, FLAC, WAV, OPUS)
- **Playlist Support**: Download entire playlists, specify range (e.g., "download songs 5-20")
- **Channel Download**: Download all videos from a channel, with pagination support
- **Scheduled Downloads**: Queue downloads for off-peak hours
- **Smart Caching**: Skip already downloaded files, detect changed videos (re-uploaded)
- **Bandwidth Control**: Rate limiting, time-based throttling (slower at certain hours)

### Media Library Management

- **Local Database**: SQLite database tracking all downloads with metadata
- **Library Organization**:

  ```
  library/
  ├── podcasts/
  │   ├── Language Learning/
  │   │   ├── Coffee Break Spanish/
  │   │   │   ├── Season 1/
  │   │   │   │   ├── S1E01 - Greetings.mp3
  │   │   │   │   └── S1E02 - Introductions.mp3
  │   │   │   └── metadata.json
  │   │   └── EnglishClass101/
  └── music/
      ├── Artist - Song.mp3
      └── metadata.json
  ```

- **Deduplication**: Detect duplicates by content, not just filename
- **Tags & Playlists**: Organize downloaded media into custom playlists
- **Search**: Full-text search across downloaded library by title, description, transcript
- **Statistics**: View download history, total size, most played, listening time

### Metadata & Enrichment

- **Auto Tagging**: Embed ID3v2 tags in MP3/AAC files (title, artist, album, artwork, release date)
- **Album Art**: Fetch high-quality thumbnails, embed in audio files
- **Lyrics**: Fetch lyrics when available (Genius API integration optional)
- **Chapters**: Extract video chapters for long content
- **Transcript Export**: Generate text, VTT, SRT formats with speaker detection
- **Description**: Include video description in metadata file
- **Thumbnail Archive**: Save thumbnails in multiple sizes

### Integration Features

- **Music Player Sync**: Sync playlists to music players (iPod, Android, foobar2000)
- **Podcast Feeds**: Generate RSS feeds from downloaded content for podcast apps
- **Smart Playlists**: "Newest from subscriptions", "Unplayed", "Most Played"
- **Webhook Notifications**: Call webhook on download complete (for automation)
- **API Server**: Expose REST API for other tools (web UI, mobile app)
- **Keyboard Shortcuts** (when in interactive mode):
  - `j/k` or `↑/↓` - Navigate
  - `space` - Toggle selection
  - `d` - Download selected
  - `p` - Play in default player
  - `q` - Quit

### CLI Interface

```bash
# Core commands
tubemaster download <url>              # Download single video/audio
tubemaster playlist <url>              # Download entire playlist
tubemaster search <query>              # Search YouTube
tubemaster library                     # Browse local library
tubemaster sync                        # Sync to devices
tubemaster playlist                    # Manage playlists

# Options
-o, --output <path>                    # Output directory (default: ~/TubeMaster)
-f, --format <format>                  # Video: mp4|mkv|webm (default: mp4)
-a, --audio <format>                   # Audio: mp3|aac|flac|wav|opus (default: mp3)
-q, --quality <quality>                # Quality: 4k|1080p|720p|480p|360p (default: 720p)
--no-audio                             # Video only, no audio
--no-video                             # Audio only
--extract-audio                        # Extract audio after download
--add-to-playlist <name>               # Add to playlist after download
--download-archive <file>              # Don't re-download archived videos
--cookies <file>                       # Use cookies for age-restricted content
--rate-limit <speed>                   # Limit download speed (e.g., 5M)
--max-downloads <n>                    # Parallel downloads (default: 1)
--transcript                           # Generate transcript (default: true)
--no-transcript                        # Skip transcript
--thumbnail                            # Download thumbnail images
--metadata                             # Save metadata JSON (default: true)
--embed-thumbnail                      # Embed thumbnail in audio file
--force                                # Overwrite existing files
--dry-run                              # Preview without downloading

# Management commands
tubemaster library list                # List all downloads
tubemaster library search <query>      # Search library
tubemaster library stats               # Show storage usage, counts
tubemaster library clean               # Remove broken/incomplete files
tubemaster playlist create <name>      # Create new playlist
tubemaster playlist add <name> <url>   # Add video to playlist
tubemaster playlist export <name>      # Export playlist to file
tubemaster playlist import <file>      # Import playlist
tubemaster sync device <name>          # Sync to connected device

# Configuration
tubemaster config show                 # Show current config
tubemaster config set <key> <value>    # Set config value
tubemaster config reset                # Reset to defaults

# Interactive mode
tubemaster interactive                 # Enter interactive TUI mode
tubemaster i                            # Shorthand
```

## Technical Requirements

### Stack

- **Node.js v23.x** with npm/npx
- **TypeScript** with strict mode (compiles in build step)
- **SQLite** with better-sqlite3 for local database
- **yt-dlp** as download engine (install via npm or standalone)
- **fluent-ffmpeg** for media processing
- **chalk** for colored terminal output
- **Ink** or **Blessed** for interactive TUI
- **Conf** for config file management
- **Execa** for subprocess management

### Configuration

Config file location: `~/.config/tubemaster/config.json`

```json
{
  "downloadsDir": "~/TubeMaster",
  "defaultFormat": "mp3",
  "defaultQuality": "720p",
  "audioBitrate": 192,
  "extractAudio": true,
  "includeMetadata": true,
  "includeTranscripts": true,
  "embedThumbnails": true,
  "maxConcurrent": 2,
  "rateLimit": null,
  "downloadSchedule": {
    "enabled": true,
    "start": "02:00",
    "end": "06:00"
  },
  "playbackDevice": null,
  "webhookUrl": null,
  "theme": "dark"
}
```

### Error Handling

- **Graceful Degradation**: Continue on single download failure, report all errors
- **Exit Codes**: 0=success, 1=general error, 2=usage error, 3=download partially failed
- **Detailed Logging**: JSON logs to file, pretty to stdout
- **Progress Bars**: Real-time progress with ETA for each download
- **Disk Space Alerts**: Warn when low disk space, auto-pause
- **Network Retry**: Exponential backoff for network errors (max 3 retries)

## Testing Requirements

### Test Suite Structure

Create a `tests/` directory with the following test files:

- **`tests/unit/download.test.ts`** - Download engine unit tests
  - URL parsing and validation
  - Format selection logic
  - Quality detection
  - Retry mechanism behavior
  - Rate limiting calculations

- **`tests/unit/library.test.ts`** - Library management unit tests
  - Database operations (SQLite)
  - Metadata parsing and generation
  - Deduplication algorithms
  - Tag management
  - Search functionality

- **`tests/unit/metadata.test.ts`** - Metadata tests
  - ID3v2 tag generation
  - Album art embedding
  - Thumbnail processing
  - Transcript extraction
  - Chapter detection

- **`tests/integration/cli.test.ts`** - CLI integration tests
  - Command parsing and argument handling
  - All CLI commands (download, playlist, channel, library, etc.)
  - Option processing
  - Exit codes
  - Help output validation

- **`tests/integration/download.test.ts`** - Download integration tests
  - Full download workflow
  - Playlist downloading
  - Channel downloading
  - Resume from interruption
  - Multiple concurrent downloads

- **`tests/fixtures/`** - Test fixtures
  - Sample video metadata
  - Sample playlists
  - Mock API responses
  - Test media files

### Test Configuration

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts'],
    },
  },
});
```

### Running Tests

```bash
# Run all tests
npm test

# Run unit tests only
npm run test:unit

# Run integration tests only
npm run test:integration

# Run with coverage
npm run test:coverage

# Watch mode for development
npm run test:watch
```

### CI Configuration

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '23'
      - run: npm ci
      - run: npm run test:coverage
```

### Success Criteria

- [ ] **Tests Pass**: All test suites pass with 100% pass rate
- [ ] **Coverage**: Minimum 80% code coverage
- [ ] **Unit Tests**: All utility functions and logic tested
- [ ] **Integration Tests**: CLI commands fully tested
- [ ] **No Regressions**: CI catches breaking changes
- [ ] **Fast Tests**: Full test suite runs in under 2 minutes
- [ ] **Isolated**: Tests don't require network or external services

### Performance

- **Smart Queue**: Prioritize downloads, queue management
- **Memory Efficient**: Stream processing, no full file buffering
- **Parallel Processing**: Concurrent downloads + audio extraction
- **Cache Strategy**: Cache API responses, thumbnails, metadata

## Example Usage Scenarios

### Scenario 1: Build Music Library

```bash
# Download playlist of favorite music videos, extract audio
tubemaster playlist "https://youtube.com/playlist?list=PLxxx" \
  --extract-audio --audio mp3 --quality 720p \
  --add-to-playlist "Favorites"

# Later, sync to phone
tubemaster sync device "Pixel 7"
```

### Scenario 2: Podcast Archive

```bash
# Download podcast channel, generate RSS feed
tubemaster channel "https://www.youtube.com/@PodcastChannel" \
  --output ~/TubeMaster/podcasts \
  --format audio --audio aac \
  --add-to-playlist "Tech Podcasts"

# Generate RSS for podcast app
tubemaster rss generate ~/TubeMaster/podcasts/Tech\ Podcasts \
  --title "Tech Podcast Archive" \
  --url "https://myserver.com/feed.xml"
```

### Scenario 3: Offline Learning

```bash
# Download course videos for offline viewing
tubemaster playlist "https://youtube.com/playlist?list=PLcourse" \
  --format mp4 --quality 1080p \
  --output ~/Courses/Python

# Include transcripts for searching
tubemaster playlist "https://youtube.com/playlist?list=PLcourse" \
  --transcript --output ~/Courses/Python

# Search within transcripts later
tubemaster library search "python list comprehension" \
  --transcript
```

### Scenario 4: Batch Night Download

```bash
# Queue multiple downloads for off-peak hours
cat <<EOF > downloads.txt
https://youtube.com/watch?v=video1
https://youtube.com/watch?v=video2
https://youtube.com/playlist?list=playlist1
EOF

tubemaster download downloads.txt \
  --download-archive ~/.tubemaster/archive.txt \
  --rate-limit 10M \
  --schedule
```

## Success Criteria

- [ ] **Installs cleanly**: `npm install -g tubemaster` works on macOS/Linux
- [ ] **No external deps**: yt-dlp bundled or easy install
- [ ] **Fast downloads**: Parallel processing, resume support
- [ ] **Great audio**: High-quality audio extraction with proper tags
- [ ] **Searchable library**: Full-text search across titles and transcripts
- [ ] **Syncs well**: Works with common music players and devices
- [ ] **Beautiful TUI**: Interactive mode feels professional
- [ ] **Robust**: Handles errors, network issues, partial downloads
- [ ] **Well documented**: --help for every command, examples in README
- [ ] **Configurable**: Sensible defaults, easy customization
- [ ] **Tested**: All functionality has automated tests

## Bonus Features

- [ ] **Web Dashboard**: Simple web UI for library management
- [ ] **Smart Recommendations**: "You might also like" based on downloads
- [ ] **Cloud Sync**: Sync library across machines (optional S3/Google Drive)
- [ ] **AI Summaries**: Generate AI summaries of video content
- [ ] **Share Server**: Stream content to other devices on network
- [ ] **Voice Commands**: Voice control for interactive mode
- [ ] **Mobile App**: React Native companion app
- [ ] **Plugin System**: Third-party plugins for custom integrations
