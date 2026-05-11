# Quarto Reporting Structure for gopherDen

## Goals
gopherDen is a **showcase/template** demonstrating what's possible with the gopheR framework. Users will fork/copy this to create their own domain-specific implementations.

## Two Thrusts

### Thrust 1: Static HTML Reports/Dashboards
- Quarto templates (regular pages + dashboards)
- Fully static HTML (can be emailed, no server needed)
- Show database contents at-a-glance
- Non-coder friendly navigation

### Thrust 2: Interactive LLM-Powered Exploration (Future)
- Natural language querying (querychat/elmer patterns)
- "Show me all high-quality MAGs from pH > 7 sites"
- Schema-aware (knows object types, edges, result keys)
- Dynamic, requires some infrastructure

## Thrust 1 Implementation Plan

### Directory Structure
```
inst/quarto/
├── index.qmd                    # Main landing page (overview)
├── mags.qmd                     # MAG overview (summary table, quality plots)
├── mag-browser.qmd              # 🌟 Advanced: All MAGs with picker (Phase 2)
├── assemblies.qmd               # Assembly overview
├── assembly-browser.qmd         # Advanced: All assemblies with picker
├── samples.qmd                  # Sample overview
├── readsets.qmd                 # Readset overview
├── objects/                     # Example detail pages (optional Phase 1)
│   ├── mag-M001.qmd            # Example MAG detail
│   ├── mag-M002.qmd            # Second example MAG
│   ├── assembly-A001.qmd       # Example assembly detail
│   └── sample-S001.qmd         # Example sample detail
└── _quarto.yml                  # Website configuration
```

### Hierarchical Navigation
**Level 1:** Main landing (index.qmd)
- Database summary (object counts, edge counts)
- Links to object type pages

**Level 2:** Object type pages (mags.qmd, assemblies.qmd, etc.)
- Summary tables with search/filter (reactable/DT)
- Aggregate plots (quality distributions, taxonomy, maps)
- Links to example detail pages OR browser

**Level 3a:** Individual object examples (objects/mag-M001.qmd)
- 2-3 examples per object type
- Demonstrates pattern for users to generate more
- Shows provenance, metadata, results, files

**Level 3b:** Browser pages (mag-browser.qmd) - Advanced Feature
- ALL objects with multi-select picker
- Embed all data as JSON (~5-10KB per MAG = 5-10MB for 1000 MAGs)
- Client-side filtering/display
- Compare multiple objects side-by-side

## Advanced Feature: mag-browser.qmd with Picker

### Requirements
- Single static HTML file
- Contains ALL MAG data embedded
- Multi-select picker (not dropdown) to choose 1 or many MAGs
- Details panel updates based on selection
- No server needed

### Implementation Options

**Recommended: Crosstalk + reactable**
```r
library(crosstalk)
library(reactable)

# Shared data object
sd <- SharedData$new(mags_data)

# Multi-select picker
filter_select(
  id = "mag_picker", 
  label = "Select MAG(s)", 
  sharedData = sd, 
  group = ~mag_id,
  multiple = TRUE
)

# Linked table/plots update automatically
reactable(sd)
```

**Alternative: reactable with row selection**
- Click rows to select multiple MAGs
- Search/filter built in
- Extract selected rows for detail panel

**Alternative: DT with checkboxes**
- Extensions for multi-select
- Less polished than crosstalk

### Data Constraints
- ✅ Database metadata (quality, taxonomy, N50, provenance): 5-10KB per MAG
- ✅ 1,000 MAGs × 10KB = 10MB embedded JSON (browser handles fine)
- ❌ Raw sequences (FASTA/FASTQ): Too large, link to files instead

## Implementation Phases

### Phase 1: Simple Static Structure (START HERE)
1. Create main landing page (index.qmd)
2. Create object type overview pages (mags.qmd, assemblies.qmd, samples.qmd)
3. Add 2-3 example detail pages per type (objects/mag-M001.qmd)
4. Set up _quarto.yml with navigation
5. Use reactable/DT for searchable tables
6. Add summary plots (ggplot2)
7. Add maps if applicable (leaflet)

### Phase 2: Advanced Browser Feature
1. Create mag-browser.qmd with crosstalk picker
2. Query all MAG data at render time
3. Embed as JSON in HTML
4. Implement multi-select picker
5. Create reactive detail panels
6. Add comparison views for multiple selections
7. Repeat pattern for assemblies, samples if desired

## Content for Each Page Type

### Main Landing (index.qmd)
- Database summary statistics
- Object/edge counts by type
- Recent activity (optional)
- Links to object type pages
- Example queries demonstrating provenance

### Object Type Overview (mags.qmd)
- Summary table (all MAGs with key metrics)
- Quality distribution plots
- Taxonomy breakdown
- Links to example detail pages
- Link to browser (Phase 2)

### Individual Detail Page (objects/mag-M001.qmd)
- Object metadata table
- Provenance trace (binned_from assembly, binned_with readsets)
- Results (completeness, contamination, taxonomy, N50)
- Observations (observed_in which readsets/samples)
- File manifest (genome FASTA, proteins, annotations)
- Environmental context (site info, sample metadata)

### Browser Page (mag-browser.qmd) - Phase 2
- Multi-select picker for MAGs
- Selected MAG(s) detail panel
- Comparison table if multiple selected
- Filterable/searchable
- Export selected data option

## Key R Packages

### For all pages
- tidyverse (dplyr, ggplot2)
- gopheR (database access)
- knitr (tables)

### For interactive tables
- reactable (modern, fast)
- DT (DataTables wrapper)
- crosstalk (linked brushing)

### For visualizations
- ggplot2 (plots)
- leaflet (maps)
- visNetwork or igraph (network graphs)
- plotly (optional, interactive plots)

### For browser feature
- crosstalk (multi-widget linking)
- jsonlite (embed data as JSON)

## Notes
- All Quarto dashboards can mix with regular Quarto pages in same site
- Format specified in YAML frontmatter: `format: dashboard` vs default html
- Can use ObservableJS cells for client-side interactivity
- Keep example data manageable (not thousands of example objects)
- Users will customize for their domain (clinical, industrial, etc.)

## Edge Types to Showcase
With new "binned_with" edge, demonstrate:
- assembled_from: readsets → assembly
- binned_from: assembly → MAG
- binned_with: readsets → MAG (coverage for binning)
- observed_in: readsets → MAG (post-hoc detection)
- sequenced_from: sample → readset
- collected_from: site → sample

## Rendering the Site

Use the provided R functions to build the HTML site:

```r
# Load package functions during development
devtools::load_all()

# Render the Quarto site
render_site()

# Open in browser
view_site()
```

The `render_site()` function:
- Auto-detects site location (development or installed package)
- Calls `quarto render` with appropriate arguments
- Returns path to rendered output directory
- Can specify custom output directory with `output_dir` parameter

## Next Steps
1. ✅ Added "binned_with" edge to databases
2. ✅ Create basic Quarto structure (Phase 1)
3. ✅ Build main landing page
4. ✅ Build object type overview pages
5. ✅ Add example detail pages (MAG_A1_001)
6. ✅ Test rendering
7. ✅ Create render_site() helper function
8. ⏭️ Add advanced browser feature (Phase 2)
