# YouTube URL Processor - CLI Tool

Build a command-line tool for downloading YouTube URLs and generating transcripts.

## Core Features

### URL Processing

- Accept single URL or file with multiple URLs (one per line)
- Support various YouTube URL formats:
  - `https://www.youtube.com/watch?v=VIDEO_ID`
  - `https://youtu.be/VIDEO_ID`
  - `https://www.youtube.com/shorts/VIDEO_ID`
- Validate URLs before processing
- Skip already-downloaded content (idempotent)

### Audio Download

- Download YouTube video as audio (MP3 format)
- Default quality: 192kbps (configurable)
- Include video metadata in ID3 tags:
  - Title
  - Artist (uploader)
  - Album (video title)
  - Release date
  - Cover art (video thumbnail)
- Output filename format: `ARTIST - TITLE.mp3`

### Transcript Generation

- Generate transcripts from YouTube videos
- Support auto-generated and manual captions
- Preserve timestamps in VTT format
- Generate plain text version (no timestamps)
- Language detection (default: English)

### Output Structure

```
output/
├── audio/
│   └── ARTIST - TITLE.mp3
├── transcripts/
│   └── VIDEO_ID/
│       ├── transcript.vtt
│       └── transcript.txt
└── metadata/
    └── VIDEO_ID.json
```

## Technical Requirements

### Stack

- Node.js v23.x with npm
- No global dependencies (use npx for tools)
- Use yt-dlp for downloading (install via npm)
- Configuration via config file or CLI flags

### CLI Interface

```bash
youtube-processor [OPTIONS] URL_OR_FILE

Options:
  -o, --output-dir PATH    Output directory (default: ./output)
  -q, --quality BITRATE    Audio quality in kbps (default: 192)
  -f, --format FORMAT      Output format: mp3, m4a, wav (default: mp3)
  -t, --transcript         Generate transcript (default: true)
  --no-transcript          Skip transcript generation
  --include-metadata       Save video metadata JSON (default: true)
  --overwrite              Re-download existing files
  --concurrency N          Parallel downloads (default: 1)
  -h, --help               Show help
  --version                Show version
```

### Error Handling

- Graceful handling of unavailable videos
- Clear error messages with exit codes
- Resume capability for interrupted downloads
- Rate limiting to avoid IP blocks
- Logging to file and stdout

## Example Usage

```bash
# Download single video with transcript
npx youtube-processor "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Process multiple URLs from file
npx youtube-processor urls.txt

# Download high-quality audio without transcript
npx youtube-processor -q 320 -t false -o /music "https://youtu.be/VIDEO_ID"

# Parallel download with overwrite
npx youtube-processor --concurrency 3 --overwrite urls.txt
```

## Success Criteria

- [ ] CLI tool installs and runs without errors
- [ ] Downloads audio from various YouTube URL formats
- [ ] Generates transcripts with timestamps
- [ ] Includes proper ID3 tags on audio files
- [ ] Handles errors gracefully with clear messages
- [ ] Idempotent (skips already downloaded)
- [ ] Configurable via CLI and config file
- [ ] Code is well-documented and maintainable
- [ ] Includes package.json with proper bin entry
- [ ] README with usage examples
