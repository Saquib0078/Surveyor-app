import 'package:flutter/material.dart';

class FormPreview extends StatefulWidget {
  final Map<String, Map<String, dynamic>> formData;
  final Function(bool) onScrollComplete;
  final Function(String) onSectionTap;
  final List<String>? excludedFields; // Add this parameter

  FormPreview({
    required this.formData,
    required this.onScrollComplete,
    required this.onSectionTap,
    this.excludedFields, // Initialize it
  });

  @override
  _FormPreviewState createState() => _FormPreviewState();
}

class _FormPreviewState extends State<FormPreview> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      if (!_hasReachedBottom) {
        setState(() {
          _hasReachedBottom = true;
        });
        widget.onScrollComplete(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            ...widget.formData.entries.map((section) => _buildSection(section)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Vehicle Insurance Claim Form',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(MapEntry<String, Map<String, dynamic>> section) {
    // Filter the fields in the section to exclude those listed in widget.excludedFields
    final filteredFields = section.value.entries
        .where((field) => widget.excludedFields == null || !widget.excludedFields!.contains(field.key))
        .toList();

    // Check if the filtered fields have any incomplete (null or empty) values
    bool isIncomplete = filteredFields.any((field) => field.value == null || field.value.toString().isEmpty);

    return GestureDetector(
      onTap: () => widget.onSectionTap(section.key),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              color: isIncomplete ? Colors.red[100] : Colors.grey[300],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    section.key.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (isIncomplete)
                    Icon(Icons.error_outline, color: Colors.red),
                ],
              ),
            ),
            ...filteredFields.map((field) => _buildField(field)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(MapEntry<String, dynamic> field) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${field.key}:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${field.value ?? 'Not provided'}',
              style: TextStyle(
                color: field.value == null || field.value.toString().isEmpty
                    ? Colors.red
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
