import 'package:flutter/material.dart';
import 'package:good_news/core/services/api_service.dart';
import 'package:good_news/core/services/preferences_service.dart';
import 'package:good_news/core/constants/theme_tokens.dart';
import 'package:good_news/responsive_app.dart';
import 'package:good_news/widgets/animated_category_chip.dart';

class ChooseTopicsScreen extends StatefulWidget {
  const ChooseTopicsScreen({Key? key}) : super(key: key);

  @override
  State<ChooseTopicsScreen> createState() => _ChooseTopicsScreenState();
}

class _ChooseTopicsScreenState extends State<ChooseTopicsScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const int minSelections = 3;

  // Fallback mock categories (जर API काम न करेल)
  static const List<Map<String, dynamic>> _mockCategories = [
    {'id': 1, 'name': 'Community'},
    {'id': 2, 'name': 'Technology'},
    {'id': 3, 'name': 'Health'},
    {'id': 4, 'name': 'Education'},
    {'id': 5, 'name': 'Environment'},
    {'id': 6, 'name': 'Sports'},
    {'id': 7, 'name': 'Entertainment'},
    {'id': 8, 'name': 'Business'},
    {'id': 9, 'name': 'Science'},
    {'id': 10, 'name': 'Politics'},
  ];

  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _filteredCategories = [];
  Set<int> _selectedCategories = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  void _initializeCategories() {
    // पहिले mock categories दाखवा
    setState(() {
      _allCategories = List<Map<String, dynamic>>.from(_mockCategories);
      _filteredCategories = List<Map<String, dynamic>>.from(_mockCategories);
    });

    // मग API वरून load करा
    _loadFromAPI();
  }

  Future<void> _loadFromAPI() async {
    setState(() => _isLoading = true);
    try {
      print('📡 Loading categories from API...');
      final response = await ApiService.getCategories();

      print('📊 API Response type: ${response.runtimeType}');

      List<Map<String, dynamic>> apiCategories = _parseCategories(response);

      // If we got valid categories from API, use them
      if (apiCategories.isNotEmpty) {
        print('✅ Using ${apiCategories.length} categories from API');
        setState(() {
          _allCategories = apiCategories;
          _filteredCategories = List<Map<String, dynamic>>.from(apiCategories);
          _errorMessage = null;
        });
      } else {
        print('⚠️ No valid categories from API, using mock categories');
        setState(() {
          _errorMessage = 'Using local categories. API data unavailable.';
        });
      }
    } catch (e) {
      print('❌ Failed to load categories from API: $e');
      setState(() {
        _errorMessage = 'Could not load from server, using local categories';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Parse categories from different API response formats
  List<Map<String, dynamic>> _parseCategories(dynamic response) {
    try {
      // Format 1: Response is direct List
      if (response is List) {
        print('✅ Response is List - parsing ${response.length} items');
        return response
            .whereType<Map<String, dynamic>>()
            .toList();
      }

      // Format 2: Response is Map with 'categories' or 'data'
      if (response is Map<String, dynamic>) {
        print('✅ Response is Map');

        // Try 'categories' key
        if (response.containsKey('categories')) {
          final cats = response['categories'];
          if (cats is List) {
            print('✅ Found categories key - parsing ${cats.length} items');
            return cats.whereType<Map<String, dynamic>>().toList();
          }
        }

        // Try 'data' key
        if (response.containsKey('data')) {
          final data = response['data'];
          if (data is List) {
            print('✅ Found data key - parsing ${data.length} items');
            return data.whereType<Map<String, dynamic>>().toList();
          }
        }
      }

      print('⚠️ Could not parse categories from response');
      return [];
    } catch (e) {
      print('❌ Error parsing categories: $e');
      return [];
    }
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = List<Map<String, dynamic>>.from(_allCategories);
      } else {
        _filteredCategories = _allCategories
            .where((category) => (category['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  Future<void> _savePreferences() async {
    if (_selectedCategories.length < minSelections) {
      _showErrorSnackBar('Please select at least $minSelections categories');
      return;
    }

    setState(() => _isSaving = true);
    try {
      print('💾 Saving ${_selectedCategories.length} selected categories...');

      // Save to local preferences
      await PreferencesService.saveSelectedCategories(_selectedCategories.toList());
      await PreferencesService.setOnboardingCompleted(true);
      print('✅ Saved to local preferences');

      // Also try to save to server if authenticated
      final token = await PreferencesService.getToken();
      if (token != null && token.isNotEmpty) {
        print('📤 Saving to server with token...');
        await ApiService.saveUserPreferencesAuth(_selectedCategories.toList(), token);
        print('✅ Saved to server');
      } else {
        print('⚠️ No token found, skipping server save');
      }

      _navigateToApp();
    } catch (e) {
      print('❌ Error saving preferences: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save preferences: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ResponsiveApp()),
    );
  }

  void _skipOnboarding() {
    // Save default empty categories list if skipping
    PreferencesService.saveSelectedCategories([]).then((_) {
      PreferencesService.setOnboardingCompleted(true).then((_) {
        _navigateToApp();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? ThemeTokens.darkBackground : Colors.white;
    final cardColor = isDark ? ThemeTokens.cardBackground : Colors.grey.shade100;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textPrimary, textSecondary),
            _buildSearchBar(cardColor, textPrimary, textSecondary),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ThemeTokens.spacingL, vertical: ThemeTokens.spacingS),
                child: Container(
                  padding: const EdgeInsets.all(ThemeTokens.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(ThemeTokens.radiusM),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Expanded(child: _buildCategoriesSection(textSecondary)),
            _buildBottomActions(textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.all(ThemeTokens.spacingL),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: ThemeTokens.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choose topics you care about',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: _skipOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeTokens.spacingM),
          Text(
            'Pick at least $minSelections categories so we show news you\'ll love.',
            style: TextStyle(color: textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color fillColor, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ThemeTokens.spacingL, vertical: ThemeTokens.spacingM),
      child: TextField(
        controller: _searchController,
        onChanged: _filterCategories,
        style: TextStyle(color: textPrimary),
        decoration: InputDecoration(
          hintText: 'Search topics...',
          hintStyle: TextStyle(color: textSecondary),
          prefixIcon: Icon(Icons.search, color: textSecondary),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ThemeTokens.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ThemeTokens.spacingM,
            vertical: ThemeTokens.spacingM,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(Color textSecondary) {
    if (_isLoading && _allCategories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ThemeTokens.primaryGreen),
      );
    }

    if (_filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: textSecondary),
            const SizedBox(height: ThemeTokens.spacingM),
            Text('No categories found', style: TextStyle(color: textSecondary)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(ThemeTokens.spacingL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: ThemeTokens.spacingM,
        mainAxisSpacing: ThemeTokens.spacingM,
      ),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        final id = category['id'] as int;
        final name = category['name'] as String?;
        final isSelected = _selectedCategories.contains(id);

        return AnimatedCategoryChip(
          label: name ?? 'Unknown',
          isSelected: isSelected,
          onTap: () => _toggleCategory(id),
        );
      },
    );
  }

  Widget _buildBottomActions(Color textSecondary) {
    final canContinue = _selectedCategories.length >= minSelections;

    return Container(
      padding: const EdgeInsets.all(ThemeTokens.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(
          top: BorderSide(color: ThemeTokens.border, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canContinue && !_isSaving ? _savePreferences : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeTokens.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: ThemeTokens.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ThemeTokens.radiusM),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                'Continue (${_selectedCategories.length}/$minSelections)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!canContinue) ...[
            const SizedBox(height: ThemeTokens.spacingS),
            Text(
              'Select at least $minSelections categories to continue',
              style: const TextStyle(color: ThemeTokens.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _skipOnboarding,
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}