# BookShelf - Personal Library Management System

A comprehensive book collection manager that rivals commercial apps like Goodreads, but keeps everything local and private.

## Overview

Build a complete library management system with:

- ISBN scanning and book cataloging
- Reading progress tracking
- Discovery and recommendations
- Rich reviews and notes
- Collection organization with shelves

## Running with RalphLoop

```bash
# Run with 15 iterations (path is relative to /workspace inside container)
RALPH_PROMPT_FILE=/workspace/examples/book-collection/prompt.md npm run container:run 15

# Or set RALPH_PROMPT directly from the file
RALPH_PROMPT="$(cat examples/book-collection/prompt.md)" npm run container:run 15
```

> **Note:** `RALPH_PROMPT_FILE` paths are relative to `/workspace` inside the container.

## Key Features

### Collection Management

- ISBN barcode scanning
- Auto-fetch book covers from Open Library/Google Books
- Track physical books, ebooks, and audiobooks
- Edition and location tracking

### Reading Progress

- Set reading goals (annual/quarterly)
- Track current page and completion percentage
- Reading streaks and speed calculations
- Re-read tracking with ratings

### Discovery

- Search Open Library, Google Books, ISBN DB
- Author pages and series management
- "Based on your reads" recommendations
- Curated lists and reading challenges

## Files

- `prompt.md` - Complete project specification for RalphLoop
