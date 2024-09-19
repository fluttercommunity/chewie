// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes, avoid_renaming_method_parameters

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> ru = {
  "player": {
    "no_select": "Не выбран",
    "watched": "Просмотрено",
    "settings": {
      "title": "Настройки",
      "quality": "Качество",
      "lang": "Язык",
      "speed": "Скорость",
      "subtitle": "Субтитры",
      "no_subtitle": "Без субтитра",
      "auto": "Автоматический"
    },
    "season": {
      "all_episodes": "Список всех серии",
      "episode": "Серия",
      "and_episode": "Сезон: {}, серия: {}"
    },
    "time": {
      "min": "мин",
      "hour": "час",
      "second": "сек"
    },
    "ending": {
      "next_episode": "Следующая серия начнется через {}",
      "like": "Понравился фильм?"
    }
  }
};
static const Map<String,dynamic> uz = {
  "player": {
    "no_select": "Tanlanmagan",
    "watched": "Ko'rilgan",
    "settings": {
      "title": "Sozlamalar",
      "quality": "Sifat",
      "lang": "Til",
      "speed": "Tezlik",
      "subtitle": "Subtitrlar",
      "no_subtitle": "Subtitr yo'q",
      "auto": "Avtomatik"
    },
    "season": {
      "all_episodes": "Barcha qismlar ro'yxati",
      "episode": "Qism",
      "and_episode": "Mavsum: {}, qism: {}"
    },
    "time": {
      "min": "daqiqa",
      "hour": "soat",
      "second": "sekund"
    },
    "ending": {
      "next_episode": "Keyingi qism {} sekund dan keyin boshlanadi",
      "like": "Film yoqdimi?"
    }
  }
};
static const Map<String, Map<String,dynamic>> mapLocales = {"ru": ru, "uz": uz};
}
