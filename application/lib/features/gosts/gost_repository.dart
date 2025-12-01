import 'gost_models.dart';
import 'gost_database.dart';

class GostRepositoryImpl implements GostRepository {
  final GostLocalDataSource _localDataSource;

  GostRepositoryImpl() : _localDataSource = GostLocalDataSource();

  @override
  Future<List<GostSection>> getSections() async {
    return await _localDataSource.getSections();
  }

  @override
  Future<GostSection?> getSectionById(String id) async {
    final sections = await _localDataSource.getSections();
    try {
      return sections.firstWhere((section) => section.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<GostStandard>> getStandards() async {
    return await _localDataSource.getStandards();
  }

  @override
  Future<GostStandard?> getStandardById(String id) async {
    final standards = await _localDataSource.getStandards();
    try {
      return standards.firstWhere((standard) => standard.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<TermCategory>> getTermCategories() async {
    return await _localDataSource.getTermCategories();
  }

  @override
  Future<TermCategory?> getTermCategoryById(String id) async {
    final categories = await _localDataSource.getTermCategories();
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Term?> getTermById(String categoryId, String termId) async {
    final category = await getTermCategoryById(categoryId);
    if (category != null) {
      try {
        return category.terms.firstWhere((term) => term.id == termId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<List<GostStandard>> searchStandards(String query) async {
    if (query.isEmpty) return [];

    final standards = await _localDataSource.getStandards();
    return standards.where((standard) =>
      standard.id.toLowerCase().contains(query.toLowerCase()) ||
      standard.title.toLowerCase().contains(query.toLowerCase()) ||
      (standard.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  @override
  Future<List<Term>> searchTerms(String query) async {
    if (query.isEmpty) return [];

    final categories = await _localDataSource.getTermCategories();
    final allTerms = categories.expand((category) => category.terms).toList();

    return allTerms.where((term) =>
      term.name.toLowerCase().contains(query.toLowerCase()) ||
      term.definition.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  @override
  Future<String> getNoteContent(String noteId) async {
    return await _localDataSource.getNoteContent(noteId);
  }

  @override
  Future<String> getImageCaptionText(String imageId) async {
    return await _localDataSource.getImageCaptionText(imageId);
  }

  @override
  Future<String> getImageAssetPath(String imageId) async {
    return await _localDataSource.getImageAssetPath(imageId);
  }
}