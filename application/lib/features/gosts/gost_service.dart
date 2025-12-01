import 'gost_models.dart';
import 'gost_repository.dart';

class GostService {
  final GostRepository _repository;

  GostService._internal(this._repository);
  static final GostService _instance = GostService._internal(GostRepositoryImpl());
  factory GostService() => _instance;

  Future<List<GostSection>> getSections() async {
    return await _repository.getSections();
  }

  Future<GostSection?> getSection(String id) async {
    return await _repository.getSectionById(id);
  }

  Future<List<GostStandard>> getStandards() async {
    return await _repository.getStandards();
  }

  Future<GostStandard?> getStandard(String id) async {
    return await _repository.getStandardById(id);
  }

  Future<List<TermCategory>> getTermCategories() async {
    return await _repository.getTermCategories();
  }

  Future<TermCategory?> getTermCategory(String id) async {
    return await _repository.getTermCategoryById(id);
  }

  Future<List<Term>> searchAllTerms(String query) async {
    if (query.isEmpty) return [];
    return await _repository.searchTerms(query);
  }

  Future<String> getNoteContent(String noteId) async {
    return await _repository.getNoteContent(noteId);
  }

  Future<String> getImageCaption(String imageName) async {
    return await _repository.getImageCaptionText(imageName);
  }

  Future<String> getImageAssetPath(String imageName) async {
    return await _repository.getImageAssetPath(imageName);
  }

  List<ContentItem> parseSectionContent(String content) {
    final List<ContentItem> items = [];
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.contains('[NOTE:')) {
        final noteMatch = RegExp(r'\[NOTE:(\w+)\]').firstMatch(line);
        final noteId = noteMatch?.group(1);
        final cleanText = line.replaceAll(RegExp(r'\[NOTE:\w+\]'), '').trim();

        items.add(ContentItem(
          text: cleanText.isNotEmpty ? cleanText : 'Смотри примечание ниже',
          isNote: true,
          noteId: noteId,
        ));
      } else if (line.contains('[IMAGE:')) {
        final imageMatch = RegExp(r'\[IMAGE:(\w+)\]').firstMatch(line);
        final imageName = imageMatch?.group(1);

        if (imageName != null) {
          items.add(ContentItem(
            text: '',
            isImage: true,
            imageName: imageName,
          ));
        }

        final cleanText = line.replaceAll(RegExp(r'\[IMAGE:\w+\]'), '').trim();
        if (cleanText.isNotEmpty) {
          items.add(ContentItem(text: cleanText));
        }
      } else {
        items.add(ContentItem(text: line.trim()));
      }
    }

    return items;
  }

  List<GostReference> findGostReferences(String text) {
    final List<GostReference> references = [];
    final pattern = RegExp(r'ГОСТ\s+([Р]?\s*\d+\.\d+(?:-\d{4})?)', caseSensitive: false);
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      references.add(GostReference(
        fullText: match.group(0)!,
        gostId: match.group(1)!,
        start: match.start,
        end: match.end,
      ));
    }

    return references;
  }

  bool _isLetterChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
           (code >= 97 && code <= 122) ||
           (code >= 1040 && code <= 1103) ||
           code == 1025 || code == 1105;
  }

  bool _isRussianChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 1040 && code <= 1103) || code == 1025 || code == 1105;
  }

  List<TermReference> findTermReferences(String text, List<Term> allTerms) {
    final List<TermReference> references = [];
    final textLower = text.toLowerCase();

    for (final term in allTerms) {
      final termName = term.name.toLowerCase().trim();
      if (termName.length < 3) continue;

      int startIndex = 0;
      while (true) {
        final index = textLower.indexOf(termName, startIndex);
        if (index == -1) break;

        int endIndex = index + termName.length;
        while (endIndex < textLower.length &&
               _isRussianChar(textLower[endIndex]) &&
               endIndex - index < termName.length + 5) {
          endIndex++;
        }

        final beforeChar = index > 0 ? textLower[index - 1] : ' ';
        final afterChar = endIndex < textLower.length ? textLower[endIndex] : ' ';

        if (!_isLetterChar(beforeChar) && !_isLetterChar(afterChar)) {
          final originalText = text.substring(index, endIndex);
          references.add(TermReference(
            term: term,
            start: index,
            end: endIndex,
            originalText: originalText,
          ));
        }

        startIndex = index + 1;
      }
    }

    references.sort((a, b) => a.start.compareTo(b.start));
    return references;
  }
}