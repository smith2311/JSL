import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/messages.dart';
import '../constants/strings.dart';
import '../core/token_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/jhaveri_picks_provider.dart';
import '../providers/sub_category_provider.dart';

class BottomFilterMF extends ConsumerStatefulWidget {
  final String apiBaseUrl;
  final Map<String, Set<String>> initialAppliedFilters;

  const BottomFilterMF({
    super.key,
    required this.apiBaseUrl,
    this.initialAppliedFilters = const {},
  });

  @override
  ConsumerState<BottomFilterMF> createState() => _BottomFilterMFState();
}

class _BottomFilterMFState extends ConsumerState<BottomFilterMF> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _optionsScrollController = ScrollController();
  Timer? _debounce;

  String? _selectedCategory;
  late Map<String, Set<String>> _localFilters;
  Map<String, List<Map<String, dynamic>>> _categoryOptions = {};
  List<Map<String, dynamic>> _filteredOptions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Pagination state
  Map<String, int> _currentPage = {};
  Map<String, bool> _hasMoreData = {};
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _initFilters();
    _searchController.addListener(_onSearchChanged);
    _optionsScrollController.addListener(_onOptionsScroll);
  }

  void _onOptionsScroll() {
    if (_selectedCategory == null || _isLoadingMore || _isLoading) return;

    if (_optionsScrollController.position.pixels >=
        _optionsScrollController.position.maxScrollExtent - 100) {
      final hasMore = _hasMoreData[_selectedCategory!] ?? false;
      if (hasMore) {
        _fetchMoreOptions();
      }
    }
  }

  void _initFilters() async {
    _localFilters = {};
    for (var category in AppStrings.filterCategories) {
      _localFilters[category] = Set<String>.from(
        widget.initialAppliedFilters[category]?.map((e) => e.toString()) ?? <String>{},
      );
      _currentPage[category] = 1;
      _hasMoreData[category] = true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      for (var category in AppStrings.filterCategories) {
        final saved = prefs.getStringList('filter_$category') ?? [];
        if (saved.isNotEmpty) {
          _localFilters[category] = _localFilters[category]!.union(saved.toSet());
        }
      }

      // Auto-select first category with filters
      for (var category in AppStrings.filterCategories) {
        if (_localFilters[category]!.isNotEmpty) {
          _selectedCategory = category;
          await _fetchOptionsForCategory(category);
          break;
        }
      }
    } catch (e) {
      debugPrint("❌ [BottomFilterMF] Error initializing filters: $e");
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Reset pagination on search
      if (_selectedCategory != null) {
        _currentPage[_selectedCategory!] = 1;
        _categoryOptions[_selectedCategory!] = [];
        _fetchOptionsForCategory(_selectedCategory!, isSearch: true);
      }
    });
  }

  Future<void> _fetchOptionsForCategory(String category, {bool isSearch = false}) async {
    setState(() {
      _isLoading = true;
      if (!isSearch) _searchController.clear();
      _errorMessage = null;
      _currentPage[category] = 1;
    });

    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        setState(() {
          _errorMessage = "Authentication required. Please login.";
          _isLoading = false;
        });
        return;
      }

      String url = _getUrlForCategory(category);
      if (url.isEmpty) {
        setState(() {
          _categoryOptions[category] = [];
          _filteredOptions = [];
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          "page": 1,
          "page_size": _pageSize,
          "search_term": _searchController.text,
          "sort_order": "",
          "sort_by": ""
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final dataList = (responseData['data']?['data_list'] as List<dynamic>?);
        final totalRecords = responseData['data']?['total_records'] ?? 0;

        final options = dataList
            ?.where((e) => e['id'] != null && e['name'] != null)
            .map((e) => {"id": e['id'].toString(), "name": e['name']})
            .toList() ?? [];

        _categoryOptions[category] = options;
        // Handle cases where API returns total_records as 0 but has data
        if (totalRecords == 0 && options.isNotEmpty) {
          _hasMoreData[category] = false;
        } else {
          _hasMoreData[category] = options.length < totalRecords;
        }
        _applyFiltersToOptions(category);

        if (options.isEmpty) {
          _errorMessage = ErrorMessages.no_options;
        }
      } else if (response.statusCode == 401) {
        _errorMessage = ErrorMessages.unauth_login;
        ref.read(authStateProvider.notifier).refreshAuthState();
      } else {
        _errorMessage = "Failed to fetch options. (${response.statusCode})";
      }
    } catch (e) {
      _errorMessage = "Error: $e";
      _categoryOptions[category] = [];
      _filteredOptions = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreOptions() async {
    if (_selectedCategory == null || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) return;

      final nextPage = (_currentPage[_selectedCategory!] ?? 1) + 1;
      String url = _getUrlForCategory(_selectedCategory!);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          "page": nextPage,
          "page_size": _pageSize,
          "search_term": _searchController.text,
          "sort_order": "",
          "sort_by": ""
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final dataList = (responseData['data']?['data_list'] as List<dynamic>?);
        final totalRecords = responseData['data']?['total_records'] ?? 0;

        final newOptions = dataList
            ?.where((e) => e['id'] != null && e['name'] != null)
            .map((e) => {"id": e['id'].toString(), "name": e['name']})
            .toList() ?? [];

        if (newOptions.isNotEmpty) {
          _categoryOptions[_selectedCategory!]!.addAll(newOptions);
          _currentPage[_selectedCategory!] = nextPage;

          final totalLoaded = _categoryOptions[_selectedCategory!]!.length;
          _hasMoreData[_selectedCategory!] = totalLoaded < totalRecords;

          _applyFiltersToOptions(_selectedCategory!);
        } else {
          _hasMoreData[_selectedCategory!] = false;
        }
      }
    } catch (e) {
      debugPrint("Error loading more options: $e");
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  String _getUrlForCategory(String category) {
    switch (category) {
      case 'Fund House':
        return '${widget.apiBaseUrl}/funds/amc';
      case 'Fund Category':
        return '${widget.apiBaseUrl}/funds/category';
      case 'Sub Category':
        return '${widget.apiBaseUrl}/funds/sub-category';
      case 'Risk Level':
        return '${widget.apiBaseUrl}/funds/risk-level';
      case 'Fund Size':
        return '${widget.apiBaseUrl}/funds/fund-size';
      default:
        return '';
    }
  }

  void _applyFiltersToOptions(String category) {
    final selected = _localFilters[category]!;
    _filteredOptions = _categoryOptions[category]!
        .map((opt) => {"id": opt['id'], "name": opt['name'], "checked": selected.contains(opt['id'])})
        .toList();
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

      // Save instantly
      _saveCategoryFilterToStorage(_selectedCategory!, selected);

      // Update provider live for Sub Category
      if (_selectedCategory == 'Sub Category') {
        final subCategoryIds =
        selected.map((e) => int.tryParse(e)).whereType<int>().toList();
        ref.read(selectedSubCategoriesProvider.notifier).state = subCategoryIds;
        ref.read(jhaveriPicksProvider.notifier).fetchFunds();
      }
    });
  }

  Future<void> _saveCategoryFilterToStorage(String category, Set<String> filters) async {
    final prefs = await SharedPreferences.getInstance();
    if (filters.isNotEmpty) {
      await prefs.setStringList('filter_$category', filters.toList());
    } else {
      await prefs.remove('filter_$category');
    }
  }

  Future<void> _saveFiltersToStorage() async {
    for (var category in AppStrings.filterCategories) {
      await _saveCategoryFilterToStorage(category, _localFilters[category]!);
    }
  }

  Future<void> _clearFiltersFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    for (var category in AppStrings.filterCategories) {
      await prefs.remove('filter_$category');
    }
  }

  void _clearAll() {
    setState(() {
      for (var category in AppStrings.filterCategories) {
        _localFilters[category] = <String>{};
        _currentPage[category] = 1;
        _hasMoreData[category] = true;
      }
      if (_selectedCategory != null) {
        _categoryOptions[_selectedCategory!] = [];
        _filteredOptions = [];
      }
      _selectedCategory = null;
      _searchController.clear();
      _errorMessage = null;
    });
    _clearFiltersFromStorage();
  }

  void _applyAndClose() {
    // Save filters to storage
    _saveFiltersToStorage();

    // Update Sub Category provider
    if (_localFilters.containsKey('Sub Category')) {
      final subCategoryIds = _localFilters['Sub Category']!.map((e) => int.tryParse(e)).whereType<int>().toList();
      ref.read(selectedSubCategoriesProvider.notifier).state = subCategoryIds;
    }

    // Trigger fund refresh
    ref.read(jhaveriPicksProvider.notifier).fetchFunds();

    // Return filters
    final filtersToReturn = <String, Set<String>>{};
    for (var category in AppStrings.filterCategories) {
      final set = _localFilters[category] ?? <String>{};
      if (set.isNotEmpty) filtersToReturn[category] = set;
    }
    Navigator.pop(context, filtersToReturn);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _optionsScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rightContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : (_selectedCategory == null
        ? const Center(child: Text(AppStrings.sel_categ))
        : _errorMessage != null
        ? Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      ),
    )
        : Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.searching_filter,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset(AppStrings.search, color: Colors.grey),
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: _filteredOptions.isEmpty
              ? const Center(child: Text(AppStrings.no_macth))
              : ListView.builder(
            controller: _optionsScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _filteredOptions.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _filteredOptions.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final option = _filteredOptions[index];
              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF0060A6),
                title: Text(option['name'], style: const TextStyle(color: Color(0xFF888898))),
                value: option['checked'] ?? false,
                onChanged: (v) => _toggleOption(option['id'], v),
              );
            },
          ),
        ),
      ],
    ));

    return WillPopScope(
      onWillPop: () async {
        // Return null to discard changes when dismissing
        Navigator.pop(context, null);
        return true;
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(AppStrings.filter_lbl, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  // Category list
                  Container(
                    width: 150,
                    color: const Color(0xFFF7F7F7),
                    child: ListView.builder(
                      itemCount: AppStrings.filterCategories.length,
                      itemBuilder: (context, index) {
                        final category = AppStrings.filterCategories[index];
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
                                color: isSelected ? const Color(0xFFE3F3FE) : Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          color: isSelected ? const Color(0xFF0060A6) : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (appliedCount > 0)
                                      Text(
                                        "($appliedCount)",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected ? const Color(0xFF0060A6) : const Color(0xFF888898),
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
                  Expanded(child: rightContent),
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
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0060A6)),
                      onPressed: _clearAll,
                      child: const Text(AppStrings.clear_filters),
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
                      child: const Text(AppStrings.add_filters),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}