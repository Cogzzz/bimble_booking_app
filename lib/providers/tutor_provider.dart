import 'package:flutter/material.dart';
import '../models/tutor_model.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

class TutorProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<TutorModel> _tutors = [];
  TutorModel? _selectedTutor;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedSubject;
  int? _minRate;
  int? _maxRate;

  // Getters
  List<TutorModel> get tutors => _tutors;
  List<TutorModel> get filteredTutors => _getFilteredTutors();
  TutorModel? get selectedTutor => _selectedTutor;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedSubject => _selectedSubject;
  int? get minRate => _minRate;
  int? get maxRate => _maxRate;

  // Load all tutors
  Future<void> loadTutors() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabaseService.client
          .from(AppConstants.tutorsTable)
          .select('''
            *,
            users!tutors_user_id_fkey(*)
          ''')
          .order('rating', ascending: false);

      _tutors = (response as List)
          .map((json) => TutorModel.fromJson(json))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Gagal memuat data tutor');
      _setLoading(false);
    }
  }

  // Get tutor by ID
  Future<void> getTutorById(String tutorId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabaseService.client
          .from(AppConstants.tutorsTable)
          .select('''
            *,
            users!tutors_user_id_fkey(*)
          ''')
          .eq('user_id', tutorId)
          .single();

      _selectedTutor = TutorModel.fromJson(response);
      _setLoading(false);
    } catch (e) {
      _setError('Gagal memuat detail tutor');
      _setLoading(false);
    }
  }

  // Search tutors
  void searchTutors(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  // Filter by subject
  void filterBySubject(String? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  // Filter by price range
  void filterByPriceRange(int? minRate, int? maxRate) {
    _minRate = minRate;
    _maxRate = maxRate;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedSubject = null;
    _minRate = null;
    _maxRate = null;
    notifyListeners();
  }

  // Get filtered tutors
  List<TutorModel> _getFilteredTutors() {
    List<TutorModel> filtered = List.from(_tutors);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tutor) {
        final name = tutor.name.toLowerCase();
        final subjects = tutor.subjects.toLowerCase();
        return name.contains(_searchQuery) || subjects.contains(_searchQuery);
      }).toList();
    }

    // Subject filter
    if (_selectedSubject != null && _selectedSubject!.isNotEmpty) {
      filtered = filtered.where((tutor) {
        return tutor.subjectsList.any(
          (subject) =>
              subject.toLowerCase().contains(_selectedSubject!.toLowerCase()),
        );
      }).toList();
    }

    // Price range filter
    if (_minRate != null) {
      filtered = filtered
          .where((tutor) => tutor.hourlyRate >= _minRate!)
          .toList();
    }
    if (_maxRate != null) {
      filtered = filtered
          .where((tutor) => tutor.hourlyRate <= _maxRate!)
          .toList();
    }

    return filtered;
  }

  // Get tutors by subject
  List<TutorModel> getTutorsBySubject(String subject) {
    return _tutors.where((tutor) {
      return tutor.subjectsList.any(
        (tutorSubject) =>
            tutorSubject.toLowerCase().contains(subject.toLowerCase()),
      );
    }).toList();
  }

  // Get top rated tutors
  List<TutorModel> getTopRatedTutors({int limit = 5}) {
    final sorted = List<TutorModel>.from(_tutors)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(limit).toList();
  }

  // Get popular tutors (by total sessions)
  List<TutorModel> getPopularTutors({int limit = 5}) {
    final sorted = List<TutorModel>.from(_tutors)
      ..sort((a, b) => b.totalSessions.compareTo(a.totalSessions));
    return sorted.take(limit).toList();
  }

  // Get available subjects
  List<String> getAvailableSubjects() {
    final Set<String> subjects = {};
    for (final tutor in _tutors) {
      subjects.addAll(tutor.subjectsList);
    }
    return subjects.toList()..sort();
  }

  // Update tutor profile (for tutor themselves)
  Future<bool> updateTutorProfile({
    required String userId,
    String? subjects,
    int? hourlyRate,
    int? experience,
    String? bio,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{};
      if (subjects != null) updateData['subjects'] = subjects;
      if (hourlyRate != null) updateData['hourly_rate'] = hourlyRate;
      if (experience != null) updateData['experience'] = experience;
      if (bio != null) updateData['bio'] = bio;

      await _supabaseService.client
          .from(AppConstants.tutorsTable)
          .update(updateData)
          .eq('user_id', userId);

      // Refresh tutor data
      await getTutorById(userId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Gagal memperbarui profil tutor');
      _setLoading(false);
      return false;
    }
  }

  // Create tutor profile (for new tutors)
  Future<bool> createTutorProfile({
    required String userId,
    required String subjects,
    required int hourlyRate,
    required int experience,
    required String bio,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Insert new tutor profile into tutors table
      final response = await _supabaseService.client
          .from(AppConstants.tutorsTable)
          .insert({
            'user_id': userId,
            'subjects': subjects,
            'hourly_rate': hourlyRate,
            'experience': experience,
            'bio': bio,
            'rating': 0.0,
            'total_sessions': 0,
          })
          .select('''
            *,
            users!tutors_user_id_fkey(*)
          ''')
          .single();

      // Create TutorModel from response and set as selected tutor
      _selectedTutor = TutorModel.fromJson(response);

      // Add the new tutor to the tutors list
      _tutors.add(_selectedTutor!);

      // Sort tutors by rating (highest first)
      _tutors.sort((a, b) => b.rating.compareTo(a.rating));

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(
        'Gagal membuat profil tutor: ${_supabaseService.handleError(e)}',
      );
      _setLoading(false);
      return false;
    }
  }

  // Check if user is already a tutor
  Future<bool> isTutor(String userId) async {
    try {
      _clearError();
      
      final response = await _supabaseService.client
          .from(AppConstants.tutorsTable)
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      _setError('Gagal memeriksa status tutor');
      return false;
    }
  }
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  void clearSelectedTutor() {
    _selectedTutor = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadTutors();
  }
}
