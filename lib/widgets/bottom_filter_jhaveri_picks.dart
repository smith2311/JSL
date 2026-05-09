import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/secure_store.dart';

class BottomFilterJhaveriPicks extends StatefulWidget {
  final String apiBaseUrl;
  final Map<String, Set<String>> initialAppliedFilters;
  final String? title; // Optional custom title

  const BottomFilterJhaveriPicks({
    super.key,
    required this.apiBaseUrl,
    this.initialAppliedFilters = const {},
    this.title, // Add title parameter
  });

  @override
  State<BottomFilterJhaveriPicks> createState() =>
      _BottomFilterJhaveriPicksState();
}

class _BottomFilterJhaveriPicksState extends State<BottomFilterJhaveriPicks> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _selectedCategory;
  late Map<String, Set<String>> _localFilters;

  // Pagination state for each category
  Map<String, List<Map<String, dynamic>>> _categoryOptions = {};
  Map<String, int> _currentPages = {};
  Map<String, bool> _isLoadingMore = {};
  Map<String, bool> _hasMoreData = {};
  Map<String, ScrollController> _scrollControllers = {};

  List<Map<String, dynamic>> _filteredOptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  static const int _pageSize = 10;

  final List<String> _filterCategories = [
    "Fund House",
    "Fund Category",
    "Sub Category",
    "Risk Level",
    "Fund Size",
  ];

  @override
  void initState() {
    super.initState();
    _initFilters();
    _searchController.addListener(_onSearchChanged);

    // Initialize pagination state for all categories
    for (var category in _filterCategories) {
      _currentPages[category] = 1;
      _isLoadingMore[category] = false;
      _hasMoreData[category] = true;
      _scrollControllers[category] = ScrollController()
        ..addListener(() => _onScroll(category));
    }
  }

  // In bottom_filter_jhaveri_picks.dart
  void _initFilters() async {
    _localFilters = {};
    for (var category in _filterCategories) {
      _localFilters[category] = Set<String>.from(
        widget.initialAppliedFilters[category]?.map((e) => e.toString()) ?? {},
      );
    }

    // Don't load from SharedPreferences if we have initial filters
    // This ensures the bottom sheet always reflects current provider state
    if (widget.initialAppliedFilters.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        for (var category in _filterCategories) {
          final saved = prefs.getStringList('jhaveri_filter_$category') ?? [];
          if (saved.isNotEmpty) {
            _localFilters[category] = _localFilters[category]!.union(saved.toSet());
          }
        }
      } catch (_) {}
    }

    // Auto-select first category with filters
    for (var category in _filterCategories) {
      if (_localFilters[category]!.isNotEmpty) {
        _selectedCategory = category;
        _fetchOptionsForCategory(category);
        break;
      }
    }
  }

  void _onScroll(String category) {
    final controller = _scrollControllers[category];
    if (controller == null) return;

    if (controller.position.pixels >= controller.position.maxScrollExtent * 0.8) {
      if (!(_isLoadingMore[category] ?? false) && (_hasMoreData[category] ?? false)) {
        _loadMoreItems(category);
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterOptions(_searchController.text);
    });
  }

  Future<String> _getToken() async {
    final token = await SecureStore.getToken();
    if (token == null || token.isEmpty) throw Exception("Auth token not found");
    return token;
  }

  Future<void> _fetchOptionsForCategory(String category, {bool isInitial = true}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _searchController.clear();
        _errorMessage = null;
        _currentPages[category] = 1;
        _hasMoreData[category] = true;
      });
    }

    // If already loaded and not searching, just apply filters
    if (_categoryOptions.containsKey(category) &&
        _categoryOptions[category]!.isNotEmpty &&
        isInitial) {
      _applyFiltersToOptions(category);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final token = await _getToken();
      String url = '';
      switch (category) {
        case 'Fund House':
          url = '${widget.apiBaseUrl}/funds/amc';
          break;
        case 'Fund Category':
          url = '${widget.apiBaseUrl}/funds/category';
          break;
        case 'Sub Category':
          url = '${widget.apiBaseUrl}/funds/sub-category';
          break;
        case 'Risk Level':
          url = '${widget.apiBaseUrl}/funds/risk-level';
          break;
        case 'Fund Size':
          url = '${widget.apiBaseUrl}/funds/fund-size';
          break;
        default:
          _categoryOptions[category] = [];
          _filteredOptions = [];
          return;
      }

      final page = _currentPages[category] ?? 1;
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "page": page,
          "page_size": _pageSize,
          "search_term": "",
          "sort_order": "",
          "sort_by": ""
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dataList = (decoded['data']?['data_list'] as List<dynamic>?);

        final newItems = dataList
            ?.where((e) => e['id'] != null && e['name'] != null)
            .map((e) => {"id": e['id'].toString(), "name": e['name']})
            .toList() ?? [];

        setState(() {
          if (isInitial || page == 1) {
            _categoryOptions[category] = newItems;
          } else {
            _categoryOptions[category] = [
              ...(_categoryOptions[category] ?? []),
              ...newItems
            ];
          }

          // Check if there's more data
          if (newItems.length < _pageSize) {
            _hasMoreData[category] = false;
          }

          _isLoadingMore[category] = false;
        });

        _applyFiltersToOptions(category);

        if (_categoryOptions[category]!.isEmpty) {
          _errorMessage = "No options available";
        }

        debugPrint("✅ [Filter] Loaded ${newItems.length} items for $category. Total: ${_categoryOptions[category]!.length}");
      } else if (response.statusCode == 401) {
        _errorMessage = "Unauthorized. Please login again.";
      } else {
        _errorMessage = "Failed to fetch options. (${response.statusCode})";
      }
    } catch (e) {
      debugPrint("❌ [Filter] Error loading $category: $e");
      _errorMessage = "Error: $e";
      _categoryOptions[category] = [];
      _filteredOptions = [];
      setState(() => _isLoadingMore[category] = false);
    } finally {
      if (isInitial) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreItems(String category) async {
    if (_isLoadingMore[category]! || !_hasMoreData[category]!) return;

    setState(() {
      _isLoadingMore[category] = true;
      _currentPages[category] = (_currentPages[category] ?? 1) + 1;
    });

    debugPrint("📥 [Filter] Loading more for $category - Page: ${_currentPages[category]}");
    await _fetchOptionsForCategory(category, isInitial: false);
  }

  void _applyFiltersToOptions(String category) {
    final selected = _localFilters[category]!;
    _filteredOptions = _categoryOptions[category]!
        .map((opt) => {
      "id": opt['id'],
      "name": opt['name'],
      "checked": selected.contains(opt['id'])
    })
        .toList();
  }

  void _filterOptions(String query) {
    if (_selectedCategory == null) return;
    final selected = _localFilters[_selectedCategory!]!;
    final options = _categoryOptions[_selectedCategory!]!;
    _filteredOptions = options
        .where((o) => o['name'].toLowerCase().contains(query.toLowerCase()))
        .map((o) => {
      "id": o['id'],
      "name": o['name'],
      "checked": selected.contains(o['id'])
    })
        .toList();
    setState(() {});
  }

  void _toggleOption(String id, bool? value) {
    if (_selectedCategory == null) return;
    final selected = _localFilters[_selectedCategory!]!;
    setState(() {
      if (value == true) {
        selected.add(id);
      } else {
        selected.remove(id);
      }

      final index = _filteredOptions.indexWhere((o) => o['id'] == id);
      if (index != -1) _filteredOptions[index]['checked'] = value ?? false;

      _saveCategoryFilterToStorage(_selectedCategory!, selected);
    });
  }

  Future<void> _saveCategoryFilterToStorage(
      String category, Set<String> filters) async {
    final prefs = await SharedPreferences.getInstance();
    if (filters.isNotEmpty) {
      await prefs.setStringList('jhaveri_filter_$category', filters.toList());
    } else {
      await prefs.remove('jhaveri_filter_$category');
    }
  }

  Future<void> _clearFiltersFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    for (var category in _filterCategories) {
      await prefs.remove('jhaveri_filter_$category');
    }
  }

  void _clearAll() {
    setState(() {
      for (var category in _filterCategories) {
        _localFilters[category] = <String>{};
      }
      if (_selectedCategory != null) {
        _applyFiltersToOptions(_selectedCategory!);
      }
      _searchController.clear();
      _errorMessage = null;
    });

    _clearFiltersFromStorage();
  }

  void _applyAndClose() async {
    for (var category in _filterCategories) {
      await _saveCategoryFilterToStorage(category, _localFilters[category]!);
    }

    final filtersToReturn = <String, Set<String>>{};
    for (var category in _filterCategories) {
      final set = _localFilters[category] ?? <String>{};
      if (set.isNotEmpty) {
        filtersToReturn[category] = set;
      }
    }
    Navigator.pop(context, filtersToReturn);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.title ?? "Filter Jhaveri Picks", // Use custom title or default
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                // Left side category list
                Container(
                  width: 150,
                  color: const Color(0xFFF7F7F7),
                  child: ListView.builder(
                    itemCount: _filterCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filterCategories[index];
                      final isSelected = category == _selectedCategory;
                      final appliedCount = _localFilters[category]?.length ?? 0;

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              _searchController.clear();
                              setState(() => _selectedCategory = category);
                              await _fetchOptionsForCategory(category);
                            },
                            child: Container(
                              color: isSelected
                                  ? const Color(0xFFE3F3FE)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? const Color(0xFF0060A6)
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (appliedCount > 0)
                                    Text(
                                      "($appliedCount)",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF0060A6)
                                            : const Color(0xFF888898),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFD9D9D9)),
                        ],
                      );
                    },
                  ),
                ),
                Container(width: 1, color: const Color(0xFFD9D9D9)),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (_selectedCategory == null
                      ? const Center(child: Text("Select a category"))
                      : _errorMessage != null
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  )
                      : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Search...",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _filteredOptions.isEmpty
                            ? const Center(
                            child: Text("No matching results"))
                            : ListView.builder(
                          controller: _scrollControllers[_selectedCategory!],
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOptions.length +
                              ((_isLoadingMore[_selectedCategory!] ?? false) ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredOptions.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final option = _filteredOptions[index];
                            return CheckboxListTile(
                              controlAffinity:
                              ListTileControlAffinity.leading,
                              activeColor: const Color(0xFF0060A6),
                              title: Text(option['name'],
                                  style: const TextStyle(
                                      color: Color(0xFF444444))),
                              value: option['checked'] ?? false,
                              onChanged: (v) =>
                                  _toggleOption(option['id'], v),
                            );
                          },
                        ),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0060A6)),
                    onPressed: _clearAll,
                    child: const Text("Clear"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF0060A6),
                    ),
                    onPressed: _applyAndClose,
                    child: const Text("Apply"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}