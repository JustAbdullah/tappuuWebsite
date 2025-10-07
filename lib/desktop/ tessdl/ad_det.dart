import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constant/app_text_styles.dart';
import '../../core/data/model/AdResponse.dart';

class AdDet extends StatefulWidget {
  final Ad ad;
  
  AdDet({super.key, required this.ad});

  @override
  State<AdDet> createState() => _AdDetState();
}

class _AdDetState extends State<AdDet> {
  late String baseUrl;
  late String shareLink;

  @override
  void initState() {
    super.initState();
    
    // الحصول على الرابط الأساسي من المتصفح
    baseUrl = html.window.location.origin;
    
    // إنشاء رابط المشاركة
    shareLink = '$baseUrl/ad/${widget.ad.id}';
    
    // تحديث URL المتصفح دون إعادة تحميل الصفحة
    _updateBrowserUrl();
  }

  void _updateBrowserUrl() {
    // استخدام History API لتحديث URL دون إعادة تحميل الصفحة
    html.window.history.pushState({}, '', '/ad/${widget.ad.id}');
  }

  void _copyLink() {
    // نسخ الرابط إلى الحافظة
    html.window.navigator.clipboard?.writeText(shareLink);
    
    // إظهار رسالة للمستخدم
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ رابط الإعلان إلى الحافظة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLink() {
    // مشاركة الرابط عبر التطبيقات الأخرى
    Share.share('تحقق من هذا الإعلان: $shareLink');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ad.title.toString()),
        actions: [
          IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: _copyLink,
            tooltip: 'نسخ الرابط',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareLink,
            tooltip: 'مشاركة الرابط',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ad.title.toString(),
              style: TextStyle(fontSize: AppTextStyles.xxxlarge, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Text(
              widget.ad.description,
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 24.h),
            // عرض رابط المشاركة
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رابط مشاركة الإعلان:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTextStyles.medium,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            shareLink,
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.content_copy),
                          onPressed: _copyLink,
                          tooltip: 'نسخ الرابط',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}