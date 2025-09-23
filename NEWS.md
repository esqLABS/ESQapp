#  News

## Version 2.1.0.9003 (Development version)

#### **Main Changes:**
- **Integrated FunctionVisualizer into the `{ESQapp}`** Resolved an issue in (#177).
- **Updated the application color theme to the ESQlabs palette** Resolved an issue in (#177).


## Version 2.1.0.9002 (Development version)

#### **Documentation**
- **Update `Getting started` vignettes** Resolved an issue in (#176).


## Version 2.1.0.9001 (Development version)

#### **Bug Fixes**
- **In the Parameter Sets modal, replace the double quotes ("") with single quotes ('') when adding parameter to protect "MutliSelect" sorting editor.** Resolved an issue in (#174).


## Version 2.1.0 (2025-09-15)

#### **Main Changes:**
- **`Individuals` and `Population` dropdown** show available sheets as drop down in the "Individuals" and "Population". (#163)
- **Plots › DataCombined:** loads observed data in a modal window where users can select desired sheets; the *dataset* column is now a dropdown with available dataset names. (#168)

#### **Bug Fixes**
- **Remove `""` formatting from OutputPathIds dropdown** Resolved an issue in (#171).


## Version 2.0.0.9003 (Development version)

#### **Main Changes:**
- **Plots › DataCombined:** loads observed data in a modal window where users can select desired sheets; the *dataset* column is now a dropdown with available dataset names. (#168)


## Version 2.0.0.9002 (Development version)

#### **Bug Fixes**
- **Remove `""` formatting from OutputPathIds dropdown** Resolved an issue in (#171).


## Version 2.0.0.9001 (Development version)

#### **Main Changes:**
- **`Individuals` and `Population` dropdown** show available sheets as drop down in the "Individuals" and "Population". (#163)


## Version 2.0.0 (2025-08-19)

#### **Main Changes:**
- **SimulationTime Modal: remove "Time Unit" headers in the table** Resolved an issue in (#158).
- **Scenarios -> Outputpath_id column: show the actual path as sub-heading** Resolved an issue in (#160).

##### **Bug Fixes**
- **Sorted multi-dropdown menus: quoted sheets read incorrectly (`""`)** Resolved an issue in (#158).


## Version 1.0.5.9002 (Development version)

#### **Main Changes:**
- **Scenarios -> Outputpath_id column: show the actual path as sub-heading** Resolved an issue in (#160).


## Version 1.0.5.9001 (Development version)

#### **Main Changes:**
- **SimulationTime Modal: remove "Time Unit" headers in the table** Resolved an issue in (#158).

##### **Bug Fixes**
- **Sorted multi-dropdown menus: quoted sheets read incorrectly (`""`)** Resolved an issue in (#158).



## Version 1.0.5 (2025-07-30)

#### **Main Changes:**
- **Scenarios: Rename the column `ModelParameterSheets` to `Parameter sets`** Renamed the column only for presentation (in the UI), but retain the internal key ModelParameterSheets. (#141)
- **Scenarios: `SimulationTime` column tooltip`** Tooltip added to the "SimulationTime" column. (#141)
- **`Applications` and `Parameter sets` dropdown** show available sheets as drop down in the "Applications" and "Parameter sets". (#142)
- **Plots: Hide tabs `dataTypes`, `plotTypes`, `ObservedDataNames`** Resolved an issue in (#146)
- **Suppress printing `New names:` when loading excel files with columns without names** Resolved an issue in (#146)
- **Rename "Add Parameter" to "Add Parameter Set"** Resolved an issue in (#148)
- **`Add new column` feature added to -> Plots: `plotConfiguration`, `plotGrids`, and `exportConfiguration`** Resolved an issue in (#148)
- **`Plots` tab -> `exportConfiguration` sheet, replace `plotGridName` text type with dropdown** Resolved an issue in (#148)
- **`Plots` tab -> `plotGrids` sheet -> `plotIDs`column added sortable dropdown feature** Resolved an issue in (#149)

##### **Bug Fixes**
- **"Del" key doesn't delete "SimulationTimeUnit" cell content:** Resolved an issue in (#139).
- **"SimulationTimeUnit", "ModelParameterSheets" and "OutputPahtIds" are not copied in the "Scenario" sheet** Resolved an issue in (#140).
- **Entries get reset when switching between tabs** Resolved an issue in (#140).
- **Special characters not displayed properly in the "Parameters" table** Resolved an issue in (#148)
- **When the "Demographics" sheet of the "Populations.xslx" file is empty, it is not possible to add new entries** Resolved an issue in (#148)


## Version 1.0.4.9007 (Development version)

#### **Main Changes:**
- **`Plots` tab -> `plotGrids` sheet -> `plotIDs`column added sortable dropdown feature** Resolved an issue in (#149)


## Version 1.0.4.9006 (Development version)

#### **Main Changes:**
- **Rename "Add Parameter" to "Add Parameter Set"** Resolved an issue in (#148)
- **`Add new column` feature added to -> Plots: `plotConfiguration`, `plotGrids`, and `exportConfiguration`** Resolved an issue in (#148)
- **`Plots` tab -> `exportConfiguration` sheet, replace `plotGridName` text type with dropdown** Resolved an issue in (#148)

#### **Bug Fixes:**
- **Special characters not displayed properly in the "Parameters" table** Resolved an issue in (#148)
- **When the "Demographics" sheet of the "Populations.xslx" file is empty, it is not possible to add new entries** Resolved an issue in (#148)


## Version 1.0.4.9005 (Development version)

#### **Main Changes:**
- **Plots: Hide tabs `dataTypes`, `plotTypes`, `ObservedDataNames`** Resolved an issue in (#146)
- **Suppress printing `New names:` when loading excel files with columns without names** Resolved an issue in (#146)

## Version 1.0.4.9004 (Development version)

#### **Main Changes:**
- **`Applications` and `Parameter sets` dropdown** show available sheets as drop down in the "Applications" and "Parameter sets". (#142)

## Version 1.0.4.9003 (Development version)

#### **Main Changes:**
- **Scenarios: Rename the column `ModelParameterSheets` to `Parameter sets`** Renamed the column only for presentation (in the UI), but retain the internal key ModelParameterSheets. (#141)
- **Scenarios: `SimulationTime` column tooltip`** Tooltip added to the "SimulationTime" column. (#141)

## Version 1.0.4.9002 (Development version)

##### **Bug Fixes**
- **"SimulationTimeUnit", "ModelParameterSheets" and "OutputPahtIds" are not copied in the "Scenario" sheet** Resolved an issue in (#140).
- **Entries get reset when switching between tabs** Resolved an issue in (#140).

## Version 1.0.4.9001 (Development version)

##### **Bug Fixes**
- **"Del" key doesn't delete "SimulationTimeUnit" cell content:** Resolved an issue in (#139).


## Version 1.0.4 (2025-06-06)

#### **Main Changes:**
- **Scenario Name Validation** Added row highlight to prevent duplicate scenario names in the Scenario_name sheet. (#126)
- **Dropdown Validation for `IndividualId` and `PopulationId`** If duplicates are found in the `IndividualId` or `PopulationId` dropdowns, they are highlighted, and all validation errors are shown in a pop-up window for clarity. (#127)
- **"Enter Simulation Time" Dialog Automatically Converts Units Updates the "Enter Simulation Time** dialog to automatically convert user-entered time values to match the unit of the first "start" entry. (#132)
- **Enhancing Individual Biometrics and Population with Protein–Ontogeny Mapping** Adds a new column, Protein–Ontogeny, to the IndividualBiometrics sheet in the Individuals tab and the Demographics sheet in the Populations tab. Double-clicking a cell in this column opens a dialog for defining a Protein ↔ Ontogeny mapping, where the protein is entered by the user and the ontogeny is selected from `ospsuite::StandardOntogeny`. (#124)


##### **Bug Fixes**

- **Enhanced Handsontable Functionality:** Resolved an issue in `esqlabs.handsontable` where rows became unresponsive after clearing their contents and pasting new copied rows value. (#131)
  

## Version 1.0.3.9004 (Development version)

#### **Main Changes:**

- **Scenario Name Validation** Added row highlight to prevent duplicate scenario names in the Scenario_name sheet. (#126)
- **Dropdown Validation for `IndividualId` and `PopulationId`** If duplicates are found in the `IndividualId` or `PopulationId` dropdowns, they are highlighted, and all validation errors are shown in a pop-up window for clarity. (#127)


## Version 1.0.3.9003 (Development version)

#### **Main Changes:**

- **"Enter Simulation Time" Dialog Automatically Converts Units Updates the "Enter Simulation Time** dialog to automatically convert user-entered time values to match the unit of the first "start" entry. (#132)


## Version 1.0.3.9002 (Development version)

##### **Bug Fixes**

- **Enhanced Handsontable Functionality:** Resolved an issue in `esqlabs.handsontable` where rows became unresponsive after clearing their contents and pasting new copied rows value. (#131)

## Version 1.0.3.9001 (Development version)

#### **Main Changes:**

- **Enhancing Individual Biometrics and Population with Protein–Ontogeny Mapping** Adds a new column, Protein–Ontogeny, to the IndividualBiometrics sheet in the Individuals tab and the Demographics sheet in the Populations tab. Double-clicking a cell in this column opens a dialog for defining a Protein ↔ Ontogeny mapping, where the protein is entered by the user and the ontogeny is selected from `ospsuite::StandardOntogeny`. (#124)


## Version 1.0.3 (2025-03-27)

#### **Main Changes:**

- **Enable first remove:** (#122)  
- **ModelParameterSheets colum dropdown-sorting componet:** Listing all sheets present in the ModelParameters file. (#121)  
- **Application Protocol Dropdown:** ApplicationProtocol - drop-down with sheet names from "Applications". (#113)  
- **Simulation Time modal window update:** The "Enter Simulation Time" dialog (#76) now appears upon double-clicking the cell in the Scenarios table (#75), with full support for all time units (#111).
- **Application tab and Parameter Tab:** In both the Application and Parameter tabs, users can add new or remove existing parameter sets within the Parameter Sets tab (#83).
- **Application Staring time improved:** (#69)  
- **[Scenarios] OutputPathId column update:** Disable sorting feature (#77)
- **Add a --NONE-- option to all dropdown menus across the application.** The first entry in each dropdown is --NONE--, enabling users to intuitively clear the selection by choosing this option, which returns an empty value. (#72)


##### **Documentation**

Updated documentation. (#107); (#104)


##### **Bug Fixes**

- **Enhanced Handsontable Functionality:** Upgraded `esqlabs.handsontable` to support dynamically adding and removing parameter sheets in the Individuals tab. (#95)  
- **Improved Export Behavior:** Modified the export function to overwrite the existing file instead of creating duplicates. (#96)  




## Version 1.0.2 (2025-01-30)

#### **Main Changes:**

- **Exit Confirmation:** Users will now see a confirmation dialog before closing the application, preventing accidental exits. (#97)  
- **Default Browser Launch:** The application now opens in the system’s default web browser instead of the RStudio viewer for a better user experience. (#98)  
- **Export Status Dialog:** A new dialog window displays the export status, providing clear feedback on success or failure. (#100)  
- **Guided Walkthrough:** Introduced an interactive walkthrough to help users navigate the app and understand its key features. (#94)  


##### **Bug Fixes**

- **Enhanced Handsontable Functionality:** Upgraded `esqlabs.handsontable` to support dynamically adding and removing parameter sheets in the Individuals tab. (#95)  
- **Improved Export Behavior:** Modified the export function to overwrite the existing file instead of creating duplicates. (#96)  


##### **Documentation**

Updated documentation. (#102)


## Version 1.0.1 (2025-01-16)

### Project Core Package Update (esqlabsR 5.1.1 => 5.3.0)

#### **Main Changes:**

##### **Package Update**

Updated esqlabsR package version to 5.3.0.

##### **Bug Fixes**

- Resolved a crash when trying to load a project configuration. (#63)
- Fixed a crash that occurred when selecting a non-xlsx file while loading a project configuration. (#62)
- Addressed a warning message displayed during startup. (#60)

##### **Documentation**

Updated installation instructions to recommend the use of the pack package. (#59)


## Version 1.0.0 (2024-12-17)

### Initial Release (development version)

This is the initial release of the `ESQapp` package, providing core features for project configuration and data manipulation through a user interface, as an alternative to the `esqlabsR` package.

### Core Features
- **Select and Import Configuration File**: Allows users to select a project configuration Excel file and import connected sheets.
- **Data Entry via UI**: Facilitates data entry into sheets through a user interface, offering an alternative to the `esqlabsR` package.
- **Export Results**: Provides functionality to export results.

### Realized in This Version
- **Intermediate Package**: The `esqlabs.handsontable` package acts as an intermediate between the React.js Handsontable module and R/Shiny, splitting each table into separate JS components and enabling table editing to replicate Excel functionality.
- **Reactivity Across All Tables**: Ensures that changes in one table are automatically reflected in others, maintaining consistency and real-time updates.
- **`SimulationTime` Column Editor**: A dedicated editor for managing values in the `SimulationTime` column.
- **`OutputPathIds` Column Editor**: An editor for entering and ordering IDs in the `OutputPathIds` column.
- **Context Menu**: Provides a context menu for additional table functionalities.
- **Shortcuts**: Implements keyboard shortcuts to enhance user efficiency.
- **Integration with esqlabs.ui Package**: Integrates with the `esqlabs.ui` package for a seamless user experience.
- **Multiselect Dropdown Column Editor**: A column editor that supports multiselect dropdowns for more flexible data entry.
- **Project Configuration Import Validation**: The application validates the imported configuration against the default structure. If discrepancies are detected, it displays a warning message and provides a list of issues for the user to review.

---

This version marks the beginning of the `ESQapp` package, bringing a robust set of features to enhance data handling and project management through an intuitive user interface.
