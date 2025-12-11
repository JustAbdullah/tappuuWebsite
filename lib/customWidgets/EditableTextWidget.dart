// lib/core/widgets/editable_text_widget.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/editable_text_controller.dart';

class EditableTextWidget extends StatefulWidget {
  final String keyName;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final double? height;
  final double? overrideFontSize; // لو حبيت تزود حجم مؤقت

  const EditableTextWidget({
    Key? key,
    required this.keyName,
    this.textAlign = TextAlign.center,
    this.fontWeight = FontWeight.normal,
    this.height,
    this.overrideFontSize,
  }) : super(key: key);

  @override
  State<EditableTextWidget> createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late final EditableTextController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<EditableTextController>();

    // بعد أول فريم، جرّب تحميل الخط لو العنصر موجود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final item = ctrl.findByKey(widget.keyName);
      if (item != null) {
        ctrl.ensureFontLoaded(item);
      } else {
        if (kDebugMode) {
          debugPrint(
            'EditableTextWidget.initState: NO item for key "${widget.keyName}"',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = ctrl.items;
      final item = ctrl.findByKey(widget.keyName);

      // 1) لسه ما تم جلب بيانات النصوص (الـ List فاضية)
      if (items.isEmpty) {
        return IgnorePointer(
          ignoring: true,
          child: Text(
            'يتم التحميل...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
            style: TextStyle(
              fontFamily: null,
              fontSize: widget.overrideFontSize ?? 10.0,
              fontWeight: widget.fontWeight,
              color: Colors.grey,
              height: widget.height != null && widget.height! > 0
                  ? widget.height
                  : null,
            ),
          ),
        );
      }

      // 2) البيانات موجودة لكن المفتاح هذا غير موجود → واضح أن فيه مشكلة في الـ key
      if (item == null) {
        if (kDebugMode) {
          debugPrint(
            'EditableTextWidget.build: item is NULL for key "${widget.keyName}". '
            'Available keys: ${items.map((e) => e.keyName).toList()}',
          );
        }
        return Text(
          '[${widget.keyName}]',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: widget.textAlign,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        );
      }

      // 3) كل شيء تمام → نعرض النص الفعلي
      final family = ctrl.fontFamilyForKey(item.keyName);

      double fontSize =
          widget.overrideFontSize ?? (item.fontSize?.toDouble() ?? 16.0);
      if (fontSize <= 0) fontSize = 16.0;

      Color color;
      try {
        color = ctrl.hexToColor(item.color);
      } catch (_) {
        color = Colors.black;
      }

      final double? lineHeight =
          widget.height != null && widget.height! > 0 ? widget.height : null;

      return IgnorePointer(
        // مهم في الويب لتفادي كراش hitTest (Invalid argument: 3.62)
        ignoring: true,
        child: Text(
          item.textContent ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: widget.textAlign,
          style: TextStyle(
            fontFamily: family,
            fontSize: fontSize,
            fontWeight: widget.fontWeight,
            color: color,
            height: lineHeight,
          ),
        ),
      );
    });
  }
}
