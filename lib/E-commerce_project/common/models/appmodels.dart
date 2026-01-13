import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/announcmentScreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/cairoscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/cmscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/events.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/golive.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/indicators.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/mapscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/projects.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/reports.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/world.dart';
import 'package:flutter/material.dart';

class MainCatogoryModel {
  final String name;
  final String image;
  final String pageroute;

  MainCatogoryModel({
    required this.name,
    required this.image,
    required this.pageroute,
  });

  factory MainCatogoryModel.fromJson(Map<String, dynamic> json) {
    return MainCatogoryModel(
      name: json['categ_name'] as String? ?? 'Unknown',
      image: json['categ_img'] as String? ?? '',
      pageroute: json['page_route'] as String? ?? '',
    );
  }
}

class StationLoad {
  final String stationName;
  double load;
  final double baseLoad;
  final double minVariation;
  final double maxVariation;

  StationLoad({
    required this.stationName,
    required this.load,
    required this.baseLoad,
    required this.minVariation,
    required this.maxVariation,
  });

  factory StationLoad.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, {double defaultValue = 0.0}) =>
        value is String
            ? double.tryParse(value.replaceAll(',', '.')) ?? defaultValue
            : (value as num?)?.toDouble() ?? defaultValue;

    return StationLoad(
      stationName: json['station_name'] as String? ?? 'محطة غير معروفة',
      load: parseDouble(json['station_load']),
      baseLoad: parseDouble(json['base_load'] ?? json['station_load']),
      minVariation: parseDouble(json['min_variation'], defaultValue: -10.0),
      maxVariation: parseDouble(json['max_variation'], defaultValue: 10.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_name': stationName,
      'station_load': load,
      'base_load': baseLoad,
      'min_variation': minVariation,
      'max_variation': maxVariation,
    };
  }
}

class StationHourlyLoad {
  final String stationName;
  final List<double> loads;

  StationHourlyLoad({
    required this.stationName,
    required this.loads,
  });

  factory StationHourlyLoad.fromJson(Map<String, dynamic> json) {
    List<double> loads = [];
    for (int i = 0; i < 24; i++) {
      String col = 'hour_${i.toString().padLeft(2, '0')}';
      loads.add((json[col] as num?)?.toDouble() ?? 0.0);
    }
    return StationHourlyLoad(
      stationName: json['station_name'] as String? ?? 'محطة غير معروفة',
      loads: loads,
    );
  }
}

class StationDetialesModel {
  final int id;
  final String name;
  final String image;
  final String zone;
  final String load;
  final bool isnew;
  final String cap;
  final String type;
  final String year;

  StationDetialesModel({
    required this.id,
    required this.name,
    required this.image,
    required this.zone,
    required this.load,
    required this.isnew,
    required this.cap,
    required this.type,
    required this.year,
  });

  factory StationDetialesModel.fromJson(Map<String, dynamic> json) {
    return StationDetialesModel(
      id: int.tryParse(json['station_id'].toString()) ?? 0,
      name: json['station_name']?.toString() ?? 'Unknown',
      image: json['station_photo']?.toString() ?? '',
      zone: json['station_zone']?.toString() ?? 'general',
      load: json['station_load']?.toString() ?? 'general',
      isnew: json['station_isnew'] ?? false,
      cap: json['station_cap']?.toString() ?? 'general',
      type: json['station_type']?.toString() ?? 'general',
      year: json['station_year']?.toString() ?? '2000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': id,
      'station_name': name,
      'station_photo': image,
      'station_zone': zone,
      'station_load': load,
      'station_isnew': isnew,
      'station_cap': cap,
      'station_type': type,
      'station_year': year,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationDetialesModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

class WeatherData {
  final String dayName;
  final int maxTemp;
  final int minTemp;
  final String description;
  final String icon;
  final bool isToday;
  final bool isCurrent;
  final DateTime date;

  WeatherData({
    required this.dayName,
    required this.maxTemp,
    required this.minTemp,
    required this.description,
    required this.icon,
    required this.isToday,
    required this.isCurrent,
    required this.date,
  });
}

final List<String> announcmentdepartments = [
  'محطات جهد 220',
  'التحكم الاقليمى',
  'ادارة الازمات',
];
final Map<String, String> announcmentdepartmentToTopic = {
  'محطات جهد 220': 'stations',
  'التحكم الاقليمى': 'crcc',
  'ادارة الازمات': 'cm',
};

final Map<String, Widget Function(BuildContext)> pageRoutes = {
  'الاحداث': (context) => EventsScreen(),
  'الازمات': (context) => Cmscreen(),
  'القاهرة': (context) => Cairoscreen(),
  'مؤشرات': (context) => IndicatorsScreen(),
  'تقارير': (context) => ReportsScreen(),
  'العالم': (context) => WorldScreen(),
  'تعليمات': (context) => AnnouncementScreenDark(),
  'خريطة': (context) => Mapscreen(),
  'مشروعات': (context) => ProjectsScreen(),
  'Go live': (context) => GoliveScreen(),
};

class AnnouncImagesModel {
  final String imageUrl;
  AnnouncImagesModel({required this.imageUrl});
  factory AnnouncImagesModel.fromJson(Map<String, dynamic> json) {
    return AnnouncImagesModel(imageUrl: json['image_path'] as String? ?? '');
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final bool powerCut;
  final double amount;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.powerCut,
    required this.amount,
  });
}

class Report {
  final String name, description, date;

  const Report({
    required this.name,
    required this.description,
    required this.date,
  });
}
