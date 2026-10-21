import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../../../core/constants/app_colors.dart';

class GoogleTagsWidget extends StatefulWidget {
  final Function(List<String>) onTagsChanged;
  final List<String> initialTags;

  const GoogleTagsWidget({
    super.key,
    required this.onTagsChanged,
    this.initialTags = const [],
  });

  @override
  State<GoogleTagsWidget> createState() => _GoogleTagsWidgetState();
}

class _GoogleTagsWidgetState extends State<GoogleTagsWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _selectedTags = <String>{};
  List<String> _suggestions = [];
  bool _isLoading = false;
  int _selectedIndex = -1;
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _selectedTags.addAll(widget.initialTags);
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      _removeOverlay();
    }
  }

  Future<void> _fetchGoogleSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _selectedIndex = -1;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Using Google's suggest API (JSONP endpoint)
      final url =
          'https://suggestqueries.google.com/complete/search?client=firefox&q=${Uri.encodeComponent(query)}';

      print('HTTP GET request: $url');
      final response = await http.get(Uri.parse(url));
      print('HTTP GET response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.length > 1 && data[1] is List) {
          final suggestions = (data[1] as List)
              .map((e) => e.toString())
              .where((suggestion) => !_selectedTags.contains(suggestion))
              .take(8)
              .toList();

          setState(() {
            _suggestions = suggestions;
            _selectedIndex = -1;
          });

          if (suggestions.isNotEmpty) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        }
      }
    } catch (e) {
      print('Error fetching Google suggestions: $e');
      setState(() {
        _suggestions = [];
      });
      _removeOverlay();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchGoogleSuggestions(value);
    });
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_selectedTags.contains(tag.trim())) {
      setState(() {
        _selectedTags.add(tag.trim());
      });
      widget.onTagsChanged(_selectedTags.toList());
      _searchController.clear();
      _removeOverlay();
      setState(() {
        _suggestions = [];
        _selectedIndex = -1;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
    widget.onTagsChanged(_selectedTags.toList());
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_selectedIndex >= 0 && _selectedIndex < _suggestions.length) {
          _addTag(_suggestions[_selectedIndex]);
        } else if (_searchController.text.trim().isNotEmpty) {
          _addTag(_searchController.text.trim());
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _removeOverlay();
        _searchFocusNode.unfocus();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA0AEC0)),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  final isSelected = index == _selectedIndex;

                  return InkWell(
                    onTap: () => _addTag(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA0AEC0).withValues(alpha: 0.1)
                            : null,
                        borderRadius: index == 0
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              )
                            : index == _suggestions.length - 1
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 16,
                            color: Color(0xFF718096),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? const Color(0xFFA0AEC0)
                                    : const Color(0xFF2D3748),
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags Label
        Text(
          'Tags'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),

        // Search Input
        CompositedTransformTarget(
          link: _layerLink,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: _handleKeyPress,
            child: TextFormField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search in Google...'.tr,
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFA0AEC0),
                            ),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.search,
                        color: Color(0xFFA0AEC0),
                        size: 20,
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Selected Tags
        if (_selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFA0AEC0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
