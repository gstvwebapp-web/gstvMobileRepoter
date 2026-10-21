import 'package:flutter_test/flutter_test.dart';
import 'package:gstv_admin/app/data/models/filter_data_model.dart';

void main() {
  test('FilterDataModel parses category, eventcategory, user, newssourceList, and voiceIdarr correctly', () {
    final json = {
      "category": [
        {
          "id": 149,
          "title": "Bulletin",
          "parentID": 0,
          "child_id": null,
          "child_name": null
        },
        {
          "id": 1,
          "title": "Gujarat",
          "parentID": 0,
          "child_id": 141,
          "child_name": "Vav-Tharad"
        }
      ],
      "eventcategory": [],
      "user": [
        {
          "id": 1,
          "name": "GSTV Admin",
          "email": "dineshgstv@gmail.com",
          "email_verified_at": "2023-12-13 00:56:10",
          "password": "hashed_password",
          "profileImg": "profile_1775544623.jpg",
          "catID": "1,13",
          "moduleID": "1,2",
          "roleID": "1",
          "status": "Active",
          "remember_token": "token",
          "created_at": "2023-12-13 00:56:10",
          "updated_at": "2026-04-29 15:41:21"
        }
      ],
      "newssourceList": [
        {
          "id": 1,
          "userID": 1,
          "title": "TV",
          "status": "Active",
          "created_at": "2026-05-11 15:22:10",
          "updated_at": "2026-05-11 15:22:10"
        }
      ],
      "voiceIdarr": [
        {
          "voice_id": "ZsGLGrFQfgRJUAKsDtXX",
          "name": "Krishna"
        },
        {
          "voice_id": "QaSUPbTrjggCEi5sypUG",
          "name": "Pratik"
        }
      ]
    };

    final model = FilterDataModel.fromJson(json);

    expect(model.categories.length, 2);
    expect(model.categories[0].id, 149);
    expect(model.categories[1].childId, 141);
    expect(model.categories[1].childName, "Vav-Tharad");

    expect(model.eventCategories, isEmpty);

    expect(model.users.length, 1);
    expect(model.users[0].userID, 1);
    expect(model.users[0].name, "GSTV Admin");

    expect(model.newsSources.length, 1);
    expect(model.newsSources[0].title, "TV");

    expect(model.voiceIdarr.length, 2);
    expect(model.voiceIdarr[0].voiceId, "ZsGLGrFQfgRJUAKsDtXX");
    expect(model.voiceIdarr[0].voice_id, "ZsGLGrFQfgRJUAKsDtXX");
    expect(model.voiceIdarr[0].name, "Krishna");
    expect(model.voiceIdarr[1].voiceId, "QaSUPbTrjggCEi5sypUG");
    expect(model.voiceIdarr[1].name, "Pratik");

    // Test alias getter voices
    expect(model.voices.length, 2);
    expect(model.voices[0].name, "Krishna");

    // Test toJson
    final serialized = model.toJson();
    expect(serialized['voiceIdarr'], isA<List>());
    expect((serialized['voiceIdarr'] as List).length, 2);
    expect((serialized['voiceIdarr'] as List)[0]['voice_id'], "ZsGLGrFQfgRJUAKsDtXX");
  });
}
