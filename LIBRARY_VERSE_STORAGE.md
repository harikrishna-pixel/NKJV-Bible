# How library data is stored for Daily Verse and other verses

This describes the **current app code**. Library items (bookmark, highlight, underline, notes) live in their own tables. Daily Verse is a **schedule + copied verse text**. It does not store bookmarks or highlights itself.

---

## 1. Three places verse-related data can live

| Store | Tables | What it holds | Library data? |
|--------|--------|----------------|---------------|
| Bible reader | `verse` | Full Bible text + flags on each row | Flags only (mirror) |
| My Library | `bookmark`, `highlight`, `underline`, `save_notes` | The user’s saved items | **Yes — source of truth** |
| Daily Verse | `dailyVersesMainList`, `dailyVerses`, `dailyVersesnew` | Category, date, book/chapter/verse ref, **copied** verse text | **No** |

Also in the same DB, but not verse-library: `calendar`, `save_images` (wallpaper / quote images). Those are included in library backup, not in Daily Verse.

---

## 2. Other verses (Home / reader)

When the user bookmarks, highlights, underlines, or notes a verse in the reader, the app writes **two** things.

### A. Flag on the `verse` row (for display)

`verse` columns:

- `id`
- `book_num`, `chapter_num`, `verse_num`
- `content` (HTML verse text)
- `is_read`
- `is_bookmarked` (`yes` / `no`)
- `is_underlined` (`yes` / `no`)
- `is_highlighted` (color, or `no`)
- `is_noted` (note text, or `no`)

Update is by verse `id`:

```text
UPDATE verse SET <flag> = <value> WHERE id = ?
```

Code: `DBHelper.updateVersesData` in `lib/controller/dpProvider.dart`.  
Toggle path: `lib/core/notifiers/bottom.notifier.dart` (`HomeContentEditProvider`).

### B. Row in the matching library table (for My Library)

| Action | Library table | Typical fields |
|--------|----------------|----------------|
| Bookmark | `bookmark` | `book_num`, `chapter_num`, `verse_num`, `content`, `plaincontent`, `bookName`, `timestamp` |
| Highlight | `highlight` | same location + `plain_content`, `verse_id`, `book_name`, `color` |
| Underline | `underline` | same as bookmark (`plaincontent`, `bookName`) |
| Note | `save_notes` | location + `content`, `plaincontent`, `book_name`, `notes` |

Inserts: `insertBookmark`, `insertHighlight`, `insertUnderLine`, `insertNotes`.  
Removes: delete by `content`, and set the `verse` flag back to `no`.

My Library screens (`bookMarkScreen`, `highlight_screen`, `underLine_screen`, `notes_screen`) read these tables, not Daily Verse tables.

---

## 3. Daily Verse — what is stored

Daily Verse is **not** a second library. It only stores which verse to show and a **copy of the text** from `verse`.

### Catalog (reference only)

`dailyVersesMainList` — filled from `assets/jsonFile/dailyVerse.json`:

- `Category_Name`, `Category_Id`
- `Book`, `Book_Id`
- `Chapter`
- `Verse` — verse **number** (or range like `16-17`), not the Bible text

### Scheduled days (what the UI lists)

`dailyVerses` and `dailyVersesnew`:

- Same category / book / chapter
- `Date`
- `Verse_Num`
- `Verse` — **copied `verse.content`** from the Bible table

How the text is copied (`DownloadProvider._insertDailyVersesFromMainList` and Bible select `loadDailyVerseData`):

```text
1. Resolve book_num from book name / Book_Id
2. Resolve chapter_num + verse_num (1-based Daily Verse ref → DB)
3. SELECT * FROM verse
     WHERE book_num = ? AND chapter_num = ? AND verse_num = ?
4. Insert that row’s content into dailyVerses / dailyVersesnew.Verse
```

`dailyVersesnew` is used when the user has selected Daily Verse categories. `dailyVerses` is the fallback list.

These Daily Verse tables have **no** `is_bookmarked`, `is_highlighted`, `is_underlined`, or `is_noted` columns.

---

## 4. How library data attaches to a Daily Verse

Daily Verse itself does not save library items.

Typical path:

1. User opens Daily Verse (home sheet or `DailyVerse` screen).
2. Text shown is the **copied** `Verse` string (plus book / chapter / verse number).
3. **Read** opens Home at that book / chapter / verse (`From: "Daily"`).
4. User bookmarks / highlights / underlines / notes on the **reader verse**.
5. That writes:
   - flags on the matching `verse` row
   - a row in `bookmark` / `highlight` / `underline` / `save_notes`

After that, My Library shows the item. Opening Daily Verse again still shows the scheduled copy; the library mark is on the **same Bible verse**, not on the Daily Verse row.

If the user later opens that chapter in the reader, the flags on `verse` show the bookmark / color / underline / note.

---

## 5. Matching library items back onto verses

`verse.id` can change when the Bible table is rebuilt (version switch / reload). Library rows stay.

`LibraryVerseFlagsSync.reapplyToVerseTable` (`lib/utils/library_verse_flags_sync.dart`) reads My Library, then stamps flags on `verse` by **plain text** (HTML stripped), not by id:

| Library | Verse flag |
|---------|------------|
| bookmark | `is_bookmarked = yes` |
| highlight | `is_highlighted = <color>` |
| underline | `is_underlined = yes` |
| save_notes | `is_noted = <note text>` |

Same idea as splash `updateLocalDB`. Library rows are not rewritten.

---

## 6. What is backed up (and what is not)

Library cloud / manual backup (`ExportDb` + `LibraryBackupUploadService`) includes:

- `bookmark`
- `highlight`
- `underline`
- `save_notes`
- `calendar`
- `save_images`

It does **not** include:

- `verse` (full Bible)
- `dailyVersesMainList` / `dailyVerses` / `dailyVersesnew`

After restore, flags are reapplied onto `verse` by content match (above). Daily Verse lists are rebuilt from JSON + the active Bible `verse` table.

---

## 7. Short flow

```text
JSON catalog  →  dailyVersesMainList  (book / chapter / verse number)
                      ↓
              lookup verse table
                      ↓
         dailyVerses / dailyVersesnew  (date + copied text)
                      ↓
         UI: Daily Verse sheet / list
                      ↓
         Read → Home reader (same book/chapter/verse)
                      ↓
         User mark  →  verse flags  +  library table row
                      ↓
         My Library lists  /  reader shows flags
```

---

## 8. Main files

| Role | File |
|------|------|
| DB schema + library insert/update | `lib/controller/dpProvider.dart` |
| Reader bookmark / underline / note | `lib/core/notifiers/bottom.notifier.dart` |
| Daily Verse copy from `verse` + load list | `lib/core/notifiers/download.notifier.dart` |
| Seed Daily Verse from JSON | `lib/view/screens/bible_select_screen.dart` |
| Daily Verse UI | `lib/view/screens/dashboard/dailyverse.dart`, home sheet in `home_screen.dart` |
| Re-stamp flags after Bible reload | `lib/utils/library_verse_flags_sync.dart` |
| Library backup | `lib/core/export_db.dart`, `lib/core/library_backup_upload_service.dart` |
