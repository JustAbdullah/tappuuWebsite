import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/AdsManageSearchController.dart';
import 'ad_det.dart';

class LoadingAd extends StatefulWidget {
  final String adId;

  const LoadingAd({super.key, required this.adId});

  @override
  State<LoadingAd> createState() => _LoadingAdState();
}

class _LoadingAdState extends State<LoadingAd> {
  final AdsController _adsController = Get.find<AdsController>();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // تحديث URL المتصفح ليعكس حالة التحميل
    _updateBrowserUrl();
    
    // بدء تحميل بيانات الإعلان
    _loadAd();
  }

  void _updateBrowserUrl() {
    final baseUrl = html.window.location.origin;
    html.window.history.pushState({}, '', '/ad/loading/${widget.adId}');
  }

  Future<void> _loadAd() async {
    try {
      await _adsController.fetchAdDetails(adId: widget.adId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // الانتقال إلى شاشة تفاصيل الإعلان دون إعادة تحميل الصفحة
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AdDet(ad: _adsController.adDetails.value!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'فشل في تحميل الإعلان: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("جاري تحميل الإعلان، أنتظر قليلاً..."),
            ] else if (_error != null) ...[
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAd,
                child: Text('إعادة المحاولة'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}