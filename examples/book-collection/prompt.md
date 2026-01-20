# BookShelf - Personal Library Management System

Build a comprehensive book collection manager for book lovers who want to catalog, discover, and manage their personal library. Features should rival commercial apps like Goodreads but keep everything local and private.

## Core Features

### Collection Management

- **ISBN Scanning**: Scan ISBN barcodes with camera; Automatically pre-fills the add-book dialog with fetched book data (title, author, cover, etc.)
- **Manual Entry**: Add books with title, author, ISBN, publisher, year, genre, pages, format
- **Book Covers**: Auto-fetch covers from Open Library, Google Books, or upload custom images; Upload cover images with built-in crop, zoom, and pan controls for perfect framing; Generate beautiful shelf view visualization with realistic bookshelf display
- **Multiple Formats**: Track physical books, ebooks (Kindle, EPUB, PDF), audiobooks
- **Conditions**: Track book condition (new, like new, good, fair, poor)
- **Edition Tracking**: Track specific editions, multiple copies
- **Acquisition**: Track when/where bought, price, condition at purchase
- **Beautiful Library**: Stunning visual display with cover art; Grid, list, and shelf view modes; Smooth animations and transitions; Dark/light theme with customizable colors

### Reading Progress

- **Reading Status**: Track books across statuses: want to read, currently reading, read, abandoned, on hold; Easily move books between statuses with one click

### Comment

- **Comment Books**: Leave a comment for your book.

### Shelves & Organization

- **Custom Shelves**: Create unlimited custom shelves ("Sci-Fi Favorites", "Summer 2024")
- **Smart Shelves**: Auto-populate shelves based on rules (rating > 4 stars, unread > 1 year)
- **Sorting**: Sort by title, author, rating, date added, date read, progress
- **Filtering**: Filter by genre, author, format, rating, status, tags
- **Tags**: Flexible tagging system (themes, mood, setting, time period)

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

### Stack

#### Web App

- Single HTML file with embedded CSS/JS
- localStorage + IndexedDB for storage
- No external dependencies
- Responsive design for mobile/desktop

### Data Sources

- **Open Library API**: Free, comprehensive book data
- **Google Books API**: Good cover images, some content
- **ISBN DB**: ISBN lookup (requires API key for some features)
- **Cache Strategy**: Cache API responses, rate limiting

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
  coverUrl?: string; // URL or base64 data for book cover image
  coverColor?: string; // Dominant color for placeholder/spine
  coverAdjustments?: {
    x: number; // Pan offset X
    y: number; // Pan offset Y
    scale: number; // Zoom level
  };
  description?: string;
  series?: string;
  seriesNumber?: number;
  edition?: string;
  notes?: string;
  purchaseDate?: string;
  purchasePrice?: number;
  purchaseLocation?: string;
  status: 'want-to-read' | 'reading' | 'on-hold' | 'read' | 'abandoned';
  rating?: number; // 1-5
  review?: string;
  startDate?: string;
  finishDate?: string;
  lastReadDate?: string;
  dateAdded: string;
  dateModified: string;
}
```

## Testing Requirements

### Test Suite Structure

Create a `tests/` directory with the following test files:

- **`tests/library.test.js`** - Collection management tests
  - Book creation (manual and ISBN fetch)
  - Book editing and updates
  - Book deletion and restore
  - Multiple format handling
  - Condition tracking
  - Edition tracking

- **`tests/shelves.test.js`** - Shelves and organization tests
  - Custom shelf creation and management
  - Smart shelf rule creation
  - Sorting functionality
  - Filtering by all attributes
  - Tag management

- **`tests/progress.test.js`** - Reading progress tests
  - Status transitions (want-to-read -> reading -> read)
  - Progress tracking (pages read, percentage)
  - Reading streaks and statistics
  - Date-based tracking (startDate, finishDate, lastReadDate)

- **`tests/api.test.js`** - External API tests
  - Open Library API integration
  - Google Books API integration
  - ISBN DB lookup
  - Cache behavior
  - Rate limiting handling
  - Error handling for API failures

- **`tests/import-export.test.js`** - Import/export tests
  - CSV import and parsing
  - JSON import/export
  - Goodreads export parsing
  - Data validation on import
  - Duplicate detection

### Browser Test Execution

Tests should be runnable in browser console:

```javascript
// Include test runner in app
if (window.location.search.includes('runTests')) {
  TestRunner.runAll();
}
```

### Success Criteria

- [ ] **Tests Pass**: All test suites pass with 100% pass rate
- [ ] **API Coverage**: All external API integrations tested
- [ ] **Import/Export**: All import/export formats tested
- [ ] **Data Integrity**: No data loss during operations
- [ ] **No Regressions**: Tests catch breaking changes

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

### Scenario 2: Year-End Review

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

### Scenario 3: Import Your Library

```

1. Go to Import section
2. Upload CSV export from Goodreads, LibraryThing, or other services
3. App matches ISBNs, fetches covers and metadata
4. Identifies duplicates (multiple copies of same book)
5. Shows import preview with match confidence
6. Confirm import to add all books to collection

```

## Success Criteria

- [ ] **Easy Entry**: Add books in under 30 seconds (auto-fetch helps)
- [ ] **Rich Data**: Fetches covers, descriptions, author info automatically
- [ ] **Beautiful Library**: Grid view with covers looks like a real bookshelf; Generate stunning shelf view visualization for sharing and printing
- [ ] **Insightful Stats**: Stats feel meaningful, not just numbers
- [ ] **Works Offline**: Can add books, update status without internet
- [ ] **Import/Export**: Easy migration from Goodreads/LibraryThing
- [ ] **Private**: All data local, no account required
- [ ] **Mobile Friendly**: Use on phone at the bookstore
- [ ] **Tested**: All core functionality has automated tests

## Bonus Features

- [ ] **Reading Quotes**: "Quote of the Day" from your collection
- [ ] **Gamification**: Reading badges
