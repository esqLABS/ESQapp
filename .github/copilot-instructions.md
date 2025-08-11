# ESQapp - R Package & Shiny Application for Pharmaceutical Simulation Scenarios

ESQapp is an R package containing a Shiny web application for editing and managing esqlabsR simulation scenarios in the Open Systems Pharmacology Suite. It provides a GUI interface for creating, editing, and running pharmaceutical modeling scenarios.

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Environment Compatibility Matrix

| Environment Type | What Works | What Fails | Recommended Workflow |
|------------------|------------|------------|---------------------|
| **Full Development (R+RStudio+Internet)** | Everything | - | Full development workflow |
| **CI/GitHub Actions** | Package validation, basic checks | renv restore, app startup | Focus on structure validation |
| **Restricted Network** | Basic R operations, structure checks | Package installation, external deps | Manual validation only |
| **Local with Limited Deps** | devtools operations, some testing | App startup, full tests | Partial development workflow |

## Working Effectively

### Initial Setup (For Fresh Repository Clone)
1. **Install R and system dependencies:**
   ```bash
   sudo apt update && sudo apt install -y r-base
   sudo apt install -y r-cran-devtools r-cran-testthat r-cran-shiny r-cran-dplyr r-cran-jsonlite r-cran-r6 r-cran-bslib
   ```

2. **Comprehensive Package Validation (ALWAYS START HERE):**

Before attempting any development work, run this validation to understand what's available:

```bash
cd /path/to/ESQapp
R --slave -e "
cat('=== ESQapp Package Validation ===\\n')
cat('R version:', R.version.string, '\\n')

# Test basic package structure
if(file.exists('DESCRIPTION') && file.exists('NAMESPACE') && dir.exists('R')) {
  cat('✓ Package structure: VALID\\n')
} else {
  cat('✗ Package structure: INVALID\\n')
}

# Count files
r_files <- length(list.files('R', pattern='.R'))
test_files <- length(list.files('tests/testthat', pattern='.R'))
cat('✓ R files found:', r_files, '\\n')
cat('✓ Test files found:', test_files, '\\n')

# Check key dependencies
deps <- c('devtools', 'testthat', 'shiny', 'golem', 'config')
cat('Available dependencies:\\n')
for(dep in deps) {
  available <- requireNamespace(dep, quietly=TRUE)
  cat('  ', dep, ':', if(available) '✓ AVAILABLE' else '✗ MISSING', '\\n')
}

cat('=== Validation Complete ===\\n')
"
```

**This validation ALWAYS works and tells you:**
- Whether basic R functionality is working
- Package structure integrity  
- Which dependencies are available vs missing
- Whether to attempt advanced operations or focus on basic validation

**DECISION TREE based on validation results:**
- **5/5 dependencies available**: Proceed with full development workflow
- **3-4/5 dependencies available**: Use partial workflow, focus on basic operations
- **1-2/5 dependencies available**: Structure validation and manual inspection only
- **0/5 dependencies available**: Manual file review, document missing packages

3. **Attempt dependency restoration (ENVIRONMENT-DEPENDENT):**
   ```bash
   R --slave -e "source('renv/activate.R')"
   R --slave -e "renv::restore(lockfile = 'renv.lock')"
   ```
   **CRITICAL TIMING:** Dependency installation takes 45-90 minutes. NEVER CANCEL. Set timeout to 120+ minutes.
   
   **NETWORK LIMITATIONS:** If external R repositories are blocked (common in CI environments):
   - renv bootstrap will fail with "cannot open URL" errors - this is EXPECTED
   - GitHub-hosted packages (esqlabsR, esqlabs.ui, esqlabs.handsontable) may be inaccessible
   - Document which packages failed and note in commit messages: "Dependencies unavailable due to network restrictions"
   - Continue with available packages for basic structural validation

4. **Validate what dependencies are available:**
   ```bash
   R --slave -e "available_packages <- c('devtools', 'testthat', 'shiny'); sapply(available_packages, function(x) requireNamespace(x, quietly=TRUE))"
   ```

5. **Alternative minimal setup (if renv fails completely):**
   ```bash
   # Only attempt if you have internet access to CRAN
   R --slave -e "install.packages(c('golem', 'config', 'shinyFiles', 'rio', 'fs'), repos='https://cloud.r-project.org')"
   ```

### Building and Documentation

**DEPENDENCY WARNING:** These commands require specialized packages. If dependencies are not available, these commands will fail immediately with package loading errors. This is EXPECTED in restricted environments.

```bash
# Check basic package structure first (always works)
R --slave -e "if(file.exists('DESCRIPTION') && file.exists('NAMESPACE') && dir.exists('R')) cat('Package structure: VALID\n') else cat('Package structure: INVALID\n')"

# Attempt documentation - takes 2-5 minutes IF dependencies available. NEVER CANCEL. Set timeout to 10+ minutes.
R --slave -e "devtools::document()"

# Attempt package build - takes 10-15 minutes IF dependencies available. NEVER CANCEL. Set timeout to 30+ minutes.
R --slave -e "devtools::build()"

# Basic structure check without dependencies (usually works)
R --slave -e "devtools::check(document = FALSE, build_args = '--no-build-vignettes')"
```

**EXPECTED FAILURE SCENARIOS:**
- `Error: there is no package called 'golem'` - Expected when golem framework is not available
- `Error: The packages "esqlabsR", "ospsuite" are required` - Expected when specialized pharmaceutical packages are not available
- Network timeout errors during package installation - Expected in CI environments

### Running Tests

**DEPENDENCY WARNING:** Testing requires ALL specialized dependencies. Expect failures in restricted environments.

```bash
# Check what test infrastructure exists (always works)
R --slave -e "cat('Test files found:', length(list.files('tests/testthat', pattern='*.R')), '\n')"

# Attempt to run tests - takes 5-10 minutes if dependencies available. NEVER CANCEL. Set timeout to 20+ minutes.
R --slave -e "devtools::test()"
```

**EXPECTED OUTCOMES:**
- **Full dependencies available:** Tests run against pharmaceutical modeling scenarios with PKML files
- **Limited dependencies:** `Error: The packages "esqlabsR" (>= 5.3.0) are required` - This is EXPECTED
- **No dependencies:** Immediate failure on first package load - Document and continue with other validation

### Running the Application

**DEPENDENCY WARNING:** Application requires golem framework and specialized pharmaceutical packages.

```bash
# Check if core files exist for app startup (always works)
R --slave -e "if(file.exists('dev/run_dev.R')) cat('Development script: FOUND\n') else cat('Development script: MISSING\n')"

# Attempt development mode startup (preferred when dependencies available)
R --slave -e "source('dev/run_dev.R')"

# Alternative direct app execution 
R --slave -e "ESQapp::run_app()"
```

**CRITICAL TIMING:** App startup takes 30-60 seconds. NEVER CANCEL. Set timeout to 120+ seconds.

**EXPECTED OUTCOMES:**
- **Success:** "Listening on http://127.0.0.1:XXXX" message appears, browser opens
- **Dependency failure:** `Error: there is no package called 'golem'` - Expected without dependencies
- **Network issues:** May fail to load external CSS/JS resources

**APP RUNTIME:** The application starts a local web server. In headless environments, note the URL but browser auto-opening may fail.

## Validation Scenarios

### ALWAYS perform these manual validation steps after making changes:

1. **Application Startup Test:**
   - Run `source('dev/run_dev.R')` 
   - Verify the app starts without errors
   - Check the browser opens to the application interface
   - Verify the ESQapp logo and interface loads correctly

2. **Basic Interface Test:**
   - Navigate through main tabs: Scenarios, Individuals, Populations, Models, Plots, Applications
   - Test sidebar navigation and module switching
   - Verify no JavaScript errors in browser console

3. **File Import Test (if dependencies available):**
   - Try importing sample data from `tests/testthat/data/` 
   - Test Excel file imports (.xlsx files in Parameters folder)
   - Verify data loads into interactive tables

### Screenshots Required
- ALWAYS take a screenshot of the running application main interface
- Document any UI changes with before/after screenshots
- Capture error messages or loading states if issues occur

## Common Development Tasks

### Adding New Dependencies
```bash
# Install new package and update lockfile snapshot - takes 15-30 minutes. NEVER CANCEL. Set timeout to 45+ minutes.
R --slave -e "renv::install('package_name')"
R --slave -e "source('dev/get_snapshot.R')"
R --slave -e "golem::add_to_description('package_name')"
R --slave -e "golem::document_and_reload()"
```

### Code Style and Linting

**DEPENDENCY WARNING:** Style tools may not be available in all environments.

```bash
# Check if styler is available
R --slave -e "if(requireNamespace('styler', quietly=TRUE)) cat('styler: AVAILABLE\n') else cat('styler: NOT AVAILABLE\n')"

# ALWAYS attempt before committing - takes 2-3 minutes IF available. Set timeout to 5+ minutes.
R --slave -e "styler::style_pkg()"

# Spell checking (if available)
R --slave -e "if(requireNamespace('spelling', quietly=TRUE)) devtools::spell_check() else cat('Spell checking not available\n')"

# Update package documentation (if golem available)
R --slave -e "if(requireNamespace('golem', quietly=TRUE)) golem::document_and_reload() else cat('golem not available\n')"
```

**FALLBACK APPROACH:** If automated style tools are not available:
- Manually review R code for basic formatting consistency
- Check indentation and spacing in modified files
- Ensure function documentation follows roxygen2 style (lines starting with #')

### Testing Specific Modules
```bash
# Test specific files
R --slave -e "testthat::test_file('tests/testthat/test-utils.R')"
```

## Repository Structure Navigation

### Key Files and Directories
```
ESQapp/
├── R/                          # Main R package code
│   ├── run_app.R              # Application entry point
│   ├── app_ui.R               # Main UI definition
│   ├── app_server.R           # Main server logic
│   └── mod_*.R                # Shiny modules for different features
├── inst/app/                  # Application assets
│   ├── www/                   # Web assets (CSS, JS, images)
│   └── samples/               # Sample data files
├── tests/testthat/            # Test files
│   └── data/                  # Test data including PKML files and Excel templates
├── dev/                       # Development scripts
│   ├── run_dev.R             # Start app in development mode
│   ├── get_snapshot.R        # Update dependency snapshot
│   └── 0*_*.R                # Golem development workflow scripts
├── renv.lock                  # Dependency lockfile
└── DESCRIPTION               # Package metadata and dependencies
```

### Key Dependencies to Understand
- **golem**: Framework for building production-ready Shiny applications
- **esqlabsR**: Core pharmaceutical modeling package (may not be available in CI)
- **ospsuite**: Open Systems Pharmacology modeling suite integration
- **esqlabs.handsontable**: Custom table interface for data editing
- **shiny/bslib**: Web interface framework

## Expected Build and Test Times

| Operation | Expected Time | Timeout Setting | Notes |
|-----------|---------------|-----------------|-------|
| Package validation script | 1-2 seconds | 10 seconds | Always works |
| `renv::restore()` | 45-90 minutes | 120+ minutes | May fail due to network |
| `devtools::document()` | 2-5 minutes | 10+ minutes | Requires golem/dependencies |
| `devtools::build()` | 10-15 minutes | 30+ minutes | Requires dependencies |
| `devtools::check()` (basic) | 2-3 seconds | 30 seconds | Works without dependencies |
| `devtools::test()` | 5-10 minutes | 20+ minutes | Requires all dependencies |
| `source('dev/run_dev.R')` | 30-60 seconds | 120+ seconds | Requires golem |
| `styler::style_pkg()` | 2-3 minutes | 5+ minutes | If styler available |

## Common Issues and Workarounds

### Network/Dependency Issues
- **External repositories blocked**: Use apt packages where available, document missing dependencies
- **GitHub rate limits**: Wait and retry, or use different authentication
- **rClr dependency**: May require manual download as shown in `dev/02_dev.R`

### Application Issues  
- **Port conflicts**: The app uses `httpuv::randomPort()` by default
- **Browser not opening**: Check if running in headless environment
- **Module loading failures**: Usually indicates missing domain-specific dependencies

### Development Workflow Issues
- **RStudio-specific functions**: Some `dev/` scripts reference RStudio IDE - skip these in non-RStudio environments
- **Package namespace issues**: Run `golem::document_and_reload()` to refresh

## CI/CD Integration Notes

- Package builds successfully with basic structure validation even without specialized dependencies
- Full functionality requires pharmaceutical modeling packages that may not be available in all CI environments
- Focus on code style, basic package structure, and documentation generation for automated checks
- Manual testing of application functionality should be done in environments with full dependencies

## Important: Always Follow These Rules

1. **NEVER CANCEL** long-running operations - pharmaceutical R packages are complex and take time
2. **ALWAYS** run `styler::style_pkg()` before committing code changes
3. **ALWAYS** test application startup after making changes to UI/server code
4. **ALWAYS** check for missing dependencies and document them clearly
5. **ALWAYS** take screenshots when testing UI changes
6. **NEVER** commit dependency changes without updating the renv.lock snapshot

Remember: This is a specialized pharmaceutical modeling application. Some functionality requires domain-specific packages that may not be available in all environments. Focus on code quality, structure, and basic functionality validation.

## Appendix: Quick Environment Test

Run this to simulate following the instructions step-by-step:

```bash
R --slave -e "
cat('=== ENVIRONMENT CAPABILITY TEST ===\\n')

# Package structure  
structure_ok <- file.exists('DESCRIPTION') && file.exists('NAMESPACE') && dir.exists('R')
cat('Package structure:', if(structure_ok) '✓ VALID' else '✗ INVALID', '\\n')

# Dependencies
deps <- c('devtools', 'testthat', 'shiny', 'golem', 'config')
available_count <- sum(sapply(deps, function(x) requireNamespace(x, quietly=TRUE)))
cat('Dependencies available:', available_count, '/', length(deps), '\\n')

# Recommendation
if(available_count >= 3) {
  cat('RECOMMENDATION: Proceed with development workflow\\n')
} else if(available_count >= 1) {
  cat('RECOMMENDATION: Basic validation only\\n') 
} else {
  cat('RECOMMENDATION: Manual inspection only\\n')
}
cat('=== TEST COMPLETE ===\\n')
"
```

Use this test result to choose the appropriate workflow level from the instructions above.