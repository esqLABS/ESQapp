#  News

## Version 0.0.0.9000

### Initial Release (development version)

This is the initial release of the `shinyScenarioEditor` package, providing core features for project configuration and data manipulation through a user interface, as an alternative to the `esqlabsR` package.

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

---

This version marks the beginning of the `shinyScenarioEditor` package, bringing a robust set of features to enhance data handling and project management through an intuitive user interface.
