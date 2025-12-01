class GostSection {
  final String id;
  final String title;
  final bool hasSubsections;
  final String? content;

  GostSection({
    required this.id,
    required this.title,
    required this.hasSubsections,
    this.content,
  });
}

class GostStandard {
  final String id;
  final String title;
  final String? description;

  GostStandard({
    required this.id,
    required this.title,
    this.description,
  });
}

class TermCategory {
  final String id;
  final String title;
  final List<Term> terms;

  TermCategory({
    required this.id,
    required this.title,
    required this.terms,
  });
}

class Term {
  final String id;
  final String categoryId;
  final String name;
  final String definition;
  final List<String> notes;

  Term({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.definition,
    required this.notes,
  });
}

class ContentImage {
  final String id;
  final String assetPath;
  final String caption;

  ContentImage({
    required this.id,
    required this.assetPath,
    required this.caption,
  });
}

class ContentItem {
  final String text;
  final bool isNote;
  final bool isImage;
  final String? noteId;
  final String? imageName;

  ContentItem({
    required this.text,
    this.isNote = false,
    this.isImage = false,
    this.noteId,
    this.imageName,
  });
}

class GostReference {
  final String fullText;
  final String gostId;
  final int start;
  final int end;

  GostReference({
    required this.fullText,
    required this.gostId,
    required this.start,
    required this.end,
  });
}

class TermReference {
  final Term term;
  final int start;
  final int end;
  final String originalText;

  TermReference({
    required this.term,
    required this.start,
    required this.end,
    required this.originalText,
  });
}

abstract class GostRepository {
  Future<List<GostSection>> getSections();
  Future<GostSection?> getSectionById(String id);
  Future<List<GostStandard>> getStandards();
  Future<GostStandard?> getStandardById(String id);
  Future<List<TermCategory>> getTermCategories();
  Future<TermCategory?> getTermCategoryById(String id);
  Future<Term?> getTermById(String categoryId, String termId);
  Future<List<GostStandard>> searchStandards(String query);
  Future<List<Term>> searchTerms(String query);
  Future<String> getNoteContent(String noteId);
  Future<String> getImageCaptionText(String imageId);
  Future<String> getImageAssetPath(String imageId);
}