import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Home/widget/special_offers_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'banners_carousel.dart';
import 'categories_grid.dart';
import 'category_section_widget.dart';
import 'home_search_bar.dart';


class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  late final CollectionReference _categoriesRef;
  late final CollectionReference _productsRef;
  late final CollectionReference _bannersRef;

  String? _selectedCategoryId;
  final String? _selectedSubcategoryId = null;
  final RangeValues _priceRange = const RangeValues(0, 10000);

  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _categoriesRef = _firestore.collection('categories');
    _productsRef = _firestore.collection('products');
    _bannersRef = _firestore.collection('banners');

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    _searchNotifier.value = query;

    if (_searchDebounceTimer?.isActive ?? false) _searchDebounceTimer!.cancel();

    if (query.isNotEmpty && query.length >= 2) {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
        _saveSearchToFirebase(query);
      });
    }
  }

  Future<void> _saveSearchToFirebase(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || cleanQuery.length < 2) return;

    final user = _auth.currentUser;
    try {
      if (user == null) {
        await _firestore.collection('search_history').add({
          'query': cleanQuery,
          'createdAt': FieldValue.serverTimestamp(),
          'userID': 'Gust',
          'gust': true,
        });
        return;
      }

      await _firestore
          .collection('user')
          .doc(user.uid)
          .collection('search_history')
          .add({
        'query': cleanQuery,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('search_history').add({
        'query': cleanQuery,
        'createdAt': FieldValue.serverTimestamp(),
        'userID': user.uid,
        'gust': false,
      });
    } catch (e) {
      debugPrint("Error saving search history: $e");
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String lang = Get.locale?.languageCode ?? "ar";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: _searchNotifier,
          builder: (context, searchQuery, _) {
            final bool isSearching = searchQuery.isNotEmpty;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeSearchBar(
                    controller: _searchController,
                    searchNotifier: _searchNotifier,
                    onSubmitted: _saveSearchToFirebase,
                  ),
                ),
                if (!isSearching) ...[
                  SliverToBoxAdapter(
                    child: BannersCarousel(bannersRef: _bannersRef),
                  ),
                  SliverToBoxAdapter(
                    child: SpecialOffersSection(productsRef: _productsRef),
                  ),
                ],
                StreamBuilder<QuerySnapshot>(
                  stream: _categoriesRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                      );
                    }

                    final allCategories = snapshot.data!.docs;

                    final filteredCategories = _selectedCategoryId != null
                        ? allCategories
                        .where((doc) => doc.id == _selectedCategoryId)
                        .toList()
                        : allCategories;

                    return SliverMainAxisGroup(
                      slivers: [
                        if (!isSearching)
                          SliverToBoxAdapter(
                            child: CategoriesGrid(
                              categories: allCategories,
                              selectedCategoryId: _selectedCategoryId,
                              onSelectCategory: (catId) {
                                setState(() => _selectedCategoryId = catId);
                              },
                            ),
                          ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final categoryDoc = filteredCategories[index];
                              final data =
                              categoryDoc.data() as Map<String, dynamic>;
                              final String categoryTitle = lang == "en"
                                  ? (data['nameEn'] ?? '')
                                  : (data['nameAr'] ?? '');

                              return Center(
                                child: Container(
                                  constraints:
                                  const BoxConstraints(maxWidth: 1300),
                                  child: CategorySectionWidget(
                                    productsRef: _productsRef,
                                    categoryId: categoryDoc.id,
                                    categoryTitle: categoryTitle,
                                    selectedSubcategoryId:
                                    _selectedSubcategoryId,
                                    priceRange: _priceRange,
                                    searchQueryNotifier: _searchNotifier,
                                  ),
                                ),
                              );
                            },
                            childCount: filteredCategories.length,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}