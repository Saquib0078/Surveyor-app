# Garage Data API Format

## ✅ Updated Garage Field Names

Changed the garage field names to match API requirements.

## 📋 API Format

### Network Garage:
```json
{
  "network_garages": 1
}
```

### Non-Network Garage:
```json
{
  "non_network_garages": {
    "name": "Custom Garage",
    "address": "123 Main St",
    "phone": "9876543210",
    "email": "garage@example.com"
  }
}
```

## 🔧 Changes Made

### Before (Wrong):
```dart
// Network garage
allDetails['garage_id'] = _selectedGarage!['id'];  // ❌

// Non-network garage
allDetails['non_network_garage'] = { ... };  // ❌
```

### After (Correct):
```dart
// Network garage
allDetails['network_garages'] = _selectedGarage!['id'];  // ✅

// Non-network garage
allDetails['non_network_garages'] = { ... };  // ✅
```

## 📊 Garage Data from API

When user selects a garage from the map:

```json
{
  "id": 1,
  "garage_name": "Garage 1",
  "garage_city": "Pune",
  "garage_state": "Maharashtra",
  "garage_phn_no": "7778889996",
  "garage_address_line1": "address 1",
  "garage_address_line2": "address 2",
  "garage_type": "Internal",
  "distance_km": 971.9
}
```

**What we send**: Only the `id` (1)

## 🔄 Data Flow

### Network Garage Flow:
```
User selects garage from map
    ↓
_selectedGarage = {id: 1, garage_name: "Garage 1", ...}
    ↓
allDetails['network_garages'] = 1
    ↓
API Request
    ↓
{
  "network_garages": 1
}
```

### Non-Network Garage Flow:
```
User enters custom garage details
    ↓
Name: "Custom Garage"
Address: "123 Main St"
Phone: "9876543210"
Email: "garage@example.com"
    ↓
allDetails['non_network_garages'] = {
  "name": "Custom Garage",
  "address": "123 Main St",
  "phone": "9876543210",
  "email": "garage@example.com"
}
    ↓
API Request
    ↓
{
  "non_network_garages": {
    "name": "Custom Garage",
    "address": "123 Main St",
    "phone": "9876543210",
    "email": "garage@example.com"
  }
}
```

## 🎯 Example API Requests

### Example 1: Network Garage Selected
```json
{
  "accident_datetime": "2025-12-23 10:54",
  "accident_location": "Akola",
  "network_garages": 1,
  "driver_name": "John Doe",
  ...
}
```

### Example 2: Non-Network Garage
```json
{
  "accident_datetime": "2025-12-23 10:54",
  "accident_location": "Akola",
  "non_network_garages": {
    "name": "Local Garage",
    "address": "456 Street",
    "phone": "9876543210",
    "email": "local@garage.com"
  },
  "driver_name": "John Doe",
  ...
}
```

### Example 3: No Garage Selected
```json
{
  "accident_datetime": "2025-12-23 10:54",
  "accident_location": "Akola",
  "driver_name": "John Doe",
  ...
}
```
(Neither `network_garages` nor `non_network_garages` is included)

## 📝 Debug Logs

### Network Garage:
```
Added network garage ID: 1
```

### Non-Network Garage:
```
Added non-network garage details
```

## ⚠️ Important Notes

1. **Mutually Exclusive**: Only one of `network_garages` or `non_network_garages` will be sent, never both
2. **Network Garage**: Sends only the `id` (integer)
3. **Non-Network Garage**: Sends complete details (object)
4. **Optional**: If no garage is selected, neither field is sent

## ✅ Summary

**Changed**:
- ✅ `garage_id` → `network_garages`
- ✅ `non_network_garage` → `non_network_garages`

**Network Garage**: Sends `id` only (e.g., `1`)

**Non-Network Garage**: Sends complete details object

The garage data now matches the API requirements! 🎉
