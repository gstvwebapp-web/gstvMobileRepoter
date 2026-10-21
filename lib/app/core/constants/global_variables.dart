import '../../data/models/user_model.dart';

class GlobalVariables {
  static UserModel? currentUser;

  static int get userID => currentUser?.userID ?? 0;
  static String get name => currentUser?.name ?? '';
  static String get email => currentUser?.email ?? '';
  static String? get profileImg => currentUser?.profileImg;
  static String get catID => currentUser?.catID ?? '';
  static String get moduleID => currentUser?.moduleID ?? '';
  static String get roleID => currentUser?.roleID ?? '';
  static String get status => currentUser?.status ?? '';
}
