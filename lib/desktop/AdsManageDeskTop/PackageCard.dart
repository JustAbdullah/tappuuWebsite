

import 'package:flutter/material.dart';

import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/PremiumPackage.dart';

class PackageCard extends StatelessWidget {
  final PremiumPackage pkg;
  final bool isDark;
  final String priceText;
  final bool isSelected;
  final VoidCallback onSelect;

  const PackageCard({
    Key? key,
    required this.pkg,
    required this.isDark,
    required this.priceText,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : Colors.grey.withOpacity(0.25);
    final bg = isSelected ? AppColors.primary.withOpacity(0.06) : (isDark ? Color(0xFF141722) : Colors.white);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم الباقة
              Text(pkg.name ?? '', style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w800,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textPrimary(isDark),
              ), maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 12),

              // السعر والمدة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(priceText, style: TextStyle(
                    fontSize: AppTextStyles.xlarge,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  )),
                  Text('${pkg.durationDays ?? '-'} يوم', style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textSecondary(isDark),
                  )),
                ],
              ),
              SizedBox(height: 12),

              // وصف الباقة إن وجد
              if (pkg.description != null && pkg.description!.isNotEmpty)
                Text(pkg.description!, style: TextStyle(
                  fontSize: AppTextStyles.small,
                  color: AppColors.textSecondary(isDark),
                ), maxLines: 3, overflow: TextOverflow.ellipsis),
              
              Spacer(),

              // زر الاختيار
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                    foregroundColor: isSelected ? Colors.white : AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: Text(isSelected ? 'محدد' : 'اختيار', style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w700,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
