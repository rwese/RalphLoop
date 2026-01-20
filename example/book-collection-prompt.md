# BookShelf - Personal Library Management System

Build a comprehensive book collection manager for book lovers who want to catalog, discover, and manage their personal library. Features should rival commercial apps like Goodreads but keep everything local and private.

## Core Features

### Collection Management

- **ISBN Scanning**: Scan ISBN barcodes with camera (web) or barcode scanner (CLI)
- **Manual Entry**: Add books with title, author, ISBN, publisher, year, genre, pages, format
- **Book Covers**: Auto-fetch covers from Open Library, Google Books, or upload custom
- **Multiple Formats**: Track physical books, ebooks (Kindle, EPUB, PDF), audiobooks
- **Conditions**: Track book condition (new, like new, good, fair, poor)
- **Edition Tracking**: Track specific editions, multiple copies
- **Location Tracking**: Where is each book (which shelf, box, Kindle device, etc.)
- **Acquisition**: Track when/where bought, price, condition at purchase

### Reading Progress

- **Reading Status**: Want to read, currently reading, read, abandoned, on hold
- **Current Page/Progress**: Track current page, percentage complete
- **Reading Dates**: Start date, finish date, last read date
- **Reading Speed**: Calculate pages/hour, estimate completion
- **Reading Streaks**: Track consecutive days reading
- **Re-read Tracking**: Track multiple reads with dates and ratings
- **Reading Goals**: Set annual/quarterly reading goals, track progress
- **Current Read**: Special "Currently Reading" shelf with prominent display

### Discovery & Recommendations

- **Book Search**: Search Open Library, Google Books, ISBN DB
- **Author Pages**: View all books by an author, add to collection
- **Series Management**: Group books into series, track reading order
- **Related Books**: "People who read this also read..."
- **Recommendation Engine**: "Based on your reads, try these..."
- **Curated Lists**: Create custom lists (favorites, gift ideas, to-buy)
- **Reading Challenges**: Join or create reading challenges
- **Book Clubs**: Link with reading groups, discussion questions

### Reviews & Notes

- **Rich Reviews**: Star ratings (1-5), written reviews with formatting
- **Private Notes**: Personal notes, quotes, thoughts (private or shareable)
- **Public Reviews**: Optional: share reviews publicly
- **Community Ratings**: Show average community rating alongside personal
- **Reading Challenges**: Notes for book clubs or personal reflection
- **Quote Collection**: Save favorite quotes from books
- **Progress Notes**: Track thoughts as you read (chapter by chapter)

### Shelves & Organization

- **Custom Shelves**: Create unlimited custom shelves ("Sci-Fi Favorites", "Summer 2024")
- **Smart Shelves**: Auto-populate shelves based on rules (rating > 4 stars, unread > 1 year)
- **Shelf Sharing**: Share read-only shelves with friends
- **Sorting**: Sort by title, author, rating, date added, date read, progress
- **Filtering**: Filter by genre, author, format, rating, status, tags
- **Tags**: Flexible tagging system (themes, mood, setting, time period)
- **Bookmarks**: Save current page across sessions

### Statistics & Insights

- **Library Stats**: Total books, pages, genres breakdown, authors
- **Reading Stats**: Books read this year/all time, pages read, average rating
- **Reading Trends**: Books read per month, year comparison
- **Genre Distribution**: Pie chart of genres in collection
- **Author Diversity**: Track reading by author diversity
- **Reading Pace**: Pages per day/week/month/year trends
- **Achievements**: Badges for milestones (100 books, 50k pages, etc.)
- **Year in Review**: Annual reading summary with insights

## Technical Requirements

### Stack (Choose One)

#### Option A: Web App (Recommended)

- Single HTML file with embedded CSS/JS
- localStorage + IndexedDB for storage
- No external dependencies
- Responsive design for mobile/desktop

#### Option B: CLI Tool

- Node.js v23.x with npm
- SQLite database
- Blessed/Ink for TUI
- NeDB or better-sqlite3 for storage

### Data Sources

- **Open Library API**: Free, comprehensive book data
- **Google Books API**: Good cover images, some content
- **ISBN DB**: ISBN lookup (requires API key for some features)
- **Cache Strategy**: Cache API responses, rate limiting

### CLI Interface (if CLI)

```bash
# Library commands
bookshelf list                    # List all books
bookshelf add <isbn>              # Add by ISBN
bookshelf search <query>          # Search online
bookshelf show <id>               # Show book details
bookshelf edit <id>               # Edit book
bookshelf delete <id>             # Delete book
bookshelf import <file>           # Import CSV/JSON
bookshelf export <file>           # Export collection

# Reading commands
bookshelf reading                 # Currently reading
bookshelf read                    # Show read books
bookshelf want                    # Want to read
bookshelf progress <id>           # Update progress
bookshelf start <id>              # Start reading
bookshelf finish <id>             # Mark as finished

# Shelves & Organization
bookshelf shelves                 # List shelves
bookshelf shelf <name>            # Show shelf
bookshelf shelf-create <name>     # Create shelf
bookshelf shelf-add <shelf> <id>  # Add book to shelf
bookshelf tag <id> <tag>          # Add tag
bookshelf rate <id> <1-5>         # Set rating
bookshelf review <id>             # Add/edit review

# Statistics
bookshelf stats                   # Library statistics
bookshelf year <year>             # Reading history for year
bookshelf challenge <year>        # Reading challenge

# Interactive mode
bookshelf interactive             # TUI mode
bookshelf i                       # Shorthand
```

### Data Model

```typescript
interface Book {
  id: string;
  isbn: string;
  title: string;
  subtitle?: string;
  authors: string[];
  publisher?: string;
  publishedDate?: string;
  pageCount?: number;
  genres: string[];
  tags: string[];
  format: 'physical' | 'kindle' | 'epub' | 'pdf' | 'audiobook';
  language?: string;
  condition?: 'new' | 'like-new' | 'good' | 'fair' | 'poor';
  location?: string; // shelf, device, box
  coverUrl?: string;
  description?: string;
  series?: string;
  seriesNumber?: number;
  edition?: string;
  notes?: string;
  purchaseDate?: string;
  purchasePrice?: number;
  purchaseLocation?: string;
  currentPage?: number;
  status: 'want-to-read' | 'reading' | 'on-hold' | 'read' | 'abandoned';
  rating?: number; // 1-5
  review?: string;
  startDate?: string;
  finishDate?: string;
  lastReadDate?: string;
  dateAdded: string;
  dateModified: string;
  readingSessions?: ReadingSession[];
}

interface ReadingSession {
  date: string;
  startPage: number;
  endPage: number;
  duration?: number; // minutes
  notes?: string;
}
```

### Import/Export

- **Import Formats**: CSV, JSON, Goodreads export, LibraryThing export
- **Export Formats**: CSV, JSON, Markdown (readable list), HTML (gallery)
- **Backup**: Full database backup to single file
- **Selective Export**: Export by shelf, genre, or date range

## Example Usage Scenarios

### Scenario 1: Quick Book Entry

```
1. Open app, press "Scan ISBN" or press 'n'
2. Type or scan ISBN: 9780316769488
3. App auto-fetches book data from Open Library
4. Shows cover, title "The Catcher in the Rye", author J.D. Salinger
5. Select format: "Physical", condition: "Good", shelf: "Classics"
6. Press Enter to add to collection
```

### Scenario 2: Track Reading Progress

```
1. Click "Currently Reading" shelf
2. Select book in progress (currently page 142 of 320)
3. Update current page to 175
4. App shows: 55% complete, estimated 4 hours remaining
5. Add quick note: "Loving the character development"
6. App tracks reading session: 33 pages in 25 minutes
```

### Scenario 3: Year-End Review

```
1. Go to Statistics > Year in Review
2. See: "2024: You read 42 books (goal: 40) ✅"
3. Total pages: 14,328
4. Average rating: 3.8 stars
5. Top genres: Sci-Fi (12), Fantasy (8), Literary Fiction (6)
6. Favorite month: July (6 books)
7. Longest book: 1,200 pages
8. Generated shareable image for social media
```

### Scenario 4: Find Your Next Read

```
1. Click "Discover" tab
2. See "Recommended for You" based on:
   - High-rated books you read
   - Authors you love
   - Genres you read most
3. See "Because you read Project Hail Mary..."
4. Browse recommendations, click one for details
5. Add to "Want to Read" shelf
6. Share recommendation with friend
```

### Scenario 5: Catalog Physical Library

```
1. Use CLI: bookshelf import library_thing_export.csv
2. App matches ISBNs, fetches covers
3. Identifies duplicates (multiple copies of same book)
4. Groups by location (Living Room Shelf A, Bedroom Box B)
5. Generates shelf map/location guide
6. Stats show: 847 books total, 89% read, 3% unread
```

## Success Criteria

- [ ] **Easy Entry**: Add books in under 30 seconds (auto-fetch helps)
- [ ] **Rich Data**: Fetches covers, descriptions, author info automatically
- [ ] **Track Reading**: Update progress in seconds, no friction
- [ ] **Beautiful Library**: Grid view with covers looks like a real bookshelf
- [ ] **Great Discovery**: Recommendations feel personal and relevant
- [ ] **Insightful Stats**: Stats feel meaningful, not just numbers
- [ ] **Works Offline**: Can add books, update progress without internet
- [ ] **Import/Export**: Easy migration from Goodreads/LibraryThing
- [ ] **Private**: All data local, no account required
- [ ] **Mobile Friendly**: Use on phone at the bookstore

## Bonus Features

- [ ] **Book Club Mode**: Discussion questions, voting on next book
- [ ] **Loan Tracking**: Track books lent to friends, send reminders
- [ ] **Wishlist**: Books to buy, track prices, alert on sales
- [ ] **Reading Quotes**: "Quote of the Day" from your collection
- [ ] **Social Features**: Share shelves/reviews with friends (local network)
- [ ] **Gamification**: Reading badges, streaks, leaderboards
- [ ] **Ebook Integration**: Sync Kindle highlights, progress from devices
- [ ] **Audiobook Sync**: Integrate with Audible, Libby
- [ ] **Reading Goals**: Monthly/quarterly/yearly targets
- [ ] **Book Covers**: Generate shelf view visualization
- [ ] **API**: Expose data for other apps
- [ ] **Web Server**: Browser-based UI from CLI tool
- [ ] **AI Summaries**: Generate AI-powered book summaries
- [ ] **Mood Reading**: Match books to current mood
