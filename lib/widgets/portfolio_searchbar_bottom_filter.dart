import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/strings.dart';
import '../core/token_helper.dart';
import '../core/config/env.dart';

class PortfolioBottomFilter extends StatefulWidget {
  final String? selectedSortBy;
  final String? selectedSortOrder;
  final List<String> selectedAmcs;
  final List<String> selectedFundCategory;
  final List<String> selectedSubCategory;
  final int currentTab;
  final int currentSubTab;

  const PortfolioBottomFilter({
    super.key,
    this.selectedSortBy,
    this.selectedSortOrder,
    this.selectedAmcs = const [],
    this.selectedFundCategory = const [],
    this.selectedSubCategory = const [],
    this.currentTab = 0,
    this.currentSubTab = 0,
  });

  @override
  State<PortfolioBottomFilter> createState() => _PortfolioBottomFilterState();
}

class _PortfolioBottomFilterState extends State<PortfolioBottomFilter> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _optionsScrollController = ScrollController();
  Timer? _debounce;

  String? _selectedCategory;
  String? _selectedSortBy;
  String? _selectedSortOrder;

  Map<String, Set<String>> _localFilters = {};
  Map<String, List<Map<String, dynamic>>> _categoryOptions = {};
  List<Map<String, dynamic>> _filteredOptions = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  Map<String, int> _currentPage = {};
  Map<String, bool> _hasMoreData = {};
  final int _pageSize = 10;

  List<Map<String, dynamic>> _getSortOptions() {
    switch (widget.currentTab) {
      case 2:
        return AppStrings.ordersSortOptions;
      case 1:
        return AppStrings.getSipSwpStpSortOptions(widget.currentSubTab);
      default:
        return AppStrings.filter_sortOptions;
    }
  }

  @override
  void initState() {
    super.initState();
    _initFilters();
    _searchController.addListener(_onSearchChanged);
    _optionsScrollController.addListener(_onOptionsScroll);
  }

  void _initFilters() {
    _selectedSortBy = widget.selectedSortBy;
    _selectedSortOrder = widget.selectedSortOrder;

    _localFilters = {
      'Fund House': Set<String>.from(widget.selectedAmcs),
      'Fund Category': Set<String>.from(widget.selectedFundCategory),
      'Sub Category': Set<String>.from(widget.selectedSubCategory),
    };

    for (var category in AppStrings.filter_categories) {
      _currentPage[category] = 1;
      _hasMoreData[category] = true;
    }

    _selectedCategory = 'Sort';
    _buildSortOptions();
  }

  void _onOptionsScroll() {
    if (_selectedCategory == null ||
        _selectedCategory == 'Sort' ||
        _isLoadingMore ||
        _isLoading) return;

    if (_optionsScrollController.position.pixels >=
        _optionsScrollController.position.maxScrollExtent - 100) {
      final hasMore = _hasMoreData[_selectedCategory!] ?? false;
      if (hasMore) {
        _fetchMoreOptions();
      }
    }
  }

  void _onSearchChanged() {
    if (_selectedCategory == 'Sort') return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_selectedCategory != null) {
        _currentPage[_selectedCategory!] = 1;
        _categoryOptions[_selectedCategory!] = [];
        _fetchOptionsForCategory(_selectedCategory!, isSearch: true);
      }
    });
  }

  void _buildSortOptions() {
    final sortOptions = _getSortOptions();
    _filteredOptions = sortOptions
        .map((opt) => {
      'id': opt['id']!,
      'name': opt['name']!,
      'icon': opt['icon']!,
      'checked': _selectedSortBy == opt['id'],
    })
        .toList();
  }

  Future<void> _fetchOptionsForCategory(String category,
      {bool isSearch = false}) async {
    if (category == 'Sort') {
      _buildSortOptions();
      return;
    }

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
          _errorMessage = "Authentication required.";
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
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
            .toList() ??
            [];

        _categoryOptions[category] = options;
        _hasMoreData[category] = options.length < totalRecords;
        _applyFiltersToOptions(category);

        if (options.isEmpty) {
          _errorMessage = "No options available";
        }
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
      if (token == null || _selectedCategory == null) return;

      final currentCategory = _selectedCategory!;
      final nextPage = (_currentPage[currentCategory] ?? 1) + 1;
      final url = _getUrlForCategory(currentCategory);

      if (url.isEmpty) return;

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "page": nextPage,
          "page_size": _pageSize,
          "search_term": _searchController.text.trim(),
          "sort_order": "",
          "sort_by": "",
        }),
      );

      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? {};
      final dataList = (data['data_list'] as List<dynamic>?) ?? [];
      final totalRecords = data['total_records'] ?? 0;

      if (dataList.isEmpty) {
        _hasMoreData[currentCategory] = false;
        return;
      }

      final newOptions = dataList
          .whereType<Map<String, dynamic>>()
          .where((e) => e['id'] != null && e['name'] != null)
          .map((e) => {
        "id": e['id'].toString(),
        "name": e['name'] as String,
      })
          .toList();

      if (newOptions.isEmpty) {
        _hasMoreData[currentCategory] = false;
        return;
      }

      _categoryOptions[currentCategory]?.addAll(newOptions);
      _currentPage[currentCategory] = nextPage;

      final totalLoaded = _categoryOptions[currentCategory]?.length ?? 0;
      _hasMoreData[currentCategory] = totalLoaded < totalRecords;

      _applyFiltersToOptions(currentCategory);
    } catch (e) {
      debugPrint("Error fetching category data: $e");
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  String _getUrlForCategory(String category) {
    switch (category) {
      case 'Fund House':
        return '${EnvConfig.apiBaseUrl}/funds/amc';
      case 'Fund Category':
        return '${EnvConfig.apiBaseUrl}/funds/category';
      case 'Sub Category':
        return '${EnvConfig.apiBaseUrl}/funds/sub-category';
      default:
        return '';
    }
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

  void _toggleOption(String id, bool? value) {
    if (_selectedCategory == null) return;

    if (_selectedCategory == 'Sort') {
      setState(() {
        if (_selectedSortBy == id) {
          if (_selectedSortOrder == 'asc') {
            _selectedSortOrder = 'desc';
          } else if (_selectedSortOrder == 'desc') {
            _selectedSortBy = null;
            _selectedSortOrder = null;
          }
        } else {
          _selectedSortBy = id;
          _selectedSortOrder = 'asc';
        }
        _buildSortOptions();
      });
    } else {
      final selected = _localFilters[_selectedCategory!]!;
      setState(() {
        if (value == true) {
          selected.add(id);
        } else {
          selected.remove(id);
        }

        final index = _filteredOptions.indexWhere((o) => o['id'] == id);
        if (index != -1) _filteredOptions[index]['checked'] = value ?? false;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _selectedSortBy = null;
      _selectedSortOrder = null;

      for (var category in AppStrings.filter_categories) {
        if (_localFilters.containsKey(category)) {
          _localFilters[category] = <String>{};
        }
        _currentPage[category] = 1;
        _hasMoreData[category] = true;
      }

      if (_selectedCategory != null) {
        if (_selectedCategory == 'Sort') {
          _buildSortOptions();
        } else {
          _categoryOptions[_selectedCategory!] = [];
          _filteredOptions = [];
        }
      }

      _selectedCategory = 'Sort';
      _buildSortOptions();
      _searchController.clear();
      _errorMessage = null;
    });

    _applyAndClose();
  }

  void _applyAndClose() {
    Navigator.pop(context, {
      'sortBy': _selectedSortBy ?? '',
      'sortOrder': _selectedSortOrder ?? '',
      'amcs': _localFilters['Fund House']?.toList() ?? [],
      'fundCategory': _localFilters['Fund Category']?.toList() ?? [],
      'subCategory': _localFilters['Sub Category']?.toList() ?? [],
    });
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
        ? const Center(child: Text('Select a category'))
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
        if (_selectedCategory != 'Sort')
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        Expanded(
          child: _filteredOptions.isEmpty
              ? const Center(child: Text('No options available'))
              : ListView.builder(
            controller: _optionsScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _filteredOptions.length +
                (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _filteredOptions.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: CircularProgressIndicator()),
                );
              }

              final option = _filteredOptions[index];

              if (_selectedCategory == 'Sort') {
                return _buildSortItem(option);
              }

              // ✅ Custom checkbox item with border colors
              return _buildCheckboxItem(option);
            },
          ),
        ),
      ],
    ));

    return Container(
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
            child: Text('Filter & Sort',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 150,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: AppStrings.filter_categories.length,
                    itemBuilder: (context, index) {
                      final category = AppStrings.filter_categories[index];
                      final isSelected = category == _selectedCategory;

                      int appliedCount = 0;
                      if (category == 'Sort') {
                        appliedCount = (_selectedSortBy != null &&
                            _selectedSortBy!.isNotEmpty)
                            ? 1
                            : 0;
                      } else {
                        appliedCount = _localFilters[category]?.length ?? 0;
                      }

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              _searchController.clear();
                              setState(() => _selectedCategory = category);
                              await _fetchOptionsForCategory(category);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE3F3FE)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0060A6)
                                      : const Color(0xFFEAEBED),
                                  width: 1,
                                ),
                              ),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (appliedCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        "($appliedCount)",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF0060A6)
                                              : const Color(0xFF888898),
                                        ),
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
                    style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0060A6)),
                    onPressed: _clearAll,
                    child: const Text('Clear All'),
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
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Custom checkbox item with proper border colors
  Widget _buildCheckboxItem(Map<String, dynamic> option) {
    final isChecked = option['checked'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isChecked ? const Color(0xFF0060A6) : const Color(0xFFEAEBED),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF0060A6),
        title: Text(
          option['name'],
          style: TextStyle(
            color: isChecked ? Colors.black : const Color(0xFF888898),
            fontWeight: isChecked ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        value: isChecked,
        onChanged: (v) => _toggleOption(option['id'], v),
      ),
    );
  }

  Widget _buildSortItem(Map<String, dynamic> option) {
    final isSelected = _selectedSortBy == option['id'];
    String? sortIndicator;

    if (isSelected) {
      if (_selectedSortOrder == 'asc') {
        sortIndicator = '↑';
      } else if (_selectedSortOrder == 'desc') {
        sortIndicator = '↓';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF0060A6) : const Color(0xFFEAEBED),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0,vertical: -4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        horizontalTitleGap: 5, // ✅ Reduce space between icon and text
        leading: Icon(
          option['icon'] as IconData,
          color: isSelected ? const Color(0xFF0060A6) : const Color(0xFF888898),
          size: 22, // ✅ Slightly smaller icon
        ),
        title: Text(
          option['name'],
          style: TextStyle(
            color: isSelected ? const Color(0xFF0060A6) : const Color(0xFF888898),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15, // ✅ Slightly smaller font for better fit
          ),
          maxLines: 1,
          overflow: TextOverflow.visible, // ✅ Show full text
        ),
        trailing: sortIndicator != null
            ? Padding(
          padding: const EdgeInsets.only(left: 4), // ✅ Small gap before arrow
          child: Text(
            sortIndicator,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF0060A6),
              fontWeight: FontWeight.bold,
            ),
          ),
        )
            : null,
        onTap: () => _toggleOption(option['id'], !isSelected),
      ),
    );
  }
}