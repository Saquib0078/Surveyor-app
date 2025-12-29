# Garage Map Search Functionality

## ✅ Features Added

Added search functionality to garage map with auto-search based on accident location.

## 🔧 Changes Made

### 1. Updated API Request Format

**Before**:
```json
{
  "query": "",
  "page": 1,
  "limit": 100
}
```

**After**:
```json
{
  "search": {
    "value": "Akola"  // Search query
  },
  "page": 1,
  "limit": 100
}
```

### 2. Added Search State

```dart
final TextEditingController _searchController = TextEditingController();
String _currentSearch = '';
```

### 3. Auto-Search on Load

```dart
@override
void initState() {
  super.initState();
  // Auto-search with accident location if provided
  if (widget.accidentLocation != null && widget.accidentLocation!.isNotEmpty) {
    _searchController.text = widget.accidentLocation!;
    _currentSearch = widget.accidentLocation!;
  }
  _fetchGarages();
}
```

### 4. Added Search Bar UI

```dart
Positioned(
  top: 16,
  left: 16,
  right: 16,
  child: Card(
    child: Row(
      children: [
        Icon(Icons.search),
        TextField(
          controller: _searchController,
          hintText: 'Search by location...',
          onSubmitted: (value) {
            _currentSearch = value;
            _fetchGarages();
          },
        ),
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            _currentSearch = '';
            _fetchGarages();
          },
        ),
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            _currentSearch = _searchController.text;
            _fetchGarages();
          },
        ),
      ],
    ),
  ),
)
```

### 5. Pass Accident Location

```dart
GarageMapSelectionScreen(
  selectedGarageId: _selectedGarage?['id'],
  accidentLocation: _accidentLocationController.text, // Auto-search
)
```

## 🔄 Flow

### Auto-Search Flow:
```
Task Data
    ↓
accident_location: "Akola"
    ↓
Auto-filled in form
    ↓
User clicks "Select on Map"
    ↓
GarageMapSelectionScreen opens
    ↓
Search bar pre-filled with "Akola"
    ↓
API called with search: { value: "Akola" }
    ↓
Garages near Akola shown on map
```

### Manual Search Flow:
```
User on map screen
    ↓
Types "Mumbai" in search bar
    ↓
Presses Enter or Search button
    ↓
API called with search: { value: "Mumbai" }
    ↓
Garages near Mumbai shown on map
```

## 📊 API Request Example

```http
POST /motor_claim_api/garage/search
Content-Type: application/json

{
  "search": {
    "value": "Akola"
  },
  "page": 1,
  "limit": 100
}
```

## 🎯 Features

### 1. Auto-Search
- ✅ Pre-fills search with accident location
- ✅ Automatically searches on load
- ✅ Shows relevant garages immediately

### 2. Manual Search
- ✅ Search bar at top of map
- ✅ Type to search any location
- ✅ Clear button to reset search
- ✅ Search button to trigger search

### 3. Search Actions
- **Enter Key**: Triggers search
- **Search Button**: Triggers search
- **Clear Button**: Clears search and shows all garages

## 🎨 UI Layout

```
┌─────────────────────────────────┐
│  Select Garage on Map           │
│  X garages found            ✓   │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 🔍 Search by location... ✕ 🔍│ │ ← Search Bar
│ └─────────────────────────────┘ │
│                                 │
│         [Google Map]            │
│         with markers            │
│                                 │
│ ┌─────────────────────────────┐ │
│ │  Selected Garage Info       │ │ ← Bottom Card
│ │  [Garage Details]           │ │
│ │  [Select This Garage]       │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

## 📝 Example Usage

### Scenario 1: Task from Akola
```
1. Task has address: "Akola"
2. Auto-filled in accident location
3. User clicks "Select on Map"
4. Map opens with search: "Akola"
5. Shows garages near Akola
```

### Scenario 2: Search Different Location
```
1. Map opens with "Akola"
2. User types "Mumbai" in search
3. Presses Enter
4. Map updates to show Mumbai garages
```

### Scenario 3: Clear Search
```
1. Map shows filtered results
2. User clicks clear (✕) button
3. Search cleared
4. Shows all garages (100 limit)
```

## ✅ Summary

**Added**:
1. ✅ Search bar UI at top of map
2. ✅ Auto-search with accident location
3. ✅ Manual search functionality
4. ✅ Clear search button
5. ✅ Updated API request format

**API Format**:
```json
{
  "search": { "value": "location" },
  "page": 1,
  "limit": 100
}
```

**Result**: Users can now search for garages by location, with automatic search based on accident location! 🎉
