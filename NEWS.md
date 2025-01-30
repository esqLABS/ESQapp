#  News

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
