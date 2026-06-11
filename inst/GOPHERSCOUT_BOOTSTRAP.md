# Gopher Scout - Bootstrap Instructions

**For the AI agent helping build this project:**

This document provides the essential context and first steps for building Gopher Scout, a desktop app for browsing and managing gopheR databases.

## Quick Context

**What is Gopher Scout?**
A Tauri-based desktop application that serves as the universal interface for gopheR databases. It handles both data management (Level 2) and data exploration (Level 3) with LLM-powered natural language querying.

**The Three-Level Architecture:**
```
Level 1: gopheR (R package)
├── Database schema validation
├── Transaction safety
└── Core framework

Level 2: gopherDen (template repo)
├── Example databases
├── Helper functions
└── Domain customization

Level 3: Gopher Scout (THIS PROJECT)
├── Desktop app for browsing/editing
├── Works with ANY gopheR database
└── LLM-powered queries
```

**Full design document:** `/Users/kimbrel1/Github/gopherDen/inst/level3_roadmap.md`

## What to Build First: Phase 1 MVP

**Goal:** Basic database browser that can open a gopheR database and display its contents.

### Deliverables

1. **Open local SQLite file**
   - File picker dialog
   - Copy to Application Support for working copy
   - Validate it's a gopheR database (check for required tables)

2. **Database validation**
   - Check for required tables: `object`, `edge`, `workflow`, `result`, `people`, `object_file`
   - Verify schema compatibility
   - Display error if not valid gopheR database

3. **Basic Browse UI**
   - Tab interface (placeholder for future tabs: Browse, Add, Edit, Ask)
   - Show database metadata (path, size, object counts)
   - Display objects in a searchable/filterable table
   - Click row → show detail view

4. **Detail view for selected object**
   - Show object metadata (ID, type, subtype, label, description)
   - Show results associated with this object
   - Show edges (relationships) to/from this object

**What NOT to include in Phase 1:**
- ❌ Data editing
- ❌ LLM integration
- ❌ Remote database support
- ❌ Complex visualizations
- ❌ Provenance graphs

Just get the basic "open database → see what's inside" working.

## Technical Foundation

### Project Structure

```
gopherscout/
├── src/                    # Frontend (vanilla HTML/CSS/JS)
│   ├── index.html         # Main window
│   ├── browse.html        # Browse tab (future)
│   ├── style.css
│   └── main.js
├── src-tauri/              # Backend (Rust)
│   ├── src/
│   │   ├── main.rs        # Entry point
│   │   ├── lib.rs         # Tauri commands & setup
│   │   ├── db.rs          # Database operations
│   │   └── types.rs       # Shared types
│   ├── Cargo.toml
│   └── tauri.conf.json
└── package.json
```

### Key Dependencies

```toml
[dependencies]
tauri = { version = "2", features = [] }
tauri-plugin-dialog = "2"          # File picker
rusqlite = { version = "0.31", features = ["bundled"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"
```

### Database Location Strategy

**On "Open Database":**
1. User selects a .sqlite file via file picker
2. Copy it to `~/Library/Application Support/com.gopherscout.app/active_db.sqlite`
3. Work on the copy (safer, cleaner)
4. Original file is preserved

**Don't expose this to users** - just say "Open Database..." and handle the copy transparently.

### Core gopheR Schema (for validation)

**Required tables:**
```sql
object           -- All objects (MAGs, samples, assemblies, etc.)
├── object_id (TEXT PRIMARY KEY)
├── object_type (TEXT)
├── object_subtype (TEXT)
├── label (TEXT)
├── description (TEXT)
├── created_at (TEXT)
└── created_by (TEXT)

edge             -- Relationships between objects
├── parent_id (TEXT)
├── child_id (TEXT)
├── edge_type (TEXT)
└── workflow_id (TEXT)

result           -- Measurements/metrics (append-only)
├── result_id (INTEGER PRIMARY KEY)
├── object_id (TEXT)
├── workflow_id (TEXT)
├── key (TEXT)
└── value (TEXT)

workflow         -- Processing pipelines
├── workflow_id (TEXT PRIMARY KEY)
├── description (TEXT)
└── workflow_date (TEXT)

people           -- Contributors
├── person_id (TEXT PRIMARY KEY)
├── full_name (TEXT)
└── email (TEXT)

object_file      -- File manifest
├── object_id (TEXT)
├── file_role (TEXT)
└── file_path (TEXT)
```

Also need spec tables (but just check they exist):
- `object_type`, `object_subtype`, `edge_spec`, `key_spec`, `object_file_type_spec`

## Implementation Steps for Phase 1

### Step 1: Initialize Tauri Project

```bash
npm install -g @tauri-apps/cli
npm create tauri-app@latest
# Choose:
# - Project name: gopherscout
# - Package manager: npm
# - UI framework: vanilla (no framework)
# - Language: TypeScript (optional) or JavaScript
```

### Step 2: Setup Database Module (Rust)

Create `src-tauri/src/db.rs`:

```rust
use anyhow::Result;
use rusqlite::Connection;
use std::path::Path;

pub struct Database {
    conn: Connection,
}

impl Database {
    pub fn open(path: &Path) -> Result<Self> {
        let conn = Connection::open(path)?;
        conn.execute("PRAGMA foreign_keys = ON", [])?;
        Ok(Database { conn })
    }

    pub fn validate_gopher_schema(&self) -> Result<()> {
        // Check for required tables
        let required_tables = vec![
            "object", "edge", "result", "workflow", 
            "people", "object_file", "object_type", 
            "object_subtype", "edge_spec"
        ];
        
        for table in required_tables {
            let exists: bool = self.conn.query_row(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=?",
                [table],
                |row| Ok(row.get::<_, i32>(0)? > 0)
            )?;
            
            if !exists {
                return Err(anyhow::anyhow!(
                    "Not a valid gopheR database: missing table '{}'", 
                    table
                ));
            }
        }
        Ok(())
    }

    pub fn get_objects(&self, limit: usize, offset: usize) -> Result<Vec<Object>> {
        // Query objects table
        // Return as Vec<Object>
        todo!()
    }

    pub fn get_object_details(&self, object_id: &str) -> Result<ObjectDetails> {
        // Get object + results + edges
        todo!()
    }
}
```

### Step 3: Create Tauri Commands

Add to `src-tauri/src/lib.rs`:

```rust
#[tauri::command]
async fn open_database(path: String) -> Result<DatabaseInfo, String> {
    // 1. Copy to Application Support
    let app_data = /* get app data dir */;
    let working_copy = app_data.join("active_db.sqlite");
    std::fs::copy(&path, &working_copy)
        .map_err(|e| format!("Failed to copy database: {}", e))?;

    // 2. Open and validate
    let db = Database::open(&working_copy)
        .map_err(|e| format!("Failed to open database: {}", e))?;
    
    db.validate_gopher_schema()
        .map_err(|e| format!("Invalid database: {}", e))?;

    // 3. Return metadata
    Ok(DatabaseInfo {
        path: path.clone(),
        object_count: db.count_objects()?,
        edge_count: db.count_edges()?,
        // ... more metadata
    })
}

#[tauri::command]
async fn get_objects(limit: usize, offset: usize) -> Result<Vec<Object>, String> {
    // Return objects from current database
    todo!()
}

#[tauri::command]
async fn get_object_details(object_id: String) -> Result<ObjectDetails, String> {
    // Return full details for one object
    todo!()
}
```

### Step 4: Build Frontend

**index.html:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Gopher Scout</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div id="app">
        <div id="no-database">
            <h1>Gopher Scout</h1>
            <button id="open-db-btn">Open Database...</button>
        </div>

        <div id="database-view" style="display: none;">
            <nav>
                <span id="db-name"></span>
                <button id="close-db-btn">Close</button>
            </nav>

            <div id="content">
                <table id="objects-table">
                    <thead>
                        <tr>
                            <th>Object ID</th>
                            <th>Type</th>
                            <th>Label</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>

            <div id="detail-panel" style="display: none;">
                <!-- Object details go here -->
            </div>
        </div>
    </div>
    <script src="main.js"></script>
</body>
</html>
```

**main.js:**
```javascript
const { invoke } = window.__TAURI__.core;
const { open } = window.__TAURI__.dialog;

document.getElementById('open-db-btn').addEventListener('click', async () => {
    const selected = await open({
        multiple: false,
        filters: [{
            name: 'SQLite Database',
            extensions: ['sqlite', 'db']
        }]
    });

    if (selected) {
        try {
            const info = await invoke('open_database', { path: selected });
            showDatabase(info);
            loadObjects();
        } catch (error) {
            alert('Error opening database: ' + error);
        }
    }
});

async function loadObjects() {
    const objects = await invoke('get_objects', { limit: 100, offset: 0 });
    displayObjects(objects);
}

function displayObjects(objects) {
    const tbody = document.querySelector('#objects-table tbody');
    tbody.innerHTML = '';
    
    objects.forEach(obj => {
        const row = tbody.insertRow();
        row.innerHTML = `
            <td>${obj.object_id}</td>
            <td>${obj.object_type}</td>
            <td>${obj.label}</td>
        `;
        row.addEventListener('click', () => showObjectDetails(obj.object_id));
    });
}

async function showObjectDetails(objectId) {
    const details = await invoke('get_object_details', { objectId });
    // Display in detail panel
}
```

### Step 5: Test with Example Database

Use the gopherDen example database:
```
/Users/kimbrel1/Github/gopherDen/inst/extdata/gopherDen_db.sqlite
```

This has realistic data (12 MAGs, 6 samples, etc.) for testing.

## Success Criteria for Phase 1

You've completed Phase 1 when:

✅ App opens and shows "Open Database..." button  
✅ User can select a .sqlite file  
✅ App validates it's a gopheR database (shows error if not)  
✅ App displays list of objects in a table  
✅ User can click an object to see details  
✅ Details show: metadata, results, and edges  

## What's Next (Don't build yet)

After Phase 1 works:
- Phase 2: Add standard views (MAG browser, Sample browser, etc.)
- Phase 3: Add data entry/editing forms
- Phase 4: Add remote database support (read-only mode)
- Phase 5: Add LLM query interface

See full roadmap at: `/Users/kimbrel1/Github/gopherDen/inst/level3_roadmap.md`

## Reference Materials

**Full vision & architecture:**
- `/Users/kimbrel1/Github/gopherDen/inst/level3_roadmap.md`

**Existing Tauri app for patterns:**
- `/Users/kimbrel1/Github/labmind` (reference implementation)

**Example database for testing:**
- `/Users/kimbrel1/Github/gopherDen/inst/extdata/gopherDen_db.sqlite`

**gopheR package documentation:**
- `/Users/kimbrel1/Github/gopheR/README.md`

## Development Commands

```bash
# Install dependencies
npm install

# Run in development mode (hot reload)
npm run dev

# Build for distribution
npm run build
# Output: src-tauri/target/release/bundle/macos/Gopher Scout.app
```

## Notes for AI Assistant

- Keep it simple for Phase 1 - no fancy features yet
- Focus on getting basic database browsing working
- Don't try to implement everything from the roadmap at once
- Test frequently with the gopherDen example database
- Vanilla HTML/CSS/JS is fine - no React/Vue needed yet
- The user can always reference LabMind code if you get stuck on Tauri patterns

## Starting the Conversation

When starting work in the new repo, the user will say something like:

> "I'm building Gopher Scout, a Tauri desktop app for browsing gopheR databases. 
> Read /Users/kimbrel1/Github/gopherDen/inst/GOPHERSCOUT_BOOTSTRAP.md for 
> context and let's start with Phase 1 MVP."

You should:
1. Acknowledge you've read this bootstrap doc
2. Confirm understanding of Phase 1 goals
3. Ask if they want to start with project initialization or have already done it
4. Begin implementing Step 1

Good luck! 🚀
