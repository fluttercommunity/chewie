import 'dart:convert';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class TranslationsLoader extends AssetLoader {
  const TranslationsLoader({this.packageName});

  final String? packageName;

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) =>
      _getMapLocales(locale);

  Future<Map<String, dynamic>> _getMapLocales(Locale locale) async {
    String getPath({Locale locale = const Locale('ru')}) =>
        '${packageName != null ? 'packages/$packageName/' : ''}assets/locales/$locale.json';

    try {
      return jsonDecode(
        await rootBundle.loadString(
          getPath(locale: locale),
        ),
      ) as Map<String, dynamic>;
    } catch (e) {
      return jsonDecode(
        await rootBundle.loadString(getPath()),
      ) as Map<String, dynamic>;
    }
  }
}
