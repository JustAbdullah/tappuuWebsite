// subcategory_level_two_model.dart
import 'package:collection/collection.dart';

class SubcategoryLevelTwo {
  final int id;
  final int subCategoryLevelOneId;
  final String slug;
  final String? slugParent1;         // <-- slug الفرعي الأول
  final String? slugParentCategory;  // <-- slug التصنيف الرئيسي
  final String date; // كما كنت تستخدم سابقاً نص التاريخ
  final int adsCount;
  final List<SubcategoryLevelTwoTranslation> translations;
  final int parent1Id;
  final String parent1Name;
  final int parentCategoryId;
  final String parentCategoryName;
  final String? image;
  final String? metaTitle;
  final String? metaDescription;

  SubcategoryLevelTwo({
    required this.id,
    required this.subCategoryLevelOneId,
    required this.slug,
     this.slugParent1, 
    this.slugParentCategory,
    required this.date,
    required this.adsCount,
    required this.translations,
    required this.parent1Id,
    required this.parent1Name,
    required this.parentCategoryId,
    required this.parentCategoryName,
    this.image,
    this.metaTitle,
    this.metaDescription,
  });

  factory SubcategoryLevelTwo.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    final rawTrans = json['translations'];
    final translationsList = (rawTrans is List)
        ? rawTrans
            .whereType<Map<String, dynamic>>()
            .map((t) => SubcategoryLevelTwoTranslation.fromJson(t))
            .toList()
        : <SubcategoryLevelTwoTranslation>[];

    return SubcategoryLevelTwo(
      id: parseInt(json['id']),
      subCategoryLevelOneId:
          parseInt(json['sub_category_level_one_id'] ?? json['subCategoryLevelOneId']),
      slug: (json['slug'] as String?) ?? '',
      slugParent1: (json['slug_parent1'] as String?) ?? null, // <-- هنا
      slugParentCategory: (json['slug_parent_category'] as String?) ?? null, // <-- ه
      date: (json['date'] as String?) ?? '',
      adsCount: parseInt(json['ads_count'] ?? json['published_ads_count']),
      translations: translationsList,
      parent1Id: parseInt(json['parent1_id'] ?? json['parent1Id']),
      parent1Name: (json['parent1_name'] as String?) ?? '',
      parentCategoryId: parseInt(json['parent_category_id'] ?? json['parentCategoryId']),
      parentCategoryName: (json['parent_category_name'] as String?) ?? '',
      image: (json['image'] as String?) ?? null,
      metaTitle: (json['meta_title'] ?? json['metaTitle'])?.toString(),
      metaDescription:
          (json['meta_description'] ?? json['metaDescription'])?.toString(),
    );
  }

  String get name => translations.firstOrNull?.name ?? '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'sub_category_level_one_id': subCategoryLevelOneId,
        'slug': slug,
        'date': date,
        'ads_count': adsCount,
        'translations': translations.map((t) => t.toJson()).toList(),
        'parent1_id': parent1Id,
        'parent1_name': parent1Name,
        'parent_category_id': parentCategoryId,
        'parent_category_name': parentCategoryName,
        'image': image,
        'meta_title': metaTitle,
        'meta_description': metaDescription,
      };
}

class SubcategoryLevelTwoTranslation {
  final int id;
  final int subCategoryLevelTwoId;
  final String language;
  final String name;

  SubcategoryLevelTwoTranslation({
    required this.id,
    required this.subCategoryLevelTwoId,
    required this.language,
    required this.name,
  });

  factory SubcategoryLevelTwoTranslation.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return SubcategoryLevelTwoTranslation(
      id: parseInt(json['id']),
      subCategoryLevelTwoId:
          parseInt(json['sub_category_level_two_id'] ?? json['subCategoryLevelTwoId']),
      language: (json['language'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sub_category_level_two_id': subCategoryLevelTwoId,
        'language': language,
        'name': name,
      };

  @override
  String toString() {
    return 'Translation(id: $id, language: $language, name: $name)';
  }
}
