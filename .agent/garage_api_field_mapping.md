# Garage Map API Response Field Mapping

## ✅ Updated Field Names

Updated the garage map to use the correct field names from the actual API response.

## 📊 API Response Structure

```json
{
  "data": [
    {
      "id": 1,
      "garage_name": "Garage 1",
      "garage_latitude": "22.790882",
      "garage_longitude": "86.147209",
      "garage_city": "Pune",
      "garage_state": "Maharashtra",
      "garage_phn_no": "7778889996",
      "garage_address_line1": "address 1",
      "garage_address_line2": "address 2",
      "distance_km": 971.9,
      "garage_type": "Internal",
      "status": "Active"
    }
  ],
  "status": "success",
  "message": "No exact match found, showing nearest garages",
  "match_type": "nearest",
  "total": 6
}
```

## 🔧 Field Mapping Changes

### Before (Wrong):
```dart
garage['latitude']      // ❌ Doesn't exist
garage['longitude']     // ❌ Doesn't exist
```

### After (Correct):
```dart
garage['garage_latitude']   // ✅ Correct
garage['garage_longitude']  // ✅ Correct
garage['garage_name']       // ✅ Already correct
garage['garage_city']       // ✅ Already correct
garage['garage_phn_no']     // ✅ Correct
```

## 📝 Code Changes

### 1. Coordinate Validation
```dart
// Check if coordinates exist and are not empty strings
final lat = garage['garage_latitude'];
final lng = garage['garage_longitude'];

return lat != null && 
       lng != null &&
       lat.toString().isNotEmpty &&
       lng.toString().isNotEmpty &&
       lat.toString() != '' &&
       lng.toString() != '';
```

### 2. Marker Position
```dart
position: LatLng(
  double.parse(garage['garage_latitude'].toString()),
  double.parse(garage['garage_longitude'].toString()),
),
```

### 3. Info Window
```dart
infoWindow: InfoWindow(
  title: garage['garage_name'] ?? 'Unknown Garage',
  snippet: garage['distance_km'] != null 
      ? '${garage['distance_km']} km away' 
      : garage['garage_city'] ?? '',
),
```

## 🎯 Displayed Information

### On Map Marker:
- **Title**: `garage_name` (e.g., "Garage 1")
- **Snippet**: `distance_km` + "km away" or `garage_city`

### In Selected Garage Card:
- **Name**: `garage_name`
- **Location**: `garage_city`, `garage_state`
- **Phone**: `garage_phn_no`
- **Distance**: `distance_km` km

## ⚠️ Handling Empty Coordinates

Some garages have empty coordinates:
```json
{
  "garage_latitude": "",
  "garage_longitude": "",
  ...
}
```

**Solution**: Filter them out
```dart
lat.toString().isNotEmpty &&
lng.toString().isNotEmpty
```

## 📊 Example Data

### Garage with Coordinates (Shown on Map):
```json
{
  "id": 1,
  "garage_name": "Garage 1",
  "garage_latitude": "22.790882",
  "garage_longitude": "86.147209",
  "garage_city": "Pune",
  "distance_km": 971.9
}
```
**Result**: ✅ Marker shown at (22.790882, 86.147209)

### Garage without Coordinates (Hidden):
```json
{
  "id": 3,
  "garage_name": "Garage 3",
  "garage_latitude": "",
  "garage_longitude": "",
  "garage_city": "Jamshedpur"
}
```
**Result**: ❌ Not shown on map (no coordinates)

## 🗺️ Map Display

```
Map shows:
├── Garage 1 (Pune) - 971.9 km
├── Garage 2 (Jamshedpur) - 971.9 km
└── (Garages 3, 4, 5, 6 hidden - no coordinates)
```

## ✅ Summary

**Updated Fields**:
- ✅ `garage_latitude` (was `latitude`)
- ✅ `garage_longitude` (was `longitude`)
- ✅ Handles empty string coordinates
- ✅ Uses `double.parse()` for string coordinates
- ✅ Shows `garage_name`, `garage_city`, `distance_km`

**Result**: Map now correctly displays garages from the API response! 🎉
