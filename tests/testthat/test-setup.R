test_that("make_new_db creates a valid SQLite database", {
  temp_db <- tempfile(fileext = ".sqlite")

  result <- make_new_db(temp_db)

  expect_true(file.exists(temp_db))
  expect_equal(result, temp_db)

  # Verify it's a valid SQLite database by connecting to it
  con <- DBI::dbConnect(RSQLite::SQLite(), temp_db)
  tables <- DBI::dbListTables(con)
  DBI::dbDisconnect(con)

  # Should have gopheR starter tables
  expect_true("object" %in% tables)
  expect_true("edge" %in% tables)
  expect_true("workflow" %in% tables)
  expect_true("object_type" %in% tables)

  # Clean up
  unlink(temp_db)
})

test_that("make_new_db fails when file exists and overwrite = FALSE", {
  temp_db <- tempfile(fileext = ".sqlite")

  # Create initial database
  make_new_db(temp_db)
  expect_true(file.exists(temp_db))

  # Should fail on second attempt without overwrite
  expect_error(
    make_new_db(temp_db, overwrite = FALSE),
    "File already exists"
  )

  # Clean up
  unlink(temp_db)
})

test_that("make_new_db overwrites when overwrite = TRUE", {
  temp_db <- tempfile(fileext = ".sqlite")

  # Create initial database
  make_new_db(temp_db)
  initial_time <- file.info(temp_db)$mtime

  # Wait a moment to ensure different timestamp
  Sys.sleep(0.1)

  # Overwrite
  make_new_db(temp_db, overwrite = TRUE)
  new_time <- file.info(temp_db)$mtime

  expect_true(new_time > initial_time)

  # Clean up
  unlink(temp_db)
})

test_that("make_new_db creates parent directories if needed", {
  temp_dir <- tempfile()
  temp_db <- file.path(temp_dir, "subdir", "test.sqlite")

  expect_false(dir.exists(dirname(temp_db)))

  make_new_db(temp_db)

  expect_true(file.exists(temp_db))
  expect_true(dir.exists(dirname(temp_db)))

  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

test_that("make_new_db database has study:general and site:general subtypes", {
  temp_db <- tempfile(fileext = ".sqlite")

  make_new_db(temp_db)

  # Connect and check subtypes
  con <- DBI::dbConnect(RSQLite::SQLite(), temp_db)
  subtypes <- DBI::dbGetQuery(con,
    "SELECT object_type, object_subtype FROM object_subtype
     WHERE (object_type = 'study' AND object_subtype = 'general')
        OR (object_type = 'site' AND object_subtype = 'general')")
  DBI::dbDisconnect(con)

  expect_equal(nrow(subtypes), 2)
  expect_true(any(subtypes$object_type == "study" & subtypes$object_subtype == "general"))
  expect_true(any(subtypes$object_type == "site" & subtypes$object_subtype == "general"))

  # Clean up
  unlink(temp_db)
})
