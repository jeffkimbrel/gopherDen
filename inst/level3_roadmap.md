# Level 3 Roadmap: Tauri Desktop App for gopheR Databases

**Vision:** A single, distributable desktop application that serves as the universal interface for gopheR databases - handling both data management (Level 2) and data exploration (Level 3).

## Why This Approach?

### Problems with Previous Plans

**Static HTML Reports (Quarto):**
- ❌ Snapshot in time - stale as soon as rendered
- ❌ Need to re-render after every database update
- ❌ Can't edit data
- ❌ One report per database state

**Excel Bundles for Data Entry:**
- ❌ No pre-population when adding edges to existing objects
- ❌ Validation only happens on submit (delayed feedback)
- ❌ Can't edit existing entries (insert-only workflow)
- ❌ No real-time autocomplete or type-ahead
- ❌ Clunky for small edits ("just fix this one taxonomy value")

**Multiple Level 3 Tools (HTML + Shiny + other):**
- ❌ Maintenance burden across multiple codebases
- ❌ Different interfaces for same data
- ❌ Duplication of effort

### The Tauri Solution

✅ **One application** for all gopheR database interactions  
✅ **Cross-platform** (Mac, Windows, Linux)  
✅ **Distributable** to non-coding colleagues  
✅ **Live data** - always current, no re-rendering  
✅ **Read-write** for local databases, **read-only** for remote  
✅ **LLM-powered** custom queries without maintaining project-specific code  
✅ **Familiar web tech** for UI (can reuse Quarto page designs)  
✅ **Fast Rust backend** for SQLite operations  

## Architecture Overview

### The Three Gopher Levels

```
Level 1: gopheR (R Package)
├── Schema validation
├── Transaction safety
├── Excel template generation
└── Shared across all projects

Level 2: gopherDen (Template Repo)
├── Example database structure
├── Helper functions (make_new_db)
├── Data generation examples
└── Domain customization patterns

Level 3: Tauri App (THIS ROADMAP)
├── Universal database browser
├── Data entry & editing interface
├── LLM-powered custom queries
└── Works with ANY gopheR database
```

### App Replaces

- ✅ Static HTML reports → Live browsing
- ✅ Excel-only data entry → App-based forms with validation
- ✅ Custom project views → LLM natural language queries

### App Complements

- ✅ Excel bundles still useful for bulk imports
- ✅ R scripts still used for complex statistical analyses
- ✅ gopheR validation still enforces schema

## App Structure

### Database Modes

The app operates in two distinct modes based on database location:

#### 1. Local Mode (Read-Write)
```
User Action: File → Open Local Database
Location: /Users/scientist/my_project/data.sqlite

UI State:
- [Edit] [Add] [Delete] buttons ENABLED
- ⚠️ Warning banner: "Editing local database"
- Auto-backup before each write operation
- Transaction safety with rollback
- "Undo last change" available

Use Cases:
- Lab managers curating data
- Scientists adding new samples/MAGs
- Data quality fixes and updates
```

#### 2. Remote Mode (Read-Only)
```
User Action: File → Open from URL
Location: https://github.com/mylab/project/raw/main/gopheR_db.sqlite

UI State:
- [Edit] [Add] [Delete] buttons DISABLED/HIDDEN
- ℹ️ Info banner: "Viewing read-only database from GitHub"
- [Refresh] button to get latest version
- Can still use LLM queries and browse

Use Cases:
- Students browsing lab data
- Collaborators exploring without edit risk
- External reviewers
- Anyone who needs current data without database management
```

### Navigation Structure

```
┌─────────────────────────────────────────────────┐
│  gopheR Database Manager                        │
│  Database: my_mags.sqlite (Local - Read-Write) │
├─────────────────────────────────────────────────┤
│                                                 │
│  📂 Database    Database selection & info       │
│  ➕ Add Data    Data entry forms (Level 2)      │
│  ✏️  Edit Data   Browse & modify (Level 2)      │
│  👀 Browse      Standard views (Level 3a)       │
│  💬 Ask         LLM queries (Level 3b)          │
│  ⚙️  Settings    API keys, preferences          │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Feature Details

### 📂 Database Tab

**Responsibilities:**
- Open local .sqlite file
- Open from URL (GitHub raw, shared drive, etc.)
- Create new database (uses gopheR starter schema)
- Display database metadata
- Connection status

**UI Elements:**
```
Database Information:
├── Path: /Users/scientist/mags.sqlite
├── Mode: Local (Read-Write) or Remote (Read-Only)
├── Size: 45.2 MB
├── Objects: 1,247
├── Edges: 3,891
├── Last Modified: 2026-06-10 14:32
└── Schema Version: gopheR 0.5.0

[Open Local...] [Open from URL...] [Create New...]
[Close Database]
```

**Validation on Open:**
- Check for required tables (object, edge, workflow, result, etc.)
- Verify gopheR schema compatibility
- Display warning if schema version mismatch
- Inspect available object types, edge types, result keys

### ➕ Add Data Tab (Level 2)

**Only visible in Local Mode (read-write)**

Replaces Excel bundle workflow with validated forms:

#### Add Object
```
Form with real-time validation:
├── Object Type: [Dropdown: genome, sample, readset...] ✓
├── Object Subtype: [Dropdown: MAG, isolate...] ✓
│   (filtered based on object_type from object_subtype table)
├── Object ID: [Text input with validation] 
│   Shows red if ID already exists
│   Shows green if valid and unique
├── Label: [Text input]
├── Description: [Text area]
├── Created By: [Dropdown from people table or add new]
└── [Add Object] [Cancel]

Real-time feedback:
- "genome:MAG already has 12 entries in database"
- "Object ID 'MAG_001' already exists"
- "✓ Ready to add"
```

#### Add Edge
```
Form with autocomplete:
├── Parent Object: [Autocomplete existing object_ids]
│   Type to search: "assembly_A1" → shows matches
├── Child Object: [Autocomplete existing object_ids]
├── Edge Type: [Dropdown filtered by valid parent→child types]
│   Only shows edge types valid for selected object types
│   Example: If parent=assembly, child=genome, shows "binned_from"
├── Created By: [Dropdown]
├── Workflow: [Optional - dropdown from workflows]
└── [Add Edge] [Cancel]

Smart validation:
- "✓ binned_from is valid for assembly → genome"
- "✗ assembled_from cannot connect genome → assembly"
- Preview: Shows how this fits in provenance graph
```

#### Add Result
```
Form driven by key_spec:
├── Object: [Autocomplete object_ids]
├── Key: [Dropdown from key_spec for this object type]
│   Only shows keys valid for selected object's type
├── Value: [Text input with type validation]
│   If key_spec says "integer", validates numeric
├── Workflow: [Dropdown from workflows]
└── [Add Result] [Cancel]

Examples:
- Object: MAG_A1_001 (genome:MAG)
- Key: [completeness, contamination, taxonomy, size_bp, gc_content...]
- Value: 95.2
```

#### Add File
```
Form for file manifest:
├── Object: [Autocomplete object_ids]
├── File Role: [Dropdown from object_file_type_spec]
│   Only shows roles valid for object's type
│   genome → [genome_fasta, protein_fasta, annotation_gff]
├── File Path: [File picker or text input]
├── File Format: [Text input, e.g., "FASTA", "FASTQ"]
├── Checksum: [Auto-calculate] or [Manual entry]
├── Workflow: [Dropdown]
└── [Add File] [Cancel]
```

**Benefits over Excel:**
- ✅ Real-time validation (red/green feedback)
- ✅ Autocomplete for existing IDs
- ✅ Only shows valid options (dropdowns filtered by specs)
- ✅ Immediate feedback on conflicts
- ✅ Can add one thing at a time (not bulk-only)
- ✅ Safer for non-coders

**Excel bundles still useful for:**
- Bulk imports (100 samples at once)
- Offline data preparation
- People who prefer spreadsheets

### ✏️ Edit Data Tab (Level 2)

**Only visible in Local Mode**

Browse and modify existing database entries:

```
Searchable table with filters:
├── Table selector: [Objects | Edges | Results | Workflows | People | Files]
├── Search: [Full-text search across all fields]
├── Filters: [By type, by date, by person, etc.]
└── Results table (sortable, paginated)
    └── Click row → Edit form (same validation as Add)

Edit Object Example:
┌────────────────────────────────────┐
│ Edit Object: MAG_A1_001            │
├────────────────────────────────────┤
│ Object Type: genome:MAG            │
│ Label: [Site A Sample 1 MAG 1]    │
│ Description: [High-quality Acido...│
│ Created: 2026-04-22 by jkimbrel   │
│                                    │
│ [Save Changes] [Delete] [Cancel]  │
└────────────────────────────────────┘

Safety features:
- Confirmation dialog before delete
- Shows dependent objects ("This object has 5 edges, delete anyway?")
- Auto-backup before destructive operations
- Transaction rollback on error
```

**Key Features:**
- ✅ Edit any field (except primary keys)
- ✅ Delete entries (with cascade warning)
- ✅ View history (if we add versioning)
- ✅ Bulk operations (select multiple, delete/edit)
- ✅ Undo last change

### 👀 Browse Tab (Level 3a - Standard Views)

**Available in both modes (read-only and read-write)**

Pre-built views for common data browsing tasks. These are **inspired by the Quarto pages we designed** but rendered dynamically:

#### Landing Page
```
Database Overview:
├── Summary Statistics
│   ├── Total Objects: 1,247
│   ├── Total Edges: 3,891
│   ├── Total Results: 8,543
│   └── Total Workflows: 42
├── Object Counts by Type
│   └── Bar chart or table
├── Edge Counts by Type
│   └── Relationship summary
└── Site Map (if geographic data available)
    └── Interactive Leaflet-style map
```

#### MAG Browser
```
Interactive table with:
├── All MAG objects
├── Most recent result values (completeness, contamination, taxonomy)
├── Searchable & filterable
├── Sort by any column
├── Color-coded quality (green: >90% complete, yellow: 50-90%, etc.)
├── Click row → Detail view

Detail View for Selected MAG:
├── Metadata (ID, label, description)
├── Quality Metrics - Historical
│   └── Table grouped by metric showing all assessments over time
├── Taxonomy - Historical
│   └── All taxonomic classifications with workflow dates
│   └── "GTDB r214 (2025), GTDB r207 (2023)"
├── Current Best Values
│   └── Most recent value for each metric
├── Provenance
│   ├── Binned from: assembly_A1
│   ├── Assembly built from: readset_A1, readset_A2, readset_A3
│   ├── Binned using coverage: readset_A1, readset_A2, readset_A3
│   └── Interactive graph visualization
├── Observations
│   └── Where this MAG was found (observed_in edges)
└── Files
    └── Manifest of associated files
```

#### Sample Browser
```
Similar to MAG browser:
├── All samples with metadata
├── Site information (via edges)
├── Provenance (which readsets, which MAGs observed)
├── Result data (pH, moisture, etc.)
├── Geographic visualization if coordinates available
```

#### Assembly Browser
```
├── Assembly statistics
├── Provenance (which readsets used)
├── Downstream products (which MAGs binned)
├── Quality metrics
```

#### Provenance Graph Viewer
```
Interactive network visualization:
├── Select a starting object
├── Show all connected objects (upstream & downstream)
├── Edge types labeled
├── Click nodes to see details
├── Zoom, pan, filter by edge type
├── Export as image

Example:
    Site_A
      ↓ collected_from
    Sample_A1
      ↓ sequenced_from
    Readset_A1
      ↓ assembled_from
    Assembly_A1
      ↓ binned_from
    MAG_A1_001
```

**Key Features:**
- ✅ Works exactly the same in read-only and read-write modes
- ✅ Dynamic - always shows current database state
- ✅ Fast - Rust backend for queries
- ✅ Interactive - click to drill down
- ✅ Export - tables to CSV, graphs to PNG

### 💬 Ask Tab (Level 3b - LLM Queries)

**Available in both modes** (only reads, doesn't modify)

**THE KILLER FEATURE** - eliminates need for project-specific customization

#### How It Works

**1. On Database Load:**
```rust
// App inspects database schema
let object_types = query("SELECT * FROM object_type");
let edge_types = query("SELECT * FROM edge_spec");
let result_keys = query("SELECT * FROM key_spec");
let file_roles = query("SELECT * FROM object_file_type_spec");

// Builds schema context for LLM
let schema_context = format!(
  "This gopheR database contains:
   Object types: {}
   Edge types: {}
   Result keys: {}
   File roles: {}", 
  object_types, edge_types, result_keys, file_roles
);
```

**2. User Asks Question:**
```
User: "Show me all high-quality MAGs from samples with moisture > 60%"
```

**3. LLM Prompt:**
```
You are a SQL query generator for gopheR databases.

Schema Context:
- Tables: object, edge, result, workflow, people, object_file
- Object types in this DB: genome (subtypes: MAG, isolate), sample (soil), 
  readset (paired_end), assembly (metagenome)
- Edge types: binned_from (assembly→genome), binned_with (readset→genome),
  assembled_from (readset→assembly), sequenced_from (sample→readset),
  observed_in (readset→genome), collected_from (site→sample)
- Result keys for genome: completeness, contamination, taxonomy, size_bp, gc_content
- Result keys for sample: moisture, pH, temperature

User Question: "Show me all high-quality MAGs from samples with moisture > 60%"

Generate a valid SQLite query. High-quality MAGs have completeness > 90% and 
contamination < 5%. You'll need to join through the graph:
genome ← binned_from ← assembly ← assembled_from ← readset ← sequenced_from ← sample

Return ONLY the SQL query, no explanation.
```

**4. LLM Returns SQL:**
```sql
SELECT 
  m.object_id as mag_id,
  m.label,
  r_comp.value as completeness,
  r_cont.value as contamination,
  r_moist.value as moisture,
  s.object_id as sample_id
FROM object m
JOIN result r_comp ON r_comp.object_id = m.object_id AND r_comp.key = 'completeness'
JOIN result r_cont ON r_cont.object_id = m.object_id AND r_cont.key = 'contamination'
JOIN edge e_binned ON e_binned.child_id = m.object_id AND e_binned.edge_type = 'binned_from'
JOIN edge e_assembled ON e_assembled.child_id = e_binned.parent_id AND e_assembled.edge_type = 'assembled_from'
JOIN edge e_seq ON e_seq.child_id = e_assembled.parent_id AND e_seq.edge_type = 'sequenced_from'
JOIN object s ON s.object_id = e_seq.parent_id
JOIN result r_moist ON r_moist.object_id = s.object_id AND r_moist.key = 'moisture'
WHERE m.object_type = 'genome'
  AND CAST(r_comp.value AS REAL) > 90
  AND CAST(r_cont.value AS REAL) < 5
  AND CAST(r_moist.value AS REAL) > 60
```

**5. App Executes & Displays:**
```
Results (8 MAGs found):
┌──────────────┬────────────────────┬──────────────┬──────────────┬──────────┐
│ MAG ID       │ Label              │ Completeness │ Contamination│ Moisture │
├──────────────┼────────────────────┼──────────────┼──────────────┼──────────┤
│ MAG_A1_001   │ Site A Sample 1... │ 95.2         │ 2.1          │ 65.3     │
│ MAG_A2_001   │ Site A Sample 2... │ 97.8         │ 1.5          │ 68.1     │
│ ...          │                    │              │              │          │
└──────────────┴────────────────────┴──────────────┴──────────────┴──────────┘

[Export CSV] [Visualize] [Save Query]
```

**6. Optional: Visualization Request:**
```
User: "Now plot completeness vs moisture colored by phylum"

LLM: Generates SQL to also get taxonomy, app renders scatter plot
```

#### UI Design

```
┌─────────────────────────────────────────────────────────────┐
│ Ask Your Database                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Question: [                                             ] ? │
│                                                             │
│ Examples:                                                   │
│  • Show me all high-quality MAGs                            │
│  • Which samples have the most MAGs?                        │
│  • Plot MAG completeness vs contamination by phylum         │
│  • What sites have Acidobacteria?                           │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ SQL Query (generated):                                      │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ SELECT m.object_id, r_comp.value as completeness...    │ │
│ │ FROM object m                                           │ │
│ │ JOIN result r_comp ON...                                │ │
│ └─────────────────────────────────────────────────────────┘ │
│ [Edit SQL] [Execute]                                        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Results:                                                    │
│ [Table View] [Chart View] [Export]                          │
│                                                             │
│ (Results display here)                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Advanced Features

**Query History:**
```
Recent Queries:
├── "High-quality MAGs from wet soils" (2 mins ago)
├── "Proteobacteria by site" (1 hour ago)
└── "MAG quality distribution" (yesterday)
    └── Click to re-run
```

**Saved Queries:**
```
Favorite Queries:
├── "Weekly MAG summary"
├── "Sample quality check"
└── "Taxonomy breakdown"
    └── Pin frequently used queries
```

**Query Templates:**
```
Moisture Lab Config:
├── Default filters: moisture > X
├── Suggested questions focusing on moisture gradients
└── Custom context in LLM prompt
```

**Visualization Options:**
- Table (default)
- Bar chart
- Scatter plot
- Histogram
- Heatmap
- Network graph

**LLM could even generate HTML:**
```
User: "Create a dashboard showing MAG quality metrics"

LLM: Generates HTML with embedded charts
App: Renders in webview
```

### ⚙️ Settings Tab

**Configuration & Preferences:**

```
API Keys:
├── OpenAI API Key: [••••••••••••••••] [Test Connection]
├── Anthropic API Key: [••••••••••••••] [Test Connection]
└── Model Selection: [gpt-4, claude-sonnet-4, etc.]

Database Preferences:
├── Auto-backup on write: [✓]
├── Backup location: [~/gopheR_backups/]
├── Transaction timeout: [30 seconds]
└── Schema validation on open: [✓]

UI Preferences:
├── Theme: [Light | Dark | System]
├── Default view: [Browse | Ask]
├── Show SQL in Ask tab: [✓]
└── Table page size: [50 rows]

LLM Settings:
├── Context verbosity: [Minimal | Standard | Detailed]
├── Query explanation: [✓] Show how LLM interpreted question
├── Safety mode: [✓] Require confirmation for DELETE/UPDATE
└── Custom system prompt: [Text area for domain-specific context]
```

## Technical Architecture

### Stack

**Frontend:**
- Tauri (Rust + Web)
- React/Vue/Svelte for UI
- D3.js or similar for network graphs
- Plotly/Chart.js for visualizations
- Leaflet for maps

**Backend (Rust):**
- rusqlite for SQLite operations
- serde for JSON serialization
- tokio for async operations
- HTTP client for remote database fetching
- LLM API client (OpenAI/Anthropic)

**Database:**
- SQLite (same as gopheR)
- No server needed
- Transaction safety built-in

### Key Technical Challenges

**1. Schema Introspection**
```rust
// Need to build comprehensive schema context for LLM
fn build_schema_context(conn: &Connection) -> SchemaContext {
    let object_types = query_object_types(conn);
    let edge_spec = query_edge_spec(conn);
    let key_spec = query_key_spec(conn);
    // ... build detailed schema description
}
```

**2. LLM SQL Generation**
- Need robust prompting to get valid SQL
- Handle errors gracefully ("I couldn't generate that query, please rephrase")
- Validate generated SQL before execution
- Prevent injection attacks

**3. Remote Database Handling**
```rust
// Download remote DB to temp location
// Cache for session
// Refresh on demand
async fn open_remote_database(url: &str) -> Result<Connection> {
    let data = fetch_url(url).await?;
    let temp_path = write_to_temp(data)?;
    open_connection(&temp_path, ReadOnly)
}
```

**4. Read-Only Enforcement**
```rust
// Open connection in read-only mode for remote DBs
Connection::open_with_flags(
    path,
    OpenFlags::SQLITE_OPEN_READ_ONLY
)?;
```

**5. Real-time Validation**
- As user types in forms, validate against database
- Debounce to avoid excessive queries
- Show green/red indicators

**6. Transaction Safety**
```rust
// All writes wrapped in transactions
conn.execute("BEGIN TRANSACTION")?;
// ... perform writes
if error {
    conn.execute("ROLLBACK")?;
    restore_backup()?;
} else {
    conn.execute("COMMIT")?;
}
```

## Implementation Phases

### Phase 1: MVP (Core Functionality)
**Goal:** Basic database browser

- ✅ Open local SQLite database
- ✅ Validate gopheR schema
- ✅ Browse tab: Display objects in tables
- ✅ Basic search & filter
- ✅ Detail view for selected object
- ⏭️ No editing, no LLM, no remote

**Deliverable:** Can open and explore a gopheR database

### Phase 2: Standard Views
**Goal:** Replicate Quarto page functionality

- ✅ Landing page with statistics
- ✅ MAG browser with quality metrics
- ✅ Sample browser
- ✅ Assembly browser
- ✅ Provenance graph visualization
- ✅ Historical data views (all result values over time)

**Deliverable:** Feature parity with planned Quarto reports but dynamic

### Phase 3: Data Entry & Editing (Level 2)
**Goal:** Replace Excel workflow for small edits

- ✅ Add Data tab with validated forms
- ✅ Real-time validation & autocomplete
- ✅ Edit existing entries
- ✅ Delete with safety checks
- ✅ Auto-backup before writes
- ✅ Transaction rollback on errors

**Deliverable:** Can manage database without Excel

### Phase 4: Remote Database Support
**Goal:** Read-only mode for shared databases

- ✅ Open from URL
- ✅ Download & cache remote DB
- ✅ Enforce read-only mode
- ✅ Refresh button to get latest
- ✅ UI indicates local vs remote

**Deliverable:** Can share databases via GitHub

### Phase 5: LLM Query Interface (Level 3b)
**Goal:** Natural language queries

- ✅ Schema introspection on DB load
- ✅ Ask tab UI
- ✅ LLM integration (OpenAI/Anthropic)
- ✅ SQL generation from natural language
- ✅ Execute & display results
- ✅ Handle errors gracefully

**Deliverable:** Can ask questions in plain English

### Phase 6: Advanced LLM Features
**Goal:** Make LLM interface production-ready

- ✅ Visualization generation
- ✅ Query history & favorites
- ✅ Custom prompts for domain specificity
- ✅ Export results
- ✅ SQL editing before execution
- ✅ Query templates

**Deliverable:** LLM interface replaces need for custom reports

### Phase 7: Polish & Distribution
**Goal:** Production-ready app

- ✅ Settings & preferences
- ✅ Error handling & user feedback
- ✅ Performance optimization
- ✅ Documentation & help system
- ✅ Installers for Mac/Windows/Linux
- ✅ Auto-update mechanism
- ✅ Telemetry (optional, privacy-respecting)

**Deliverable:** Distributable to non-technical users

## Relationship to gopherDen

### What gopherDen Becomes

**gopherDen is still valuable as Level 2 infrastructure:**

1. **Example Database Structure**
   - Shows how to set up object types, edges, result keys for MAG research
   - Users fork and customize for their domain

2. **Helper Functions**
   - `make_new_db()` - Create blank gopheR database
   - `render_site()` - DEPRECATED (replaced by Tauri app)

3. **Data Generation Examples**
   - `data-raw/` scripts showing how to populate databases
   - Example bundles for learning

4. **Documentation**
   - How to customize gopheR for your domain
   - Patterns for defining object types, edges, keys

5. **R-based Custom Analyses** (NOT in app)
   - Complex statistical analyses
   - Publication-quality figures
   - Domain-specific calculations
   - These stay as R scripts for scientists who code

**What gets removed/deprecated:**
- ❌ `inst/quarto/` templates (app replaces HTML reports)
- ❌ `render_site()` function (no longer needed)
- ❌ Quarto dependencies

**What stays/grows:**
- ✅ Example database (users learn from it)
- ✅ Helper functions for database setup
- ✅ Documentation & patterns
- ✅ Template structure for forking

### Workflow with App

**Scientist's Workflow:**

1. **Fork gopherDen template**
   - Customize object types, edges, keys for their domain
   - Example: Change from MAGs to clinical samples

2. **Create project database**
   ```r
   devtools::load_all()
   make_new_db("my_project.sqlite")
   # Customize spec tables...
   ```

3. **Open in Tauri app**
   - File → Open Local Database
   - Add data using forms (small additions)
   - OR bulk import via Excel bundles

4. **Share with team**
   - Push database to GitHub
   - Team opens: File → Open from URL
   - Everyone sees latest data (read-only)

5. **Custom analyses in R** (when needed)
   ```r
   # Complex stats not in app
   library(gopheR)
   con <- gopher_con()
   # Custom analysis code...
   ```

6. **Browse/query in app daily**
   - Use Ask tab for ad-hoc questions
   - Use Browse tab for standard views
   - No need to write R code for exploration

## Success Metrics

**App is successful if:**

✅ Non-coding lab members can browse data independently  
✅ 90% of data exploration happens in app (not R)  
✅ Excel bundles used <10% of the time (bulk only)  
✅ LLM can answer 80%+ of questions correctly  
✅ Multiple labs adopt across different domains  
✅ Maintenance burden < static HTML + Shiny combined  

## Security Considerations

### Overview

The app handles local SQLite databases with scientific data - security risks are **low to moderate** for typical academic use cases.

### Key Security Measures

#### 1. SQL Injection Protection

**Risk:** LLM could generate malicious SQL that corrupts database

**Mitigation:**
```rust
// Open LLM query connections as read-only
let conn = Connection::open_with_flags(
    db_path,
    OpenFlags::SQLITE_OPEN_READ_ONLY
)?;
```

**Note:** SQLite cannot execute system commands or compromise the machine - worst case is corrupted database data (user can restore from backup).

#### 2. API Key Storage

**Current approach (acceptable):**
- Store in Application Support folder
- User-only file permissions (macOS: 0600)
- Plaintext is fine for local desktop app

**Future enhancement (optional):**
- Encrypt with device-specific key
- OS Keychain integration (if implementable)

```rust
// Set user-only permissions
#[cfg(unix)]
std::fs::set_permissions(&api_key_path, 
    std::fs::Permissions::from_mode(0o600))?;
```

#### 3. Remote Database Access

**Security measures:**
```rust
// Only allow HTTPS URLs
if !url.starts_with("https://") {
    return Err("Only HTTPS URLs allowed");
}

// Validate SQLite file header
fn is_valid_sqlite(data: &[u8]) -> bool {
    data.starts_with(b"SQLite format 3\0")
}

// Warn about untrusted sources
if !is_known_host(url) {
    show_warning("Opening from unknown source");
}
```

#### 4. Code Signing (Optional)

**For internal lab distribution:** Not critical
- Users can right-click → "Open" to bypass warnings
- Works fine for colleagues/collaborators

**For wider distribution:** Recommended
- macOS: Apple Developer cert + notarization ($99/year)
- Windows: Code signing cert ($200-400/year)
- Prevents "untrusted developer" warnings

#### 5. Data Privacy

**PII in databases:**
- Researcher names and institutional emails (for attribution)
- Not sensitive - same info on publications
- Work emails expected to be semi-public

**Not suitable for:**
- Patient/participant data
- Private personal information
- Sensitive research subjects
- Clinical trial data

**Simple disclaimer sufficient:**
```
This database tracks scientific provenance using researcher 
names and work emails. Do not store sensitive personal 
information or private research subject data.
```

### File System Access

**Tauri security model:**
- ✅ User explicitly selects files via file picker
- ✅ App only accesses chosen databases
- ❌ Cannot scan arbitrary directories
- ❌ Cannot access system files without permission

### Network Security

**LLM API calls:**
```rust
let client = Client::builder()
    .timeout(Duration::from_secs(30))
    .https_only(true)
    .build()?;
```

**Rate limiting:**
```rust
// Prevent rapid-fire expensive API calls
struct RateLimiter {
    last_request: Instant,
    min_interval: Duration::from_secs(1),
}
```

### Security Checklist

**Critical (must have):**
- ☐ Read-only connections for LLM queries
- ☐ HTTPS-only for remote databases
- ☐ File picker (no arbitrary path access)
- ☐ Input validation on forms

**Important (should have):**
- ☐ User-only permissions on API key file
- ☐ Timeout on long-running queries
- ☐ User confirmation for destructive operations
- ☐ Clear error messages (no sensitive data leaked)

**Optional (nice to have):**
- ☐ Code signing for public distribution
- ☐ Encrypted API key storage
- ☐ Audit logging
- ☐ Network activity transparency

### User Concerns & Responses

**"I don't install apps"**
- For lab use: Right-click → Open works fine
- For public: Code signing eliminates warnings
- Alternative: Offer web version

**"What permissions does this need?"**
```
Required:
✅ Read/write local files (your databases)
✅ Internet access (LLM API, remote databases)
✅ Local storage (API keys, preferences)

Does NOT access:
❌ Your contacts, photos, or other files
❌ Run in background when closed
❌ Send data except to chosen LLM provider
```

**"Is my data secure?"**
```
✅ Databases stay on your computer
✅ No cloud storage or tracking
✅ LLM sees only results you send
⚠️  API keys stored locally (user-only permissions)
⚠️  LLM queries go to OpenAI/Anthropic (their privacy)
```

### Bottom Line

For academic lab use with scientific data:
- Security risks are **low**
- Standard precautions are **sufficient**
- Focus on **data integrity** over system security
- **Code signing optional** for internal distribution

## Implementation References

### LabMind (Existing Tauri App)

There is an existing Tauri app at `/Users/kimbrel1/Github/labmind` that provides useful patterns for this project. LabMind is a demo/prototype; the gopheR app will be the production implementation.

#### Useful Patterns to Adopt

**1. Database Location Strategy**

LabMind stores its database in Application Support:
```rust
let data_dir = app.handle()
    .path()
    .app_data_dir()  // ~/Library/Application Support/com.app-name.app/
    .expect("failed to resolve app data directory");

std::fs::create_dir_all(&data_dir)?;
let db_path = data_dir.join("database.sqlite");
```

**For gopheR app:**
- When user opens a database, copy it to Application Support
- Work on the copy (safer, cleaner)
- Sync back to original location on close/save
- Don't expose this detail to users - just say "Import from..." or "Open..."
- Users naturally assume they're working with a managed copy

**Benefits:**
- ✅ Original file preserved (automatic backup)
- ✅ No file permission issues
- ✅ Clean transaction isolation
- ✅ App controls the working environment

**2. API Key Storage**

LabMind uses Application Support folder with user-only permissions:
```rust
fn config_file_path() -> Option<std::path::PathBuf> {
    let home = std::env::var("HOME").ok()?;
    Some(std::path::PathBuf::from(home)
        .join("Library/Application Support/com.app-name.app/config.json"))
}

fn write_key_to_file(key: &str) -> Result<(), String> {
    let path = config_file_path()?;
    std::fs::create_dir_all(path.parent().unwrap())?;
    let json = serde_json::json!({ "openai_api_key": key });
    std::fs::write(&path, serde_json::to_string(&json).unwrap())?;
    
    // User-only permissions (0600)
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(&path, 
            std::fs::Permissions::from_mode(0o600));
    }
    Ok(())
}
```

**Note:** LabMind includes `keyring` crate but it's not successfully using macOS Keychain - falls back to file storage. File approach works fine for our use case.

**3. Project Structure**

Simple and clean - no frontend framework needed:
```
app/
├── src/                    # Frontend (vanilla HTML/CSS/JS)
│   ├── index.html
│   ├── browse.html
│   ├── query.html
│   └── main.js            # Tauri invoke calls
├── src-tauri/              # Backend (Rust)
│   ├── src/
│   │   ├── main.rs        # Entry point
│   │   ├── lib.rs         # Tauri commands & setup
│   │   ├── store.rs       # Database operations
│   │   └── types.rs       # Shared types
│   ├── Cargo.toml
│   └── tauri.conf.json
└── package.json           # Just @tauri-apps/cli
```

**4. SQLite Pattern**

Trait-based abstraction (good for testing, swapping implementations):
```rust
pub struct SqliteStore {
    conn: Mutex<Connection>,
}

impl SqliteStore {
    pub fn new(db_path: &std::path::Path) -> Result<Self> {
        let conn = Connection::open(db_path)?;
        conn.execute_batch("PRAGMA foreign_keys = ON;")?;
        let store = SqliteStore {
            conn: Mutex::new(conn),
        };
        store.init_schema()?;
        Ok(store)
    }

    fn init_schema(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute_batch("CREATE TABLE IF NOT EXISTS ...")?;
        Ok(())
    }
}
```

**5. Native macOS Menu**

```rust
let file_menu = Submenu::with_items(app, "File", true, &[
    &MenuItem::with_id(app, "settings",   "Settings…", true, None)?,
    &MenuItem::with_id(app, "export",     "Export Data…", true, None)?,
    &MenuItem::with_id(app, "import",     "Import Data…", true, None)?,
    &MenuItem::with_id(app, "reset",      "Reset All Data…", true, None)?,
])?;
```

**6. Simple Frontend (No Build Complexity)**

```javascript
// Vanilla JS calling Rust
const { invoke } = window.__TAURI__.core;

async function queryDatabase() {
    try {
        const result = await invoke('execute_query', {
            sql: document.getElementById('query').value
        });
        displayResults(result);
    } catch (error) {
        showError(error);
    }
}
```

**7. Key Dependencies**

```toml
[dependencies]
tauri = { version = "2", features = [] }
tauri-plugin-dialog = "2"          # File picker, dialogs
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.12", features = ["json"] }  # LLM API calls
rusqlite = { version = "0.31", features = ["bundled"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
uuid = { version = "1", features = ["v4"] }
anyhow = "1"                        # Error handling
```

#### What NOT to Copy

- ❌ Domain-specific logic (atom extraction, novelty checking, etc.)
- ❌ Keyring/Keychain code (didn't work anyway)
- ❌ Embedding/vector storage (not needed for gopheR)
- ❌ LabMind's specific database schema

#### Development Approach

LabMind is a reference/prototype. The gopheR app will:
- Start with LabMind's architectural patterns
- Evolve into the production tool
- Eventually be more robust than LabMind
- Be actively maintained (LabMind is demo-only)

Full LabMind source available at `/Users/kimbrel1/Github/labmind` if needed during development.

## Open Questions

1. **Offline LLM support?**
   - Could we embed a small model for offline use?
   - Or require internet + API key?

2. **Multi-user editing?**
   - For now: one user at a time (SQLite limitation)
   - Future: Sync via git, conflict resolution?

3. **Database versioning?**
   - Track history of changes?
   - Git-style diffs for database?

4. **LLM prompt engineering:**
   - How much schema context to include?
   - Domain-specific prompt customization?
   - Few-shot examples for better SQL generation?

5. **Mobile version?**
   - Tauri supports mobile
   - Read-only mobile app for field work?

6. **Plugin system?**
   - Allow users to add custom views?
   - Extend via JavaScript/TypeScript?

## Conclusion

This Tauri app represents a **fundamental shift** in how users interact with gopheR databases:

**Before:** Static snapshots, Excel-only editing, multiple tools  
**After:** One app, live data, LLM-powered exploration  

The app becomes the **universal Level 3 interface** while gopherDen remains the **Level 2 template** for domain customization.

This architecture is:
- ✅ Simpler to maintain (one codebase vs many)
- ✅ More powerful (LLM eliminates need for custom views)
- ✅ More accessible (distribute to non-coders)
- ✅ More current (always shows latest data)
- ✅ More flexible (works with any gopheR database)

**Next Steps:**
1. Create new repo: `gopheR-app` or `gopheR-desktop`
2. Start with Phase 1 MVP (basic browser)
3. Iterate based on user feedback
4. Deprecate Quarto work in gopherDen once app is functional
