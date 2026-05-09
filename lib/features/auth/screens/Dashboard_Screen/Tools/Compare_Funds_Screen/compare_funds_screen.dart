import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../../providers/discover_most_pop_funds_provider.dart';
import '../../../../../../widgets/nfo_fund_card.dart';
import '../../../../../funds/data/models/popular_fund.dart';

class CompareFundsScreen extends ConsumerStatefulWidget {
  const CompareFundsScreen({super.key});

  @override
  ConsumerState<CompareFundsScreen> createState() =>
      _CompareFundsScreenState();
}

class _CompareFundsScreenState extends ConsumerState<CompareFundsScreen> {
  final TextEditingController _fund1Controller = TextEditingController();
  final TextEditingController _fund2Controller = TextEditingController();

  final FocusNode _fund1FocusNode = FocusNode();
  final FocusNode _fund2FocusNode = FocusNode();

  String? _selectedFund1Id;
  String? _selectedFund2Id;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;

  List<PopularFund> _fundList = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fund1FocusNode.addListener(() => setState(() {}));
    _fund2FocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fund1Controller.dispose();
    _fund2Controller.dispose();
    _fund1FocusNode.dispose();
    _fund2FocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchFunds({String query = '', bool append = false}) async {
    if (query.isEmpty) return;

    final repo = ref.read(popularFundRepoProvider);
    try {
      if (!append) {
        setState(() => _isLoading = true);
      }

      final newFunds = await repo.fetchPopularFunds(
        page: _currentPage,
        pageSize: 10,
        searchTerm: query,
      );

      if (mounted) {
        setState(() {
          if (append) {
            _fundList.addAll(newFunds);
          } else {
            _fundList = newFunds;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching funds: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading &&
        _searchQuery.isNotEmpty) {
      _loadMoreFunds();
    }
  }

  Future<void> _loadMoreFunds() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    await _fetchFunds(query: _searchQuery, append: true);

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onFundSelected(PopularFund fund) {
    setState(() {
      if (_selectedFund1Id == null) {
        _selectedFund1Id = fund.fundId.toString();
        _fund1Controller.text = fund.fundName;
        _fund1FocusNode.unfocus();
        // Move focus to Fund 2
        Future.delayed(const Duration(milliseconds: 100), () {
          _fund2FocusNode.requestFocus();
        });
      } else if (_selectedFund2Id == null) {
        _selectedFund2Id = fund.fundId.toString();
        _fund2Controller.text = fund.fundName;
        _fund2FocusNode.unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You can select only 2 funds for comparison')),
        );
      }
    });
  }

  void _onCompare() {
    if (_selectedFund1Id != null && _selectedFund2Id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompareResultScreen(
            fund1Id: _selectedFund1Id!,
            fund2Id: _selectedFund2Id!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select 2 funds to compare.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonEnabled =
        _selectedFund1Id != null && _selectedFund2Id != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare_Funds_Screen',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFloatingFundBox(
                  label: 'Fund 1',
                  controller: _fund1Controller,
                  focusNode: _fund1FocusNode,
                  selected: _selectedFund1Id != null,
                  onClear: () {
                    setState(() {
                      _fund1Controller.clear();
                      _selectedFund1Id = null;
                      _fundList = [];
                    });
                  },
                  isTopBox: true,
                ),
                const SizedBox(height: 4),
                _buildFloatingFundBox(
                  label: 'Fund 2',
                  controller: _fund2Controller,
                  focusNode: _fund2FocusNode,
                  selected: _selectedFund2Id != null,
                  onClear: () {
                    setState(() {
                      _fund2Controller.clear();
                      _selectedFund2Id = null;
                      _fundList = [];
                    });
                  },
                  isTopBox: false,
                ),
              ],
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? const Center(
                child: Text('Search for a fund to compare',
                    style: TextStyle(color: Colors.grey, fontSize: 16)))
                : _isLoading
                ? _buildShimmerList()
                : _fundList.isEmpty
                ? const Center(
                child: Text('No funds found for your search.',
                    style:
                    TextStyle(color: Colors.grey, fontSize: 16)))
                : RefreshIndicator(
              onRefresh: () async {
                _currentPage = 1;
                await _fetchFunds(query: _searchQuery);
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _fundList.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _fundList.length) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  }
                  final fund = _fundList[index];
                  return GestureDetector(
                    onTap: () => _onFundSelected(fund),
                    child: NfoFundCard(
                      fundName: fund.fundName,
                      productTitle:
                      '${fund.fundType} - ${fund.fundSubType}',
                      threeYearReturnValue:
                      fund.threeYearReturn,
                      logoPath: AppStrings.iconFunds_png,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: buttonEnabled ? _onCompare : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonEnabled
                    ? const Color(0xFF0060A6)
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Compare',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingFundBox({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool selected,
    required VoidCallback onClear,
    required bool isTopBox,
  }) {
    final bool isFocused = focusNode.hasFocus;
    final bool hasText = controller.text.isNotEmpty;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isTopBox
            ? const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        )
            : const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: (isFocused || hasText) ? 6 : 22,
            left: 60,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: (isFocused || hasText)
                    ? const Color(0xFF0060A6)
                    : Colors.grey,
                fontSize: (isFocused || hasText) ? 12 : 16,
                fontWeight: FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
          Row(
            children: [
              Container(margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F3FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(AppStrings.money,
                    width: 32, height: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: selected,
                  enableInteractiveSelection: !selected,
                  showCursor: !selected,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _currentPage = 1;
                      _fundList = [];
                    });
                    _fetchFunds(query: val);
                  },
                  style:
                  const TextStyle(fontSize: 15, color: Colors.black),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 28),
                  ),
                ),
              ),
              if (selected)
                GestureDetector(
                  onTap: () {
                    onClear();
                    focusNode.requestFocus();
                  },
                  child:
                  const Icon(Icons.edit_outlined, color: Color(0xFF0060A6), size: 22),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompareResultScreen extends StatelessWidget {
  final String fund1Id;
  final String fund2Id;

  const CompareResultScreen({
    super.key,
    required this.fund1Id,
    required this.fund2Id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparison Result')),
      body: Center(
        child: Text(
          'Fund 1 ID: $fund1Id\nFund 2 ID: $fund2Id',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}