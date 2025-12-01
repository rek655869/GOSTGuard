import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../common/widgets/base_screen.dart';
import '../../common/widgets/primary_button.dart';
import '../../app/theme/app_colors.dart';
import 'gost_models.dart';
import 'gost_service.dart';

class GostsScreen extends StatefulWidget {
  const GostsScreen({super.key});

  @override
  State<GostsScreen> createState() => _GostsScreenState();
}

class _GostsScreenState extends State<GostsScreen> {
  final GostService _gostService = GostService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Set<String>> _highlightedTermsBySection = {};

  GostSection? _selectedSection;
  TermCategory? _selectedCategory;
  bool _showSubsections = false;
  bool _isLoading = false;
  List<GostSection> _sections = [];
  List<GostStandard> _standards = [];
  List<TermCategory> _termCategories = [];
  List<Term> _searchResults = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _performSearch();
    });
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _searchResults.clear();
    } else {
      final allTerms = _termCategories.expand((category) => category.terms).toList();
      _searchResults = allTerms.where((term) =>
        term.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final sections = await _gostService.getSections();
      final standards = await _gostService.getStandards();
      final categories = await _gostService.getTermCategories();

      setState(() {
        _sections = sections;
        _standards = standards;
        _termCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectSection(GostSection section) {
    setState(() {
      _selectedSection = section;
      _selectedCategory = null;
      _showSubsections = section.hasSubsections;
      _searchController.clear();
      _searchQuery = '';
      _searchResults.clear();

      if (!_highlightedTermsBySection.containsKey(section.id)) {
        _highlightedTermsBySection[section.id] = {};
      }
    });
  }

  void _selectCategory(TermCategory category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _searchQuery = '';
      _searchResults.clear();
    });
  }

  void _backToCategories() {
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
      _searchQuery = '';
      _searchResults.clear();
    });
  }

  void _backToMain() {
    setState(() {
      _selectedSection = null;
      _selectedCategory = null;
      _showSubsections = false;
      _searchController.clear();
      _searchQuery = '';
      _searchResults.clear();
    });
  }

  void _showNotesDialog(BuildContext context, List<String> notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Примечание'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: notes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(note),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<List<Term>> _getAllTerms() async {
    final categories = await _gostService.getTermCategories();
    return categories.expand((category) => category.terms).toList();
  }

  void _onGostLinkTap(String gostId) {
    final standard = _standards.firstWhere(
      (s) => s.id.contains(gostId),
      orElse: () => GostStandard(id: gostId, title: 'ГОСТ $gostId'),
    );

    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ГОСТ $gostId',
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(standard.title,
               style: const TextStyle(fontSize: 14, height: 1.3)),
          if (standard.description != null && standard.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(standard.description!,
                 style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
      duration: const Duration(seconds: 5),
      backgroundColor: AppColors.primary.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  void _onTermLinkTap(Term term) {
    if (_selectedSection?.id != '3' && _selectedSection != null) {
      final highlightedTerms = _highlightedTermsBySection[_selectedSection!.id] ?? {};
      if (!highlightedTerms.contains(term.id)) {
        highlightedTerms.add(term.id);
        _highlightedTermsBySection[_selectedSection!.id] = highlightedTerms;
        setState(() {});
      }
    }

    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term.name,
               style: const TextStyle(
                 fontWeight: FontWeight.bold,
                 fontSize: 16,
                 color: Colors.white
               )),
          const SizedBox(height: 6),
          Text(term.definition,
               style: const TextStyle(fontSize: 14, height: 1.3, color: Colors.white)),
        ],
      ),
      duration: const Duration(seconds: 6),
      backgroundColor: AppColors.primary.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Widget _buildSectionCard(GostSection section) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectSection(section),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    section.id,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                section.hasSubsections ? Icons.folder_open : Icons.description,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichTextWithLinks(String text, {List<Term>? allTerms}) {
    final List<GostReference> gostReferences = _gostService.findGostReferences(text);
    final List<TermReference> termReferences = allTerms != null ?
        _gostService.findTermReferences(text, allTerms) : [];

    if (_selectedSection?.id == '2' || _selectedSection?.id == '3') {
      final List<dynamic> allReferences = [];
      allReferences.addAll(gostReferences);
      allReferences.sort((a, b) => a.start.compareTo(b.start));

      if (allReferences.isEmpty) {
        return Text(text, style: const TextStyle(fontSize: 14, height: 1.4));
      }

      final textSpans = <TextSpan>[];
      int lastIndex = 0;

      for (final reference in allReferences) {
        if (reference.start > lastIndex) {
          textSpans.add(TextSpan(
            text: text.substring(lastIndex, reference.start),
            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black),
          ));
        }

        textSpans.add(TextSpan(
          text: reference.fullText,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _onGostLinkTap(reference.gostId),
        ));

        lastIndex = reference.end;
      }

      if (lastIndex < text.length) {
        textSpans.add(TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black),
        ));
      }

      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black),
          children: textSpans,
        ),
      );
    }

    final Set<String> highlightedTermsInThisSection = _selectedSection != null
        ? _highlightedTermsBySection[_selectedSection!.id] ?? {}
        : {};

    final List<TermReference> termsToHighlight = [];
    final Set<String> termsAlreadyFoundInThisText = {};

    for (final ref in termReferences) {
      final termId = ref.term.id;
      if (highlightedTermsInThisSection.contains(termId)) continue;
      if (termsAlreadyFoundInThisText.contains(termId)) continue;

      termsAlreadyFoundInThisText.add(termId);
      termsToHighlight.add(ref);
      highlightedTermsInThisSection.add(termId);
    }

    if (_selectedSection != null) {
      _highlightedTermsBySection[_selectedSection!.id] = highlightedTermsInThisSection;
    }

    final List<dynamic> allReferences = [];
    allReferences.addAll(gostReferences);
    allReferences.addAll(termsToHighlight);
    allReferences.sort((a, b) => a.start.compareTo(b.start));

    if (allReferences.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 14, height: 1.4));
    }

    final textSpans = <TextSpan>[];
    int lastIndex = 0;

    for (final reference in allReferences) {
      if (reference.start > lastIndex) {
        textSpans.add(TextSpan(
          text: text.substring(lastIndex, reference.start),
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black),
        ));
      }

      if (reference is GostReference) {
        textSpans.add(TextSpan(
          text: reference.fullText,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _onGostLinkTap(reference.gostId),
        ));
      } else if (reference is TermReference) {
        textSpans.add(TextSpan(
          text: reference.originalText,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF1A237E),
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _onTermLinkTap(reference.term),
        ));
      }

      lastIndex = reference.end;
    }

    if (lastIndex < text.length) {
      textSpans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black),
        children: textSpans,
      ),
    );
  }

  Widget _buildImageWidget(String imageName) {
    return FutureBuilder<String>(
      future: _gostService.getImageCaption(imageName),
      builder: (context, snapshot) {
        final caption = snapshot.data ?? 'Загрузка подписи...';
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16, top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: _gostService.getImageAssetPath(imageName),
                builder: (context, snapshot) {
                  final assetPath = snapshot.data ?? 'image/$imageName.png';
                  return Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 300,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'image/$imageName.jpg',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Изображение не найдено: $imageName',
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                caption,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainSections() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(children: _sections.map((section) => _buildSectionCard(section)).toList());
  }

  Widget _buildStandardsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Нормативные ссылки',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        ..._standards.map((standard) {
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.description, color: AppColors.primary),
              title: Text(
                standard.id,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              subtitle: Text(
                standard.title,
                style: TextStyle(color: Colors.grey[700]),
              ),
              onTap: () {
                final snackBar = SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(standard.id,
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(standard.title,
                           style: const TextStyle(fontSize: 14, height: 1.3)),
                      if (standard.description != null && standard.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(standard.description!,
                             style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                  duration: const Duration(seconds: 5),
                  backgroundColor: AppColors.primary.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(snackBar);
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск по названию термина...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTermItem(Term term, {String? categoryTitle}) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.abc, color: AppColors.primary, size: 24),
        title: Text(
          term.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        subtitle: categoryTitle != null
            ? Text('Категория: $categoryTitle', style: TextStyle(color: Colors.grey[600]))
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FutureBuilder<List<Term>>(
                    future: _getAllTerms(),
                    builder: (context, snapshot) {
                      final allTerms = snapshot.data ?? [];
                      return _buildRichTextWithLinks(term.definition, allTerms: allTerms);
                    },
                  ),
                ),
                if (term.notes.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.info_outline, color: AppColors.primary),
                    onPressed: () => _showNotesDialog(context, term.notes),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermCategories() {
    if (_searchQuery.isNotEmpty) return _buildSearchResults();
    if (_selectedCategory != null) return _buildCategoryTerms();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Термины и определения',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildSearchField(),
        ..._termCategories.map((category) {
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.abc, color: AppColors.primary),
              title: Text(
                category.title,
                style: TextStyle(color: AppColors.primary),
              ),
              onTap: () => _selectCategory(category),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryTerms() {
    final terms = _selectedCategory?.terms ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: PrimaryButton(
            icon: Icons.arrow_back,
            label: 'К категориям',
            radius: 12,
            onPressed: _backToCategories,
          ),
        ),
        Text(
          _selectedCategory?.title ?? '',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...terms.map((term) => _buildTermItem(term)).toList(),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCategory != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: PrimaryButton(
              icon: Icons.arrow_back,
              label: 'К категориям',
              radius: 12,
              onPressed: _backToCategories,
            ),
          ),
        Text(
          'Результаты поиска',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildSearchField(),
        if (_searchResults.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 50, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Термины не найдены',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ..._searchResults.map((term) {
            final category = _termCategories.firstWhere(
              (cat) => cat.id == term.categoryId,
              orElse: () => TermCategory(id: '', title: '', terms: [])
            );
            return _buildTermItem(term, categoryTitle: category.title);
          }).toList(),
      ],
    );
  }

  Widget _buildSectionContent() {
    if (_selectedSection?.content == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedSection?.title ?? '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 50, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Раздел работает корректно',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Содержимое раздела будет добавлено в ближайшее время',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final contentItems = _gostService.parseSectionContent(_selectedSection!.content!);
    return FutureBuilder<List<Term>>(
      future: _getAllTerms(),
      builder: (context, snapshot) {
        final allTerms = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedSection?.title ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...contentItems.map((item) {
                      if (item.isNote) {
                        return FutureBuilder<String>(
                          future: _gostService.getNoteContent(item.noteId ?? ''),
                          builder: (context, snapshot) {
                            final noteContent = snapshot.data ?? 'Загрузка...';
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Примечание',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRichTextWithLinks(noteContent, allTerms: allTerms),
                                ],
                              ),
                            );
                          },
                        );
                      } else if (item.isImage) {
                        return _buildImageWidget(item.imageName!);
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRichTextWithLinks(item.text, allTerms: allTerms),
                        );
                      }
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubsections() {
    if (_selectedSection == null) return const SizedBox();
    switch (_selectedSection!.id) {
      case '2': return _buildStandardsList();
      case '3': return _buildTermCategories();
      default: return _buildSectionContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedSection != null && _selectedCategory == null && _searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: PrimaryButton(
                  icon: Icons.arrow_back,
                  label: 'К разделам',
                  radius: 12,
                  onPressed: _backToMain,
                ),
              ),
            if (_selectedSection == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'ГОСТы и стандарты',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (_selectedSection == null)
              _buildMainSections()
            else if (_showSubsections)
              _buildSubsections()
            else
              _buildSectionContent(),
          ],
        ),
      ),
    );
  }
}