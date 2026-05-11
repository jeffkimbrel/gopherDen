# gopherDen Quarto Site

This directory contains Quarto templates for generating static HTML reports from your gopheR database.

## Rendering the Site

### From R

```r
# Load gopherDen functions
devtools::load_all()

# Render the site
render_site()

# Open in browser
view_site()
```

### From Command Line

```bash
cd inst/quarto
quarto render
open _site/index.html
```

## Site Structure

```
inst/quarto/
├── index.qmd                    # Main landing page
├── mags.qmd                     # MAG overview (most recent data)
├── samples.qmd                  # Sample overview
├── assemblies.qmd               # Assembly overview
├── objects/                     # Detail pages
│   └── mag-MAG_A1_001.qmd      # Example MAG detail (all historical data)
├── _quarto.yml                  # Site configuration
└── _site/                       # Rendered HTML (generated)
```

## Key Features

### Landing Pages
- Show **most recent** result data (latest workflow_date)
- Interactive searchable tables (reactable)
- Summary plots and statistics
- Object/edge relationship counts

### Detail Pages
- Show **all historical** result data (append-only)
- Quality metrics over time
- Taxonomy updates (e.g., different GTDB versions)
- Full provenance (binned_from, assembled_from, binned_with, observed_in)
- File manifest

## Customization

### Adding New Pages

Create a new `.qmd` file and add it to `_quarto.yml`:

```yaml
website:
  navbar:
    left:
      - text: "Your Page"
        href: your-page.html
```

### Database Connection

All pages use this pattern to connect to the database:

```r
# Set database path
db_path <- normalizePath(file.path("..", "extdata"))
options(gopheR.db_path = db_path)
options(gopheR.db_file = "gopherDen_db.sqlite")

# Query database
gopheR::with_gopher_con(function(con) {
  DBI::dbGetQuery(con, "SELECT * FROM object")
})
```

### Handling Historical Data

**For landing pages** (most recent values only):

```r
results <- gopheR::with_gopher_con(function(con) {
  DBI::dbGetQuery(con, "
    SELECT r.object_id, r.key, r.value, w.workflow_date
    FROM result r
    JOIN workflow w ON w.workflow_id = r.workflow_id
    WHERE r.object_id LIKE 'MAG%'
  ")
})

# Keep only most recent per object_id + key
results_latest <- results |>
  group_by(object_id, key) |>
  slice_max(workflow_date, n = 1, with_ties = FALSE) |>
  ungroup()
```

**For detail pages** (all historical values):

```r
results_all <- gopheR::with_gopher_con(function(con) {
  DBI::dbGetQuery(con, "
    SELECT r.key, r.value, r.workflow_id, w.workflow_date
    FROM result r
    JOIN workflow w ON w.workflow_id = r.workflow_id
    WHERE r.object_id = ?
    ORDER BY r.key, w.workflow_date DESC
  ", params = list(mag_id))
})

# Group by metric, show all entries
```

## Dependencies

Required R packages:
- gopheR
- tidyverse
- knitr
- reactable
- leaflet (for maps)

Quarto CLI required for rendering. Install from: https://quarto.org
