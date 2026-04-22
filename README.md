# gopherDen

**Genomic Objects & Provenance for Environmental Research - Example Template**

gopherDen is a GitHub template repository providing a working example of how to build domain-specific applications using the [gopheR](https://github.com/jeffkimbrel/gopheR) framework. This template demonstrates patterns for metagenomic/MAG research but can be customized for any domain (clinical, industrial, environmental, etc.).

## What's in the Box

This template includes:

- ✅ **Populated example database** (`inst/extdata/gopherDen_db.sqlite`) with realistic MAG data
- ✅ **Example Excel bundle** (`inst/extdata/example_bundle.xlsx`) showing data entry patterns
- ✅ **Helper functions** ([R/setup.R](R/setup.R)) for creating new databases
- ✅ **Tests** ([tests/testthat/](tests/testthat/)) ensuring helper functions work correctly
- ✅ **Reproducible data generation** (`data-raw/`) showing how the example was created
- 🚧 **Quarto report templates** (coming soon)
- 🚧 **Shiny data explorer** (coming soon)
- 🚧 **Domain-specific query functions** (coming soon)

## Quick Start

### 1. Use This Template

Click "Use this template" on GitHub to create your own copy. Give it a project-specific name like:
- `gopherDen-alpha-proteobacteria`
- `mylab-mag-database`
- `clinical-samples-db`

This gives you a **static snapshot** - not a fork, not connected to updates. It's yours to customize.

### 2. Customize Package Name

Edit the `DESCRIPTION` file to match your project name:

```r
Package: gopherDenAlpha  # Change this to match your repo name
Title: Alpha Proteobacteria MAG Database
# ... rest of file
```

**Why?** If you have multiple gopherDen projects, each needs a unique package name. This allows you to have multiple instances without conflicts.

### 3. Install gopheR

Install the gopheR framework package that gopherDen depends on:

```r
# Install the gopheR framework package
pak::pak("jeffkimbrel/gopheR")
```

### 4. Load Your Project Functions

gopherDen provides helper functions (like `make_new_db()`) that you access via `devtools::load_all()`:

```r
# In your gopherDen project directory
library(devtools)
load_all()

# Now functions are available in a clean namespace
gopherDenAlpha::make_new_db("my_data.sqlite")

# Or make them directly available (without package prefix)
load_all(".", export_all = FALSE)
make_new_db("my_data.sqlite")
```

**Benefits of `load_all()`:**
- ✅ Functions available without installing the package
- ✅ Clean namespace (no global environment pollution)
- ✅ Fast iteration (reload with `load_all()` after editing)
- ✅ Multiple projects can coexist independently
- ✅ Each project can customize functions for their domain

**Note:** Never use `source("R/setup.R")` - it pollutes your global environment. Always use `load_all()`.

### 5. Explore the Example Data

The template ships with a populated database containing realistic MAG data. **The example uses only keys and file roles from the gopheR starter database**, so it works immediately without custom configuration:
- 1 study, 2 field sites
- 6 soil samples
- 6 paired-end readsets
- 6 metagenomic assemblies
- 12 MAGs with quality metrics, taxonomy, and file manifests
- Complete provenance chains from site → sample → reads → assembly → MAG

```r
library(gopheR)

# Point to the example database
options(gopheR.db_path = "inst/extdata")
options(gopheR.db_file = "gopherDen_db.sqlite")

# Query high-quality MAGs
con <- gopher_con()
mags <- DBI::dbGetQuery(con, "
  SELECT o.object_id, o.label,
         MAX(CASE WHEN r.key = 'completeness' THEN r.value END) as completeness,
         MAX(CASE WHEN r.key = 'contamination' THEN r.value END) as contamination
  FROM object o
  LEFT JOIN result r ON o.object_id = r.object_id
  WHERE o.object_type = 'genome'
    AND CAST(MAX(CASE WHEN r.key = 'completeness' THEN r.value END) AS REAL) > 90
  GROUP BY o.object_id
")
DBI::dbDisconnect(con)
print(mags)
```

### 4. Try the Data Entry Workflow

The included `inst/extdata/example_bundle.xlsx` shows a complete, realistic example of data entry. You can:

**A) Validate without inserting** (safe, won't change the database):
```r
gopheR::read_bundle("inst/extdata/example_bundle.xlsx", validate_only = TRUE)
```

**B) Practice the full workflow** (ingest into a fresh database):
```r
# Load project functions
devtools::load_all()

# Create a test database
make_new_db("test_practice.sqlite")

# Point to your test database
options(gopheR.db_path = ".")
options(gopheR.db_file = "test_practice.sqlite")

# Ingest the example bundle
result <- gopheR::read_bundle("inst/extdata/example_bundle.xlsx")
print(result$results$objects)  # See what was inserted
```

This lets you practice the complete workflow: blank database → bundle ingestion → populated database.

## Key Concepts

### Using Functions: `load_all()` vs `source()`

gopherDen contains two types of R code with different usage patterns:

**Reusable Functions (in `R/`)** - Use `load_all()`
```r
devtools::load_all()        # Load all functions into namespace
make_new_db("my_db.sqlite") # Use functions cleanly
```
- ✅ Clean namespace (no global pollution)
- ✅ Proper documentation (`?make_new_db`)
- ✅ Fast iteration (reload after editing)
- ❌ **Never use** `source("R/setup.R")` - pollutes global environment

**Data Generation Scripts (in `data-raw/`)** - Use `source()`
```r
source("data-raw/populate_example_bundle.R") # Generate Excel bundle
```
- These are one-time scripts that generate data/files
- Not meant to be reusable functions
- OK to `source()` because they're not part of your working environment

**Quick Rule:** If it's in `R/`, use `load_all()`. If it's in `data-raw/`, use `source()`.

### Multiple Projects

Each gopherDen instance should have a unique package name:

```r
# Project 1: gopherDen-alpha
Package: gopherDenAlpha

# Project 2: clinical-samples  
Package: clinicalSamples

# Project 3: soil-microbiome
Package: soilMicrobiome
```

This allows you to work on multiple projects simultaneously without conflicts. Each uses `load_all()` in its own directory.

## Architecture: gopheR + gopherDen

### gopheR (The Framework Package)
An **installable R package** providing core infrastructure:
- ✅ Database schema enforcement
- ✅ Excel template generation with dropdowns
- ✅ Two-phase validation (pre-flight + database)
- ✅ Transaction-safe ingestion with automatic rollback
- ✅ **You install and update**: `pak::pak("jeffkimbrel/gopheR")`
- ✅ **Bug fixes propagate** when you update the package

**What's rigid:** Table names (`object`, `edge`, `workflow`, etc.) and column names  
**What's flexible:** The VALUES in spec tables - your custom types and relationships

### gopherDen (This Template Repository)
A **static copy** providing domain-specific implementation:
- 🗄️ Example database with omics types and realistic data
- 📊 Report templates (Quarto dashboards, analyses)
- 🔍 Domain-specific helper functions
- 📝 Data entry examples and patterns

**What you do:**
1. Click "Use this template" → you get a copy
2. Customize database specs for YOUR domain
3. Build reports and functions for YOUR science
4. Maintain independently

### Why This Design?

✅ **Bug fixes propagate** - gopheR updates reach everyone  
✅ **Customization freedom** - Each Den is unique without conflicts  
✅ **No forced updates** - Your reports/database never get overwritten  
✅ **Flexibility** - Adapt patterns to any domain

## Starting Your Own Project

### Option 1: Use the Example Database As-Is

The included `gopherDen_db.sqlite` has MAG-specific types already defined. If this fits your workflow, just start adding data:

```r
options(gopheR.db_path = "inst/extdata")
options(gopheR.db_file = "gopherDen_db.sqlite")

# Create a bundle for data entry
gopheR::write_bundle("my_data.xlsx", people_sheet = TRUE)

# Fill it out in Excel, then ingest
gopheR::read_bundle("my_data.xlsx")
```

### Option 2: Create a Fresh Database

If you need different object types (clinical, industrial, etc.), start from the gopheR starter database:

```r
# Load project functions
devtools::load_all()

# Create a new blank database
make_new_db("path/to/my_project.sqlite")

# Now customize the spec tables for your domain
# See "Customizing Your Domain" below
```

### Option 3: Regenerate the Example

Learn by rebuilding the example from scratch:

```r
# Load project functions
devtools::load_all()

# Create blank database
make_new_db("inst/extdata/test_db.sqlite")

# Generate the example bundle
source("data-raw/populate_example_bundle.R")

# Ingest it
options(gopheR.db_path = "inst/extdata")
options(gopheR.db_file = "test_db.sqlite")
gopheR::read_bundle("inst/extdata/example_bundle.xlsx")
```

## Customizing Your Domain

gopherDen is a **template** - the example is for MAGs, but you can adapt it to any domain. The key is customizing the **spec tables** in your database.

### What You Can Customize

**Object Types and Subtypes** (`object_type`, `object_subtype` tables)
- Example MAG domain: `genome:MAG`, `genome:isolate`, `sample:soil`, `readset:paired_end`
- Example clinical domain: `patient:adult`, `sample:blood`, `assay:RNAseq`, `treatment:chemotherapy`
- Example industrial: `batch:fermentation`, `sample:bioreactor`, `measurement:pH_probe`

**Edge Types** (`edge_spec` table)
- Defines valid relationships between object types
- Example: `assembled_from` connects `readset` → `assembly`
- Your domain: `sampled_from`, `diagnosed_with`, `derived_from`, etc.

**Result Keys** (`key_spec` table)
- Queryable measurements stored in the database
- Example MAG: `completeness`, `contamination`, `taxonomy`, `N50`, `size_bp`, `gc_content`
- Clinical: `viral_load`, `cell_count`, `expression_level`
- Industrial: `yield_percent`, `OD600`, `substrate_concentration`

**File Roles** (`object_file_type_spec` table)
- Types of files associated with each object type
- Example: `genome` can have `genome_fasta`; `readset` can have `fastq_r1`, `fastq_r2`
- Your domain: `raw_image`, `processed_data`, `qc_report`

**Note:** The example data only uses file roles that ship with the gopheR starter database. You can add custom file roles (like `protein_fasta`, `annotation_gff`) by inserting into `object_file_type_spec` as shown below.

### Modifying Spec Tables

```r
library(gopheR)

# Set database path
options(gopheR.db_path = "path/to/your/database/directory")
options(gopheR.db_file = "your_database.sqlite")

# Get connection (gopheR handles foreign keys automatically)
con <- gopher_con()

# Add a new object subtype
DBI::dbExecute(con,
  "INSERT INTO object_subtype (object_type, object_subtype, description, is_active)
   VALUES (?, ?, ?, 1)",
  params = list("sample", "blood", "Blood sample from patient"))

# Add a new result key for your domain
DBI::dbExecute(con,
  "INSERT INTO key_spec (object_type, key, value_type, description)
   VALUES (?, ?, ?, ?)",
  params = list("sample", "viral_load", "integer", "Viral copies per mL"))

# Add a new file role
DBI::dbExecute(con,
  "INSERT INTO object_file_type_spec (object_type, file_role, description)
   VALUES (?, ?, ?)",
  params = list("sample", "flow_cytometry", "Flow cytometry FCS file"))

DBI::dbDisconnect(con)
```

## Key Design Principles

### Database-Driven Everything

gopheR **never hardcodes** object types, edge types, or domain values. All validation pulls from your database spec tables. This is what makes gopherDen adaptable to any domain.

### Excel-Based Data Entry

Non-coders can contribute data using Excel bundles with:
- ✅ Validated dropdowns (only valid types, no typos)
- ✅ Pre-filled workflow IDs
- ✅ Left-to-right sheet ordering (people → workflow → object → edge → result → files)

### Transaction Safety

All ingestion happens in transactions with automatic rollback:
1. Pre-flight validation (fast checks, no database queries)
2. Create backup (only if pre-flight passes)
3. Begin transaction
4. Database validation (check specs, relationships)
5. Ingest all sheets in order
6. Commit or rollback + restore backup

**All-or-nothing** - no partial data corruption.

### Object Type Format

In Excel bundles, the `object_type` column accepts:
- **Plain types**: `study`, `site`, `sample` (when no subtype needed)
- **Combined format**: `genome:MAG`, `sample:soil`, `readset:paired_end`

gopheR parses these and populates `object_type` and `object_subtype` columns automatically.

## Project Structure

```
gopherDen/
├── inst/extdata/
│   ├── gopherDen_db.sqlite       # Populated example database
│   └── example_bundle.xlsx       # Example Excel bundle (for learning/practice)
├── data-raw/                      # Development scripts
│   ├── example_data_design.md    # Design doc for example data
│   └── populate_example_bundle.R # Script to generate example_bundle.xlsx
├── R/
│   └── setup.R                    # Helper: make_new_db()
├── tests/testthat/                # Test suite
│   └── test-setup.R               # Tests for make_new_db()
├── reports/                       # Quarto report templates (coming soon)
├── shiny/                         # Shiny apps (coming soon)
└── README.md                      # This file
```

## Example Data Contents

The `gopherDen_db.sqlite` database includes:

### Study & Sites
- 1 study: "Forest Soil Microbiome Study 2025"
- 2 sites: Sunny Ridge Forest, Pine Valley Forest

### Samples
- 6 soil samples (3 per site)
- Samples collected from different plots and depths

### Sequencing & Assembly
- 6 paired-end readsets (Illumina NovaSeq, 2x150bp)
- 6 metagenomic assemblies (metaSPAdes)
- Assembly metrics: N50, contig count

### MAGs (Metagenome-Assembled Genomes)
- 12 MAGs binned from assemblies (MetaBAT2)
- Quality assessment (CheckM2): completeness, contamination
- Taxonomy (GTDB-Tk r214): full lineage strings
- Genome metrics: size, GC content
- File manifest: genome FASTA

### Workflows
- 7 workflows documenting the full pipeline:
  - Field sampling, DNA extraction, sequencing
  - Assembly, binning, quality assessment, taxonomy

### Provenance
Complete relationships tracked via edges:
- Sites → Study (part_of)
- Samples → Sites (collected_from)
- Readsets → Samples (sequenced_from)
- Assemblies → Readsets (assembled_from)
- MAGs → Assemblies (binned_from)

## Workflow Example: Adding New Data

```r
# 1. Set database path
options(gopheR.db_path = "inst/extdata")
options(gopheR.db_file = "gopherDen_db.sqlite")

# 2. Create Excel template
gopheR::write_bundle("new_data.xlsx", people_sheet = TRUE)

# 3. Fill out Excel manually:
#    - Add people (if needed)
#    - Add workflows
#    - Add objects (sites, samples, MAGs, etc.)
#    - Add edges (relationships)
#    - Add results (measurements)
#    - Add object_files (file paths)

# 4. Validate before inserting
result <- gopheR::read_bundle("new_data.xlsx", validate_only = TRUE)

# 5. Ingest for real
result <- gopheR::read_bundle("new_data.xlsx")

# 6. Check summary
print(result$results$objects)
print(result$results$edges)
```

## When gopheR Updates

gopheR may have breaking changes in future versions. When this happens:

1. **Read the release notes** - explains what changed and why
2. **Check migration guide** - shows how to update your code
3. **Review updated gopherDen template** - see new patterns in action
4. **Adapt your copy** - update custom code following the guide

This is standard R package practice (tidyverse, shiny, etc.).

Example breaking change:
```
gopheR v0.6.0: BREAKING CHANGE
- read_bundle() now returns results$objects (plural) instead of results$object
- Migration: Change result$object to result$objects in your custom code
- See updated gopherDen template for examples
```

## Resources

- **gopheR package**: https://github.com/jeffkimbrel/gopheR
- **Issues & feedback**: https://github.com/jeffkimbrel/gopherDen/issues

## For Developers

### Running Tests

gopherDen includes tests for the helper functions:

```r
# Run all tests
devtools::test()

# Run tests with coverage
covr::package_coverage()
```

Tests cover:
- Database creation with `make_new_db()`
- Overwrite protection
- Directory creation
- Verification of gopheR starter schema (study:general, site:general subtypes)

### Regenerating Example Data

```r
# Load project functions
devtools::load_all()

# 1. Create blank database
make_new_db("inst/extdata/temp_db.sqlite")

# 2. Generate populated bundle
source("data-raw/populate_example_bundle.R")  # Data script to create Excel

# 3. Ingest to create populated database
file.copy("inst/extdata/temp_db.sqlite", 
          "inst/extdata/gopherDen_db.sqlite", 
          overwrite = TRUE)
options(gopheR.db_path = "inst/extdata")
options(gopheR.db_file = "gopherDen_db.sqlite")
gopheR::read_bundle("inst/extdata/example_bundle.xlsx")
```

**Note:** Data generation scripts in `data-raw/` are meant to be run with `source()` - they're one-time data builders, not reusable functions.

### Testing Your Customizations

```r
# Always validate before ingesting
result <- gopheR::read_bundle("my_bundle.xlsx", validate_only = TRUE)

# Use backup = FALSE during development for speed (not recommended for production!)
result <- gopheR::read_bundle("test_data.xlsx", backup = FALSE)
```

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.
