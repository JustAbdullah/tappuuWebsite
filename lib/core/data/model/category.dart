// category_model.dart (معدّل: أضفنا الحقول slug, metaTitle, metaDescription)

class Category {
  final int id;
  final String slug;
    final String? metaTitle;
  final String? metaDescription;
  final String date;
  final String image;
  final int adsCount; // حقل جديد لعدد الإعلانات

  final List<Translation> translations;

  Category({
    required this.id,

    required this.image,
    required this.date,
    required this.adsCount,
        required this.slug,
    this.metaTitle,
    this.metaDescription,
    required this.translations,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as int?) ?? 0,
      image: (json['image'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      adsCount: (json['published_ads_count'] as int?) ??
          (json['ads_count'] as int?) ??
          (json['adsCount'] as int?) ??
          0,
                slug: (json['slug'] as String?) ?? '',

      metaTitle: (json['meta_title'] ?? json['metaTitle'])?.toString(),
      metaDescription:
          (json['meta_description'] ?? json['metaDescription'])?.toString(),
      translations: (json['translations'] as List<dynamic>? ?? [])
          .map((t) => Translation.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  String get name => translations.isNotEmpty ? translations.first.name : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Translation {
  final int id;
  final int categoryId;
  final String language;
  final String name;
  final String description;

  Translation({
    required this.id,
    required this.categoryId,
    required this.language,
    required this.name,
    required this.description,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      id: (json['id'] as int?) ?? 0,
      categoryId: (json['category_id'] as int?) ??
          (json['categoryId'] as int?) ??
          0,
      language: (json['language'] as String?) ?? 'ar',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'language': language,
        'name': name,
        'description': description,
      };
}
