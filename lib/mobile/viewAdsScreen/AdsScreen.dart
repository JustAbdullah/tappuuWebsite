
// lib/views/ads/AdsScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/SearchHistoryController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/listing_share_controller.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/localization/changelanguage.dart';
import '../HomeScreen/menubar.dart';
import 'AdItem.dart';
import 'AdsMapFromListScreen.dart';
import 'FilterScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:html' as html;
// دالة مساعدة للعثور على عنصر أو إرجاع null
T? firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}

class AdsScreen extends StatefulWidget {
  final String? titleOfpage;
  final int? categoryId;
  final int? subCategoryId;
  final int? subTwoCategoryId;
  final String? nameOfMain;
  final String? nameOFsub;
  final String? nameOFsubTwo;
  final String? currentTimeframe;
  final bool onlyFeatured;
  final int? cityId;
  final int? areaId;
  final int ?countofAds;
  final String? categorySlug;
  final String? subCategorySlug;
  final String? subTwoCategorySlug;
    final bool? openVoiceSearch;
  final bool? openImageSearch;


  const AdsScreen({
    super.key,
    required this.titleOfpage,
    required this.categoryId,
    this.subCategoryId,
    this.subTwoCategoryId,
    this.nameOfMain,
    this.nameOFsub,
    this.currentTimeframe,
    this.nameOFsubTwo,
    this.onlyFeatured = false,
    this.countofAds = 0,
    this.cityId,
    this.areaId,
    this.categorySlug,
    this.subCategorySlug,
    this.subTwoCategorySlug,
      this.openVoiceSearch =false,

  this.openImageSearch= false,
  });

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}
// ---- كلاس الشاشة (مقتطف state مع التحسينات الصوتية والواجهة) ----
class _AdsScreenState extends State<AdsScreen> with SingleTickerProviderStateMixin {
  
  late AdsController adsController;
  late ThemeController themeController;
  late TextEditingController _searchController;
  late FocusNode _searchFocus;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showSearch = false;

  // ---- image search state ----
  final ImagePicker _imagePicker = ImagePicker();
  // ----------------------------

  // ---- sound search state ----
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  bool _speechInitialized = false;
 

  bool _initialDataLoaded = false;
  bool _isDisposed = false;
  String? _selectedTimePeriod;

  @override
  void initState() {
    super.initState();
    adsController = Get.put(AdsController());
    themeController = Get.find<ThemeController>();
    _searchController = TextEditingController();
    Get.put(ListingShareController(), permanent: false);
    _speech = stt.SpeechToText();
    _searchFocus = FocusNode();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSpeech();
      _convertSlugsToIds().then((_) {
        _handleUrlQueryParameters();
        adsController.fetchAds(
          categoryId: widget.categoryId,
          subCategoryLevelOneId: widget.subCategoryId,
          subCategoryLevelTwoId: widget.subTwoCategoryId,
          lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
          timeframe: widget.currentTimeframe,
          onlyFeatured: widget.onlyFeatured,
          cityId: widget.cityId,
          areaId: widget.areaId,
        );
      });
      _updateBrowserUrl();


       if(widget.openVoiceSearch == true){
      
      _openSearch();
   _showVoiceSearchDialog();
      setState(() {
        
      });
    }if(widget.openImageSearch == true){
      
      _openSearch();
    _showImageSearchDialog();
       
    }
    });
  }

  Future<void> _convertSlugsToIds() async {
    if (widget.categorySlug != null) {
      if (adsController.mainCategories.isEmpty) {
        await adsController.fetchMainCategories(
          Get.find<ChangeLanguageController>().currentLocale.value.languageCode
        );
      }

      final mainCategory = firstWhereOrNull(
        adsController.mainCategories, 
        (c) => c.slug == widget.categorySlug
      );
      
      if (mainCategory != null) {
        adsController.selectedMainCategoryId.value = mainCategory.id;
        adsController.currentCategoryId.value = mainCategory.id;
        
        await adsController.fetchSubCategories(
          mainCategory.id, 
          Get.find<ChangeLanguageController>().currentLocale.value.languageCode
        );
        
        if (widget.subCategorySlug != null) {
          final subCategory = firstWhereOrNull(
            adsController.subCategories, 
            (c) => c.slug == widget.subCategorySlug
          );
          
          if (subCategory != null) {
            adsController.selectedSubCategoryId.value = subCategory.id;
            adsController.currentSubCategoryLevelOneId.value = subCategory.id;
            
            await adsController.fetchSubTwoCategories(subCategory.id);
            
            if (widget.subTwoCategorySlug != null) {
              final subTwoCategory = firstWhereOrNull(
                adsController.subTwoCategories, 
                (c) => c.slug == widget.subTwoCategorySlug
              );
              
              if (subTwoCategory != null) {
                adsController.selectedSubTwoCategoryId.value = subTwoCategory.id;
                adsController.currentSubCategoryLevelTwoId.value = subTwoCategory.id;
              }
            }
          }
        }
      }
    }
  }

  void _handleUrlQueryParameters() {
    final currentUri = Uri.parse(html.window.location.href);
    
    if (currentUri.queryParameters.isNotEmpty) {
      if (currentUri.queryParameters.containsKey('search')) {
        final searchQuery = currentUri.queryParameters['search'];
        adsController.currentSearch.value = searchQuery ?? '';
        _searchController.text = searchQuery ?? '';
      }
      
      if (currentUri.queryParameters.containsKey('city')) {
        final cityId = int.tryParse(currentUri.queryParameters['city'] ?? '');
        if (cityId != null) {
          final city = firstWhereOrNull(
            adsController.citiesList,
            (c) => c.id == cityId,
          );
          if (city != null) {
            adsController.selectCity(city);
          }
        }
      }
      
      if (currentUri.queryParameters.containsKey('timeframe')) {
        _selectedTimePeriod = currentUri.queryParameters['timeframe'];
      }
    }
  }

  void _updateBrowserUrl() {
    String urlPath = '/ads';
    
    if (widget.categorySlug != null) {
      urlPath += '/${widget.categorySlug}';
      
      if (widget.subCategorySlug != null) {
        urlPath += '/${widget.subCategorySlug}';
        
        if (widget.subTwoCategorySlug != null) {
          urlPath += '/${widget.subTwoCategorySlug}';
        }
      }
    }
    
    final params = <String>[];
    
    if (adsController.currentSearch.value.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(adsController.currentSearch.value)}');
    }
    
    if (adsController.selectedCity.value != null) {
      params.add('city=${adsController.selectedCity.value!.id}');
    }
    
    if (_selectedTimePeriod != null && _selectedTimePeriod != 'all') {
      params.add('timeframe=$_selectedTimePeriod');
    }
    
    if (params.isNotEmpty) {
      urlPath += '?${params.join('&')}';
    }
    
    html.window.history.replaceState({}, '', urlPath);
  }

  void updateUrlWithFilters() {
    String urlPath = '/ads';
    
    if (adsController.selectedMainCategoryId.value != null) {
      final mainCategory = firstWhereOrNull(
        adsController.mainCategories,
        (c) => c.id == adsController.selectedMainCategoryId.value,
      );
      if (mainCategory != null && mainCategory.slug != null) {
        urlPath += '/${mainCategory.slug}';
      }
    }
    
    if (adsController.selectedSubCategoryId.value != null) {
      final subCategory = firstWhereOrNull(
        adsController.subCategories,
        (c) => c.id == adsController.selectedSubCategoryId.value,
      );
      if (subCategory != null && subCategory.slug != null) {
        urlPath += '/${subCategory.slug}';
      }
    }
    
    if (adsController.selectedSubTwoCategoryId.value != null) {
      final subTwoCategory = firstWhereOrNull(
        adsController.subTwoCategories,
        (c) => c.id == adsController.selectedSubTwoCategoryId.value,
      );
      if (subTwoCategory != null && subTwoCategory.slug != null) {
        urlPath += '/${subTwoCategory.slug}';
      }
    }
    
    final params = <String>[];
    
    if (adsController.currentSearch.value.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(adsController.currentSearch.value)}');
    }
    
    if (adsController.selectedCity.value != null) {
      params.add('city=${adsController.selectedCity.value!.id}');
    }
    
    if (_selectedTimePeriod != null && _selectedTimePeriod != 'all') {
      params.add('timeframe=$_selectedTimePeriod');
    }
    
    if (params.isNotEmpty) {
      urlPath += '?${params.join('&')}';
    }
    
    html.window.history.replaceState({}, '', urlPath);
  }




  // دالة تهيئة التعرف على الكلام
  Future<bool> _initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          if (mounted && status == 'notListening' && _isListening) {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      return _speechInitialized;
    } catch (e) {
      print('Error initializing speech: $e');
      if (mounted) {
        setState(() {
          _speechInitialized = false;
        });
      }
      return false;
    }
  }

  // في دالة toggleListening داخل _showVoiceSearchDialog
  Future<void> toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      if (!_speechInitialized) {
        // محاولة إعادة التهيئة إذا فشلت أول مرة
        bool initialized = await _initSpeech();
        if (!initialized) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('التعرف على الكلام غير متاح'.tr)),
            );
          }
          return;
        }
      }

      // التحقق من الإذن - الطريقة الصحيحة حسب التوثيق الرسمي
      bool hasPermission = await _speech.hasPermission;
      if (!hasPermission) {
        // طريقة طلب الإذن الصحيحة هي استخدام initialize()
        hasPermission = await _speech.initialize(
          onStatus: (status) {
            if (mounted && status == 'notListening' && _isListening) {
              setState(() {
                _isListening = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          },
        );
      }

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم رفض إذن استخدام الميكروفون'.tr)),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isListening = true;
          _recognizedText = '';
        });
      }

      _speech.listen(
        onResult: (result) {
          // لا نصرّح بنوع صريح لتفادي مشكلة undefined class
          if (mounted) {
            try {
              final recognized = (result.recognizedWords ?? '');
              setState(() {
                _recognizedText = recognized;
              });
            } catch (_) {
              // سلامة: إذا النتيجة شكلها غير متوقع تجاهل
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  void _stopListening() {
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _showSearch = true;
    });
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) FocusScope.of(context).requestFocus(_searchFocus);
    });
  }

  void _showVoiceSearchDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> toggleListeningInner() async {
              // استدعاء الدالة العامة toggleListening حتى تكون المنطق موحد
              await toggleListening();
              // حدث الـ dialog بعد تغيير الحالة
              if (mounted) setState(() {});
            }

            final isDarkMode = themeController.isDarkMode.value;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.surface(isDarkMode),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'البحث الصوتي'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.xlarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Icon(
                      Icons.mic,
                      size: 36.w,
                      color: _isListening ? Colors.green : AppColors.textSecondary(isDarkMode),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      _isListening ? 'جاري الاستماع...'.tr : 'انقر على الميكروفون وابدأ الكلام'.tr,
                      style: TextStyle(
                        color: AppColors.textSecondary(isDarkMode),
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.card(isDarkMode),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _recognizedText,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkMode),
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _stopListening();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.redId,
                          ),
                          child: Text(
                            'إلغاء'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: toggleListeningInner,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening ? Colors.red : AppColors.primary,
                          ),
                          child: Text(
                            _isListening ? 'إيقاف'.tr : 'بدء'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _recognizedText.isEmpty
                              ? null
                              : () {
                                  _stopListening();
                                  Navigator.pop(context);
                                  _searchController.text = _recognizedText;
                                  _performSearch();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonAndLinksColor,
                          ),
                          child: Text(
                            'بحث'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // تأكّد من إيقاف الاستماع عند غلق الحوار
      if (_isListening) _stopListening();
    });
  }

  void _performSearch({String? searchText}) {
    final q = (searchText ?? _searchController.text).trim();
    adsController.currentSearch.value = q;
    adsController.fetchAds(
      categoryId: widget.categoryId,
      subCategoryLevelOneId: adsController.currentSubCategoryLevelOneId.value,
      subCategoryLevelTwoId: adsController.currentSubCategoryLevelTwoId.value,
      search: q.isNotEmpty ? q : null,
      cityId: adsController.selectedCity.value?.id,
      areaId: adsController.selectedArea.value?.id,
      attributes: adsController.currentAttributes.isNotEmpty ? adsController.currentAttributes : null,
      lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      timeframe: widget.currentTimeframe,
      onlyFeatured: widget.onlyFeatured,
      page: 1,
    );

    // اغلاق الحقل بعد البحث (لو تريد إبقائه مفتوح احذف هذا السطر)
    _closeSearch();
  }

  String _formatCount(int count) {
    return count.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  void _closeSearch() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showSearch = false;
        });
      }
    });
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }



  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeController.isDarkMode.value;

    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: Menubar(), // بدل drawer العادي
          backgroundColor: AppColors.background(isDarkMode),

          // ===== AppBar مخصّص مشابه للصورة =====
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(color: AppColors.primary),
                child: Row(
                  children: [
                    // menu / hamburger
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.white, size: 26.w),
                      onPressed: () {
                        try {
                          _scaffoldKey.currentState?.openDrawer();
                        } catch (_) {}
                      },
                    ),

                    SizedBox(width: 6.w),

                    // Title + subtitle (count)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.titleOfpage??"",
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.xlarge,

                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Obx(() {
                            final count = adsController.filteredAdsList.length;
                            return Text(
                              '${_formatCount(count)} ${'إعلان'.tr}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.small,

                                color: Colors.white.withOpacity(0.9),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // actions: search, share, favorite
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.white, size: 24.w),
                          onPressed: _openSearch,
                        ),
                        IconButton(
                          icon: Icon(Icons.share, color: Colors.white, size: 24.w),
                          onPressed: () {
                            try {
                              final shareCtrl = Get.find<ListingShareController>();
                              final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

                              // جمع الفلاتر الحالية لتمريرها
                              final categoryId = widget.categoryId;
                              final sub1 = widget.subCategoryId;
                              final sub2 = widget.subTwoCategoryId;
                              final search = adsController.currentSearch.value.isNotEmpty ? adsController.currentSearch.value : null;
                              final sortBy = adsController.currentSortBy.value;
                              final order = adsController.currentOrder.value;
                              final attributes = (adsController.currentAttributes != null && adsController.currentAttributes.isNotEmpty)
                                  ? adsController.currentAttributes
                                  : null;
                              final cityId = widget.cityId ?? adsController.selectedCity.value?.id;
                              final areaId = widget.areaId ?? adsController.selectedArea.value?.id;
                              final timeframe = widget.currentTimeframe;
                              final onlyFeatured = widget.onlyFeatured;

                              // عنوان ونص دعائي قصير
                              final title = widget.titleOfpage;
                              final subtitle = onlyFeatured
                                  ? 'اطّلع على الإعلانات المميزة في $title'
                                  : (search != null ? 'نتائج البحث عن: "$search"' : 'اكتشف أحدث الإعلانات في $title');

                              // عدد النتائج الحالية (لإظهار في الرسالة)
                              final resultsCount = adsController.filteredAdsList.length;

                              shareCtrl.shareListing(
                                categoryId: categoryId,
                                subCategoryLevelOneId: sub1,
                                subCategoryLevelTwoId: sub2,
                                search: search,
                                sortBy: sortBy,
                                order: order,
                                attributes: attributes,
                                cityId: cityId,
                                areaId: areaId,
                                timeframe: timeframe,
                                onlyFeatured: onlyFeatured,
                                lang: lang,
                                title: title,
                                subtitle: subtitle,
                                resultsCount: resultsCount,
                              );
                            } catch (e) {
                              // لو لم يتم تسجيل الـ ListingShareController، سجّله الآن وحاول مجددًا
                              debugPrint('Share error: $e');
                              final shareCtrl = Get.put(ListingShareController());
                              final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
                              shareCtrl.shareListing(
                                categoryId: widget.categoryId,
                                subCategoryLevelOneId: widget.subCategoryId,
                                subCategoryLevelTwoId: widget.subTwoCategoryId,
                                lang: lang,
                                title: widget.titleOfpage,
                                subtitle: 'تصفّح الإعلانات',
                                resultsCount: adsController.filteredAdsList.length,
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.star_border, color: Colors.white, size: 24.w),
                          onPressed: () {
                            _showSaveSearchDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== Body =====
          body: SafeArea(
            child: Obx(() {
              final isLoading = adsController.isLoadingAds.value;
              final empty = adsController.filteredAdsList.isEmpty;

              return Column(
                children: [
                  // ===== Toolbar تحت العنوان — مشابه للصورة =====
                  Container(
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: AppColors.backGroundButton(isDarkMode),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.09),
                          blurRadius: 9,
                          offset: const Offset(0, 7),
                        )
                      ],
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: [
                        _toolItem(
                          label: 'حفظ البحث'.tr,
                          onTap: () {
                            _showSaveSearchDialog(context);
                          },
                          isDarkMode: isDarkMode,
                        ),
                        _verticalToolDivider(isDarkMode),
                        _toolItem(
                          label: 'فرز حسب'.tr,
                          onTap: () => _showSortOptions(context, adsController),
                          isDarkMode: isDarkMode,
                        ),
                        _verticalToolDivider(isDarkMode),
                        Obx(() {
                          int activeFilters = 0;
                          try {
                            if (adsController.currentAttributes != null && adsController.currentAttributes.isNotEmpty) activeFilters += adsController.currentAttributes.length;
                          } catch (_) {}
                          try {
                            if (adsController.selectedCity.value != null) activeFilters += 1;
                          } catch (_) {}
                          try {
                            if (adsController.selectedArea.value != null) activeFilters += 1;
                          } catch (_) {}
                          return _toolItem(
                            label: 'فلترة'.tr,
                            onTap: () {
                              if (widget.categoryId != null) {
                                Get.to(() => FilterScreen(categoryId: widget.categoryId!, currentTimeframe: widget.currentTimeframe, onlyFeatured: widget.onlyFeatured));
                              } else {
                                Get.to(() => FilterScreen(categoryId: 0, currentTimeframe: widget.currentTimeframe, onlyFeatured: widget.onlyFeatured));
                              }
                            },
                            isDarkMode: isDarkMode,
                            badgeCount: activeFilters,
                          );
                        }),
                        _verticalToolDivider(isDarkMode),
                        _toolItem(
                          label: 'طريقة العرض'.tr,
                          onTap: () => _showViewOptions(context, adsController),
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 7.h),

                  // ===== المحتوى: شيمر / رسالة فارغة / قائمة الإعلانات =====
                  Expanded(
                    child: isLoading
                        ? _buildShimmerLoader()
                        : empty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 48.w, color: AppColors.grey),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'لا توجد إعلانات مطابقة'.tr,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.xlarge,

                                        color: AppColors.textSecondary(isDarkMode),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _buildAdsList(adsController),
                  ),
                ],
              );
            }),
          ),

          // زر الخريطة أسفل يمين مثل الصورة
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Get.to(() => AdsMapFromListScreen(
                    ads: adsController.filteredAdsList,
                  ));
            },
            backgroundColor: AppColors.primary,
            child: Icon(Icons.location_on, color: Colors.white, size: 28.w),
          ),
        ),

        // ===== Search Overlay (dark background full screen + top aligned search box) =====
        if (_showSearch)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Stack(
                children: [
                  // dim background (tap outside to close)
                  GestureDetector(
                    onTap: _closeSearch,
                    child: Container(color: Colors.black.withOpacity(0.45)),
                  ),

                  // top-aligned search box (under the status bar / appbar)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: AppColors.surface(themeController.isDarkMode.value),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocus,
                                      textInputAction: TextInputAction.search,
                                      onSubmitted: (v) => _performSearch(searchText: v),
                                      decoration: InputDecoration(
                                        hintText: 'ابحث عن إعلان، ادخل عنوان البحث هنا '.tr,
                                        hintStyle: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontSize: AppTextStyles.medium,

                                          color: AppColors.textSecondary(themeController.isDarkMode.value),
                                        ),
                                        isDense: true,
                                        border: InputBorder.none,
                                      ),
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.medium,

                                        color: AppColors.textPrimary(themeController.isDarkMode.value),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),

                                  // ---- image search icon ----
                                  IconButton(
                                    icon: Icon(Icons.image_search_outlined, color: AppColors.textPrimary(themeController.isDarkMode.value), size: 22.w),
                                    onPressed: () => _showImageSearchDialog(),
                                    tooltip: 'بحث بواسطة صورة'.tr,
                                  ),
                                  SizedBox(width: 6.w),
                                  // ----------------------------
                                  IconButton(
                                    icon: Icon(Icons.mic, color: AppColors.textPrimary(themeController.isDarkMode.value), size: 22.w),
                                    onPressed: _showVoiceSearchDialog,
                                    tooltip: 'بحث بالصوت'.tr,
                                  ),
                                  SizedBox(width: 6.w),
                                  InkWell(
                                    onTap: () => _performSearch(),
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.search, color: Colors.white, size: 20.w),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'بحث'.tr,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.appFontFamily,
                                              fontSize: AppTextStyles.medium,

                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  InkWell(
                                    onTap: _closeSearch,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                                      child: Icon(Icons.close, size: 22.w, color: AppColors.textSecondary(themeController.isDarkMode.value)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ===== Helper widget for toolbar items =====
  Widget _toolItem({
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        height: double.infinity,
        child: Row(
          children: [
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,

                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            if (badgeCount > 0) ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12.r)),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _verticalToolDivider(bool isDarkMode) {
    return Container(
      width: 1,
      height: 28.h,
      color: AppColors.grey.withOpacity(0.35),
      margin: EdgeInsets.symmetric(horizontal: 6.w),
    );
  }

  // ========== باقي الدوال كما عندك (قوائم، شيمر، مودالات) ==========
  Widget _buildAdsList(AdsController controller) {
    final viewMode = controller.viewMode.value;

    if (viewMode.startsWith('grid')) {
      return GridView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: viewMode == 'grid_simple' ? 1.17 : 0.85,
        ),
        itemCount: controller.filteredAdsList.length,
        itemBuilder: (context, index) {
          return AdItem(ad: controller.filteredAdsList[index], viewMode: viewMode);
        },
      );
    } else if (viewMode.startsWith('vertical')) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 0.h),
        itemCount: controller.filteredAdsList.length,
        itemBuilder: (context, index) {
          return AdItem(ad: controller.filteredAdsList[index], viewMode: viewMode);
        },
      );
    } else {
      return AdsMapFromListScreen(ads: controller.filteredAdsList);
    }
  }

  Widget _buildShimmerLoader() {
    final isDarkMode = themeController.isDarkMode.value;

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(0.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, spreadRadius: 1, offset: Offset(0, 2)),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // simplified shimmer row (title + image)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 18.h, width: double.infinity, color: Colors.white),
                            SizedBox(height: 6.h),
                            Container(height: 16.h, width: 160.w, color: Colors.white),
                            SizedBox(height: 12.h),
                            Container(height: 14.h, width: 100.w, color: Colors.white),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(width: 110.w, height: 80.h, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSaveSearchDialog(BuildContext context) {
    SearchHistoryController searchHistoryController = Get.put(SearchHistoryController());

    final isDarkMode = themeController.isDarkMode.value;
    TextEditingController searchNameController = TextEditingController();
    bool emailNotifications = true;
    bool mobileNotifications = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.all(16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.surface(isDarkMode),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'حفظ البحث'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.xlarge,

                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: searchNameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.card(isDarkMode),
                        hintText: 'اسم البحث'.tr,
                        hintStyle: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,

                          color: AppColors.grey,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildNotificationOption(
                      title: 'إشعار البريد الإلكتروني'.tr,
                      value: emailNotifications,
                      isDarkMode: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          emailNotifications = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12.h),
                    _buildNotificationOption(
                      title: 'إشعارات الهاتف المحمول'.tr,
                      value: mobileNotifications,
                      isDarkMode: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          mobileNotifications = value!;
                        });
                      },
                    ),

                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                color: AppColors.buttonAndLinksColor,
                                width: 1.2,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Text(
                              'إلغاء'.tr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,

                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final userId = Get.find<LoadingController>().currentUser?.id;
                              if (userId == null) {
                                Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول '.tr);
                                return;
                              } else if (widget.categoryId == null) {
                                Get.snackbar('تنبيه'.tr, 'لايمكنك حفظ البحث في عمليات البحث او الاعلانات المميزة او العاجلة'.tr);
                              } else {
                                print(userId);
                                searchHistoryController.addSearchHistory(
                                    userId: Get.find<LoadingController>().currentUser?.id ?? 0,
                                    recordName: searchNameController.text,
                                    categoryId: widget.categoryId!,
                                    subcategoryId: widget.subCategoryId,
                                    secondSubcategoryId: widget.subCategoryId,
                                    notifyPhone: mobileNotifications,
                                    notifyEmail: emailNotifications);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonAndLinksColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Text(
                              'حفظ'.tr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,

                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required bool value,
    required bool isDarkMode,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.buttonAndLinksColor,
          activeTrackColor: AppColors.buttonAndLinksColor.withOpacity(0.4),
        ),
      ],
    );
  }

void _showViewOptions(BuildContext context, AdsController controller) {
  final isDarkMode = themeController.isDarkMode.value;
  final List<Map<String, dynamic>> viewOptions = [
    {'value': 'vertical_simple', 'label': 'عرض طولي (مختصر)'.tr, 'icon': Icons.view_agenda_outlined},
    {'value': 'grid_simple', 'label': 'عرض شبكي (مختصر)'.tr, 'icon': Icons.grid_view_outlined},
    {'value': 'map', 'label': 'العرض على الخريطة'.tr, 'icon': Icons.map_outlined},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.30,
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Text(
                'خيارات العرض'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: viewOptions.length,
                itemBuilder: (context, index) {
                  final option = viewOptions[index];
                  return ListTile(
                    leading: Icon(option['icon'], color: AppColors.primary),
                    title: Text(
                      option['label'],
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (option['value'] == 'map') {
                        // افتح شاشة الخريطة كاملة
                        Get.to(() => AdsMapFromListScreen(
                              ads: controller.filteredAdsList,
                              embedded: false,
                            ));
                      } else {
                        controller.changeViewMode(option['value']);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showSortOptions(BuildContext context, AdsController controller) {
  final isDarkMode = themeController.isDarkMode.value;
  final Map<String, String> sortMap = {
    'الأحدث إلى الأقدم'.tr: 'newest',
    'الأقدم إلى الأحدث'.tr: 'oldest',
    'الأغلى إلى الأرخص'.tr: 'price_desc',
    'الأرخص إلى الأغلى'.tr: 'price_asc',
    'الأكثر مشاهدة'.tr: 'most_viewed',
    'الأقل مشاهدة'.tr: 'least_viewed',
  };
  final sortOptions = sortMap.keys.toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.45,
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Text(
                'خيارات الفرز'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: sortOptions.length,
                itemBuilder: (context, index) {
                  final label = sortOptions[index];
                  return ListTile(
                    title: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      final sortValue = sortMap[label] ?? 'newest';
                      controller.fetchAds(
                        categoryId: widget.categoryId,
                        subCategoryLevelOneId: controller.currentSubCategoryLevelOneId.value,
                        subCategoryLevelTwoId: controller.currentSubCategoryLevelTwoId.value,
                        search: controller.currentSearch.value.isNotEmpty ? controller.currentSearch.value : null,
                        sortBy: sortValue,
                        cityId: controller.selectedCity.value?.id,
                        areaId: controller.selectedArea.value?.id,
                        attributes: controller.currentAttributes.isNotEmpty ? controller.currentAttributes : null,
                        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
                        timeframe: widget.currentTimeframe,
                        onlyFeatured: widget.onlyFeatured,
                        page: 1,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------- Image search UI & logic ----------------

/// يعرض مودال لاختيار/التقاط صورة ثم زر "ابحث الآن"
void _showImageSearchDialog() {
  XFile? pickedXFile;
  File? _pickedImage;
  bool isSearching = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final isDark = themeController.isDarkMode.value;
      return StatefulBuilder(builder: (context, setState) {
        return Dialog(
          insetPadding: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بحث بالصور'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.xlarge,

                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'التقط صورة أو اختر من المعرض ثم اضغط "ابحث الآن"'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,

                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                SizedBox(height: 12.h),

                // معاينة الصورة لو موجودة
                Container(
                  height: 160.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.grey.withOpacity(0.12)),
                  ),
                  child: _pickedImage == null
                      ? Center(
                          child: Text(
                            'لم يتم اختيار صورة'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.grey,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover),
                        ),
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.photo_camera),
                        label: Text(
                          'كاميرا'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: Colors.black,
                          ),
                        ),
                        onPressed: isSearching
                            ? null
                            : () async {
                                try {
                                  final XFile? x = await _imagePicker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 80,
                                    maxWidth: 1024,
                                  );
                                  if (x != null) {
                                    setState(() {
                                      pickedXFile = x;
                                      _pickedImage = File(x.path);
                                    });
                                  }
                                } catch (e) {
                                  print('Camera pick error: $e');
                                  Get.snackbar(
                                    'خطأ',
                                    'فشل اختيار الصورة من الكاميرا',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.photo_library),
                        label: Text(
                          'معرض'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: Colors.black,
                          ),
                        ),
                        onPressed: isSearching
                            ? null
                            : () async {
                                try {
                                  final XFile? x = await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 80,
                                    maxWidth: 1024,
                                  );
                                  if (x != null) {
                                    setState(() {
                                      pickedXFile = x;
                                      _pickedImage = File(x.path);
                                    });
                                  }
                                } catch (e) {
                                  print('Gallery pick error: $e');
                                  Get.snackbar(
                                    'خطأ',
                                    'فشل اختيار الصورة من المعرض',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSearching
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: Text(
                          'إلغاء'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.redId,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (isSearching || pickedXFile == null)
                            ? null
                            : () async {
                                // 1) فعل حالة البحث داخل الـ dialog
                                setState(() => isSearching = true);

                                try {
                                  // 2) استدعاء الكنترولر
                                  final adsController = Get.find<AdsController>();

                                  // 3) استدعاء عملية البحث بالصورة
                                  await adsController.searchAdsByImage(
                                    imageFile: pickedXFile!,
                                    lang: Get.find<ChangeLanguageController>()
                                        .currentLocale
                                        .value
                                        .languageCode,
                                    page: 1,
                                    perPage: 15,
                                    categoryId: widget.categoryId,
                                    subCategoryLevelOneId: widget.subCategoryId,
                                    subCategoryLevelTwoId: widget.subTwoCategoryId,
                                    debug: false,
                                  );

                                  // 4) إغلاق المودال بعد النجاح وإظهار رسالة خفيفة
                                  Navigator.pop(context);
                                  Get.snackbar(
                                    'نجاح',
                                    'تم جلب النتائج',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } catch (e, st) {
                                  // معالجة الأخطاء وعرض رسالة مفصّلة للمستخدم
                                  print('searchByImage error: $e');
                                  print(st);
                                  final errMsg = (e is Exception) ? e.toString() : 'حدث خطأ غير متوقع';
                                  Get.snackbar(
                                    'خطأ',
                                    errMsg,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  setState(() => isSearching = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonAndLinksColor),
                        child: isSearching
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                                ),
                              )
                            : Text(
                                'ابحث الآن'.tr,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}
}