// pages/student/search_tutor_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tutor_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/cards/tutor_card.dart';
import '../shared/profile_detail_page.dart';
import 'booking_page.dart';

class SearchTutorPage extends StatefulWidget {
  const SearchTutorPage({Key? key}) : super(key: key);

  @override
  State<SearchTutorPage> createState() => _SearchTutorPageState();
}

class _SearchTutorPageState extends State<SearchTutorPage> {
  final _searchController = TextEditingController();
  bool _showFilters = false;
  
  @override
  void initState() {
    super.initState();
    _loadTutors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTutors() {
    Provider.of<TutorProvider>(context, listen: false).loadTutors();
  }

  void _navigateToTutorDetail(tutor) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileDetailPage(
          user: tutor.user!,
          tutor: tutor,
          showBookingButton: true,
        ),
      ),
    );

    if (result == 'book') {
      _navigateToBooking(tutor);
    }
  }

  void _navigateToBooking(tutor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingPage(tutor: tutor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cari Tutor'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Cari tutor atau mata pelajaran...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                Provider.of<TutorProvider>(context, listen: false)
                    .searchTutors(value);
              },
            ),
          ),

          // Filters
          if (_showFilters) _buildFilters(),

          // Tutors List
          Expanded(
            child: Consumer<TutorProvider>(
              builder: (context, tutorProvider, child) {
                if (tutorProvider.isLoading) {
                  return const LoadingWidget();
                }

                final tutors = tutorProvider.filteredTutors;

                if (tutors.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadTutors(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: tutors.length,
                    itemBuilder: (context, index) {
                      final tutor = tutors[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: TutorCard(
                          tutor: tutor,
                          onTap: () => _navigateToTutorDetail(tutor),
                          onBookTap: () => _navigateToBooking(tutor),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Pencarian',
            style: AppTextStyles.labelLarge,
          ),
          SizedBox(height: 12),
          
          // Subject Filter
          Consumer<TutorProvider>(
            builder: (context, tutorProvider, child) {
              final subjects = tutorProvider.getAvailableSubjects();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mata Pelajaran',
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // All subjects chip
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('Semua'),
                            selected: tutorProvider.selectedSubject == null,
                            onSelected: (selected) {
                              tutorProvider.filterBySubject(null);
                            },
                          ),
                        ),
                        // Subject chips
                        ...subjects.map((subject) => Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(subject),
                            selected: tutorProvider.selectedSubject == subject,
                            onSelected: (selected) {
                              tutorProvider.filterBySubject(selected ? subject : null);
                            },
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          SizedBox(height: 16),
          
          // Price Range Filter
          Consumer<TutorProvider>(
            builder: (context, tutorProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rentang Harga',
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: tutorProvider.minRate,
                              hint: Text('Min Harga'),
                              isExpanded: true,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              items: [
                                DropdownMenuItem(value: null, child: Text('Tidak ada')),
                                DropdownMenuItem(value: 25000, child: Text('Rp 25.000')),
                                DropdownMenuItem(value: 50000, child: Text('Rp 50.000')),
                                DropdownMenuItem(value: 75000, child: Text('Rp 75.000')),
                                DropdownMenuItem(value: 100000, child: Text('Rp 100.000')),
                              ],
                              onChanged: (value) {
                                tutorProvider.filterByPriceRange(value, tutorProvider.maxRate);
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: tutorProvider.maxRate,
                              hint: Text('Max Harga'),
                              isExpanded: true,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              items: [
                                DropdownMenuItem(value: null, child: Text('Tidak ada')),
                                DropdownMenuItem(value: 75000, child: Text('Rp 75.000')),
                                DropdownMenuItem(value: 100000, child: Text('Rp 100.000')),
                                DropdownMenuItem(value: 150000, child: Text('Rp 150.000')),
                                DropdownMenuItem(value: 200000, child: Text('Rp 200.000')),
                              ],
                              onChanged: (value) {
                                tutorProvider.filterByPriceRange(tutorProvider.minRate, value);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          
          SizedBox(height: 16),
          
          // Clear Filters Button
          Consumer<TutorProvider>(
            builder: (context, tutorProvider, child) {
              final hasFilters = tutorProvider.selectedSubject != null ||
                                tutorProvider.minRate != null ||
                                tutorProvider.maxRate != null ||
                                tutorProvider.searchQuery.isNotEmpty;
              
              if (!hasFilters) return SizedBox.shrink();
              
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    tutorProvider.clearFilters();
                    _searchController.clear();
                  },
                  child: Text('Hapus Filter'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Consumer<TutorProvider>(
      builder: (context, tutorProvider, child) {
        final hasSearch = tutorProvider.searchQuery.isNotEmpty;
        final hasFilters = tutorProvider.selectedSubject != null ||
                          tutorProvider.minRate != null ||
                          tutorProvider.maxRate != null;
        
        return Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasSearch || hasFilters ? Icons.search_off : Icons.school_outlined,
                  size: 64,
                  color: AppColors.textHint,
                ),
                SizedBox(height: 16),
                Text(
                  hasSearch || hasFilters 
                      ? 'Tidak ada tutor yang sesuai'
                      : 'Belum ada tutor terdaftar',
                  style: AppTextStyles.h6.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  hasSearch || hasFilters
                      ? 'Coba ubah kata kunci atau filter pencarian'
                      : 'Tutor akan muncul di sini ketika sudah mendaftar',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasSearch || hasFilters) ...[
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      tutorProvider.clearFilters();
                      _searchController.clear();
                    },
                    child: Text('Hapus Filter'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}