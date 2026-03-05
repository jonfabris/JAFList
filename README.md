# JAFList - iOS Todo List App

A SwiftUI-based iOS todo list application with folders, nested sublists, checkboxes, and JSON-based cloud sync.

## Features

- **Folders**: Organize tasks into folders
- **Nested Lists**: Create unlimited nesting of sub-items
- **Checkboxes**: Mark items as complete with strikethrough
- **Expand/Collapse**: Show/hide nested children
- **JSON Persistence**: Auto-save to local JSON file
- **Cloud Export**: Share JSON file via Files app, iCloud Drive, AirDrop

## Requirements

- Xcode 14.0 or later
- iOS 16.0 or later
- Swift 5.0

## Getting Started

### Opening the Project

1. Navigate to the `JAFList` directory
2. Open `JAFList.xcodeproj` in Xcode
3. Select a simulator or device
4. Press Cmd+R to build and run

### Project Structure

```
JAFList/
├── JAFListApp.swift              # App entry point
├── Models/
│   ├── TodoItem.swift            # Recursive todo item model
│   ├── Folder.swift              # Folder container model
│   └── AppData.swift             # Root data model
├── ViewModels/
│   └── AppViewModel.swift        # State management
├── Services/
│   ├── DataStore.swift           # File I/O and persistence
│   └── JSONService.swift         # JSON encoding/decoding
└── Views/
    ├── ContentView.swift         # Folder list view
    ├── FolderView.swift          # Todo item list view
    └── TodoItemRow.swift         # Recursive item row
```

## Usage

### Creating Folders

1. Tap the **+** button in the top-right corner
2. Enter a folder name
3. Tap **Add**

### Creating Todo Items

1. Tap on a folder to open it
2. Tap the **+** button in the top-right corner
3. Enter the item text
4. Tap **Add**

### Creating Sub-Items

1. Swipe left on any todo item
2. Tap the **Add Subitem** button (blue)
3. Enter the subitem text
4. Tap **Add**

### Completing Items

- Tap the checkbox (circle icon) to mark an item as complete
- The text will show a strikethrough
- Tap again to unmark

### Expanding/Collapsing Items

- Tap on an item with children to expand/collapse its nested items
- Chevron icon indicates if item has children

### Deleting Items/Folders

- Swipe left on any item or folder
- Tap the **Delete** button (red)

### Cloud Export

1. Tap the **Share** button (top-left corner in folder list)
2. Choose a destination:
   - Files app
   - iCloud Drive
   - AirDrop to another device
   - Other share options
3. The JSON file will be saved/sent

## Data Storage

All data is stored in a single JSON file:
- Location: `~/Documents/jaflist_data.json`
- Auto-saves with debouncing (0.5 second delay)
- Saves immediately when app enters background
- Pretty-printed for readability

### JSON Structure

```json
{
  "folders": [
    {
      "id": "uuid",
      "name": "Folder Name",
      "items": [
        {
          "id": "uuid",
          "text": "Todo item text",
          "isCompleted": false,
          "isExpanded": false,
          "children": [
            {
              "id": "uuid",
              "text": "Nested item",
              "isCompleted": false,
              "isExpanded": false,
              "children": []
            }
          ]
        }
      ]
    }
  ],
  "lastModified": "2024-01-01T12:00:00Z"
}
```

## Architecture

### MVVM Pattern

- **Models**: Data structures (`TodoItem`, `Folder`, `AppData`)
- **Views**: SwiftUI views (`ContentView`, `FolderView`, `TodoItemRow`)
- **ViewModel**: `AppViewModel` manages state and business logic
- **Services**: `DataStore` handles persistence, `JSONService` handles encoding/decoding

### Key Design Decisions

1. **Recursive Structure**: `TodoItem` contains `children: [TodoItem]` for unlimited nesting
2. **Reactive Updates**: `@Published` properties trigger UI updates automatically
3. **Debounced Saving**: Prevents excessive file writes during rapid interactions
4. **Single Source of Truth**: `AppViewModel` is the central state manager

## Testing Checklist

- [x] Create folders
- [x] Create items in folders
- [x] Toggle checkboxes
- [x] Add nested sub-items
- [x] Expand/collapse items with children
- [x] Delete items and folders
- [x] Data persists after force quit
- [x] Cloud export works
- [x] Deep nesting (3+ levels) works correctly

## Known Limitations

- Single user (no multi-user sync)
- No authentication
- Manual cloud upload (user-initiated)
- No conflict resolution (last write wins)
- No import functionality (export only)

## Future Enhancements

- Import from JSON file
- iCloud sync
- Reminders/due dates
- Tags and filters
- Search functionality
- Reordering items
- Undo/redo

## License

This project was created as a demonstration app.
