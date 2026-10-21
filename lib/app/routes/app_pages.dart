import 'package:get/get.dart';
import '../modules/login/login_screen.dart';
import '../modules/home/home_screen.dart';
import '../modules/newslist/newslist_screen.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/create_news/create_news_screen.dart';
import '../modules/media_gallery/media_gallery_screen.dart';
import '../modules/users/user_profile_news_screen.dart';
// import '../modules/html_editor_demo/html_editor_demo_screen.dart';
import '../modules/video_editor/presentation/views/editor_view.dart';
// import '../modules/image_editor/image_editor_screen.dart';
import '../modules/video_editor/presentation/bindings/video_editor_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const String initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
    GetPage(name: AppRoutes.dashboard, page: () => const NewslistScreen()),
    GetPage(name: AppRoutes.createNews, page: () => const CreateNewsScreen()),
    GetPage(
      name: AppRoutes.mediaGallery,
      page: () => const MediaGalleryScreen(),
    ),
    GetPage(
      name: AppRoutes.userProfileNews,
      page: () => const UserProfileNewsScreen(),
    ),
    GetPage(
      name: AppRoutes.videoEditor,
      page: () => const EditorView(),
      binding: VideoEditorBinding(),
    ),
  ];
}
