import 'category_model.dart';
import 'user_model.dart';
import 'news_source_model.dart';
import 'voice_model.dart';

export 'voice_model.dart';

class FilterDataModel {
  final List<CategoryModel> categories;
  final List<CategoryModel> eventCategories;
  final List<UserModel> users;
  final List<NewsSourceModel> newsSources;
  final List<VoiceModel> voiceIdarr;

  /// Convenience getter for voiceIdarr
  List<VoiceModel> get voices => voiceIdarr;

  FilterDataModel({
    required this.categories,
    required this.eventCategories,
    required this.users,
    required this.newsSources,
    List<VoiceModel>? voiceIdarr,
    List<VoiceModel>? voices,
  }) : voiceIdarr = voiceIdarr ?? voices ?? const [];

  factory FilterDataModel.fromJson(Map<String, dynamic> json) {
    return FilterDataModel(
      categories:
          (json['category'] as List<dynamic>?)
              ?.map((item) => CategoryModel.fromJson(item))
              .toList() ??
          [],
      eventCategories:
          (json['eventcategory'] as List<dynamic>?)
              ?.map((item) => CategoryModel.fromJson(item))
              .toList() ??
          [],
      users:
          (json['user'] as List<dynamic>?)
              ?.map((item) => UserModel.fromJson(item))
              .toList() ??
          [],
      newsSources:
          (json['newssourceList'] as List<dynamic>?)
              ?.map((item) => NewsSourceModel.fromJson(item))
              .toList() ??
          [],
      voiceIdarr:
          (json['voiceIdarr'] as List<dynamic>?)
              ?.map((item) => VoiceModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': categories.map((item) => item.toJson()).toList(),
      'eventcategory': eventCategories.map((item) => item.toJson()).toList(),
      'user': users.map((item) => item.toJson()).toList(),
      'newssourceList': newsSources.map((item) => item.toJson()).toList(),
      'voiceIdarr': voiceIdarr.map((item) => item.toJson()).toList(),
    };
  }
}
