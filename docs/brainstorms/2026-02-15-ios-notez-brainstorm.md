# Brainstorm: iOS Notez — Organization-First Notes App

**Date:** 2026-02-15
**Status:** Draft
**Participants:** User, Claude

---

## What We're Building

A native iOS notes app where **organization is the primary feature**, not editing. Designed for users with a large volume of notes who need powerful tools to categorize, tag, search, and manage their collection.

### Core Concept

Notes live in a simple hierarchy: each note optionally belongs to one folder (or stays in "Unsorted Notes"). Notes can have multiple tags for cross-cutting categorization. A hybrid search system lets users construct complex queries visually or via text syntax.

---

## Key Decisions

### Note Model
- **One folder max per note** — folders act as physical locations (like a filesystem), tags act as cross-cutting labels
- **Each note has:** title, body stored as **Markdown source** (rendered on display, edited with a formatting toolbar that manipulates Markdown), optional folder, zero or more tags, pinned status, timestamps (created, modified)
- **Minimal rich text editor** with a formatting toolbar (bold, italic, bullet lists) — toolbar inserts Markdown syntax. Not the focus of the app.

### Folder System
- **One level of nesting** — folders can contain subfolders (one level deep only)
- **"Unsorted Notes"** is a virtual folder showing all notes not assigned to any folder
- **"All Pinned Notes"** is a virtual folder showing all pinned notes across the app
- When a note is moved to a folder, it leaves "Unsorted Notes"
- When a note is removed from a folder, it returns to "Unsorted Notes"
- Folders have **user-assignable colors** for visual differentiation

### Tag System
- Notes can have zero or more tags
- Tags can be **renamed** (updates all notes with that tag)
- Tags can be **merged** (combine multiple tags into one)
- Tag merges are **permanently undoable** — merge history is stored so users can split previously merged tags at any time, restoring original tag assignments
- Tags have **user-assignable colors** for visual differentiation
- Main page shows all tags with note counts

### Main Page Layout
1. Heading: "Your notes"
2. Virtual folder: "All Pinned Notes" (with count)
3. Virtual folder: "Unsorted Notes" (with count)
4. User-created folders (with note counts, including subfolders)
5. User-created tags (with note counts)

### Note List Display
- Default view: **Title + body snippet + tag chips** (configurable in settings)
- Settings toggle: snippet on/off (when off, shows title + tag chips only)
- Pinned notes show a pin indicator

### Navigation
- Tap folder → folder view (pinned notes first, then rest sorted by last modified)
- Tap tag → tag view (pinned notes first, then rest sorted by last modified)
- Tap subfolder → subfolder view (same sort behavior)

### Sort Order
- **Pinned notes always first**, then remaining notes sorted by **last modified** (most recent first)
- No user-configurable sort options (keeping it simple)

### Search System — Hybrid Approach
- **Default mode:** Visual query builder with filter chips
  - Pick tags (OR/AND logic between them)
  - Pick folders (include/exclude)
  - Filter by pinned status
  - Tap chips to toggle logic operators
- **Power mode:** Prefix-based text query syntax (Gmail/GitHub-style)
  - Syntax: `tag:name`, `folder:name`, `AND`, `OR`, `NOT`, parentheses for grouping
  - Example: `(tag:work OR tag:personal) AND NOT folder:archive`
  - Switchable from the visual builder

### Deletion
- **Trash folder** with 30-day auto-purge
- Deleted notes can be restored from trash

### Technical Stack
- **SwiftUI** with iOS 17+ minimum deployment target
- **GRDB.swift** (SQLite) for persistence — chosen for complex query support
- **Repository pattern** for clean separation between UI and data layer
- **@Observable** macro for view models
- **NavigationStack** for navigation
- No cloud sync, no external dependencies beyond GRDB

---

## Why This Approach

### SwiftUI + GRDB with Repository Pattern

**Why SwiftUI:** iOS 17+ gives us `@Observable`, `NavigationStack`, and modern list APIs. Since organization/navigation is the core feature, SwiftUI's declarative approach makes the folder/tag/search views straightforward to build and maintain.

**Why GRDB over SwiftData/Core Data:** The hybrid search feature requires complex SQL queries with dynamic WHERE clauses (AND/OR/NOT across tags and folders). GRDB gives us direct SQL control while still providing Swift-friendly APIs and observation support for reactive UI updates.

**Why Repository Pattern:** With a notes app focused on organization, the query logic will be substantial. A repository layer keeps SQL isolated from views, makes the search engine testable, and allows the data layer to evolve independently of the UI.

---

## Data Model (Conceptual)

### Tables
- **notes** — id, title, body (Markdown source text), folder_id (nullable), is_pinned, created_at, modified_at, deleted_at (nullable, for trash)
- **folders** — id, name, parent_folder_id (nullable, for one level of nesting), color (nullable), created_at
- **tags** — id, name, color (nullable), created_at
- **note_tags** — note_id, tag_id (join table)
- **tag_merge_history** — id, source_tag_id, target_tag_id, merged_at, note_tag_snapshots (JSON blob of original assignments for undo)

### Key Queries
- Unsorted notes: `WHERE folder_id IS NULL AND deleted_at IS NULL`
- Pinned notes: `WHERE is_pinned = 1 AND deleted_at IS NULL`
- Folder view: `WHERE folder_id = ? AND deleted_at IS NULL ORDER BY is_pinned DESC, modified_at DESC`
- Tag view: `JOIN note_tags ... WHERE tag_id = ? AND deleted_at IS NULL ORDER BY is_pinned DESC, modified_at DESC`
- Complex search: Dynamically built WHERE clause from filter chips or parsed text query

---

## Resolved Questions

1. **Rich text storage format** → **Markdown source.** Stored as plain Markdown text, rendered on display. Formatting toolbar manipulates Markdown syntax.
2. **Search query text syntax** → **Prefix-based** (Gmail/GitHub-style). `tag:name`, `folder:name`, `AND`, `OR`, `NOT`, parentheses for grouping.
3. **Tag colors** → **Yes.** Tags have user-assignable colors for visual differentiation.
4. **Folder colors** → **Yes.** Folders also have user-assignable colors.
5. **Note preview on lists** → **Configurable.** Default: title + snippet + tag chips. Setting to toggle snippet on/off.

---

## Out of Scope (for v1)

- Cloud sync
- Sharing/collaboration
- Image or file attachments in notes
- Widgets
- Siri/Shortcuts integration
- iPad-specific layouts
- Export/import
