// subcategory_level_one_model.dart
import 'package:collection/collection.dart';

class SubcategoryLevelOne {
  final int id;
  final int categoryId;
  final String categoryName;
  final String slug;
    final String? slugCategoryMain; // <-- هنا أضفنا slug التصنيف الرئيسي

  final DateTime date;
  final int adsCount;
  final List<SubcategoryLevelOneTranslation> translations;
  final String? image;
  final String? metaTitle;
  final String? metaDescription;

  SubcategoryLevelOne({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.slug,
    this.slugCategoryMain,
    required this.date,
    required this.adsCount,
    required this.translations,
    this.image,
    this.metaTitle,
    this.metaDescription,
  });

  factory SubcategoryLevelOne.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    final rawTrans = json['translations'];
    final translationsList = (rawTrans is List)
        ? rawTrans
            .whereType<Map<String, dynamic>>()
            .map((e) => SubcategoryLevelOneTranslation.fromJson(e))
            .toList()
        : <SubcategoryLevelOneTranslation>[];

    return SubcategoryLevelOne(
      id: parseInt(json['id']),
      categoryId: parseInt(json['category_id']),
      categoryName: (json['category_name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
            slugCategoryMain: (json['slug_categeroMain'] as String?) ?? null, // <-- هنا

      date: DateTime.tryParse((json['date'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      adsCount: parseInt(json['ads_count'] ?? json['published_ads_count']),
      translations: translationsList,
      image: (json['image'] as String?) ?? null,
      metaTitle: (json['meta_title'] ?? json['metaTitle'])?.toString(),
      metaDescription:
          (json['meta_description'] ?? json['metaDescription'])?.toString(),
    );
  }

  String get name => translations.firstOrNull?.name ?? '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'category_name': categoryName,
        'slug': slug,
        'date': date.toIso8601String(),
        'ads_count': adsCount,
        'translations': translations.map((t) => t.toJson()).toList(),
        'image': image,
        'meta_title': metaTitle,
        'meta_description': metaDescription,
      };

  @override
  String toString() {
    return 'SubcategoryLevelOne(id: $id, categoryName: $categoryName, name: $name, adsCount: $adsCount)';
  }
}

class SubcategoryLevelOneTranslation {
  final int id;
  final int subCategoryLevelOneId;
  final String language;
  final String name;

  SubcategoryLevelOneTranslation({
    required this.id,
    required this.subCategoryLevelOneId,
    required this.language,
    required this.name,
  });

  factory SubcategoryLevelOneTranslation.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return SubcategoryLevelOneTranslation(
      id: parseInt(json['id']),
      subCategoryLevelOneId:
          parseInt(json['sub_category_level_one_id'] ?? json['subCategoryLevelOneId']),
      language: (json['language'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sub_category_level_one_id': subCategoryLevelOneId,
        'language': language,
        'name': name,
      };

  @override
  String toString() {
    return 'Translation(id: $id, language: $language, name: $name)';
  }
}
