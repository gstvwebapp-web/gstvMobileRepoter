class VoiceModel {
  final String voiceId;
  final String name;

  VoiceModel({
    required this.voiceId,
    required this.name,
  });

  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    return VoiceModel(
      voiceId: json['voice_id']?.toString() ?? json['voiceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_id': voiceId,
      'name': name,
    };
  }

  // ignore: non_constant_identifier_names
  String get voice_id => voiceId;
}

typedef VoiceIdModel = VoiceModel;
