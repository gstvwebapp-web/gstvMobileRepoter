import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/language_switcher.dart';
import '../dashboard/dashboard_screen.dart';
import '../newslist/newslist_screen.dart';
import '../media_gallery/media_gallery_screen.dart';
import '../users/users_screen.dart';
import '../help/help_screen.dart';
import 'home_controller.dart';
import '../../core/constants/global_variables.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());

    // Handle navigation arguments (e.g. returning from create-news)
    // Must run only once and after the build phase to avoid triggering
    // reactive rebuilds during widget construction.
    final args = Get.arguments;
    if (args is Map && args['menu'] == 'news') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.selectedMenu.value = HomeMenuItem.news;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: _buildAppBar(context, controller),
      drawer: _buildDrawer(context, controller),
      body: SafeArea(
        top: false,
        child: Obx(() => _buildBody(controller.selectedMenu.value)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    HomeController controller,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 60,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu, color: AppColors.primary, size: 20),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Menu'.tr,
        ),
      ),
      title: _buildLogo(),
      actions: [
        // Language Switcher
        const LanguageSwitcher(
          showLabel: false,
          isCompact: true,
        ).paddingOnly(right: 0),
        // Help
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          onPressed: () {
            Get.to(
              () => const HelpScreen(url: 'https://www.gstv.in/backend2/help'),
            );
          },
          tooltip: 'Help'.tr,
        ).paddingOnly(right: 0),
        // Logout
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 18,
            ),
          ),
          onPressed: controller.logout,
          tooltip: 'logout'.tr,
        ).paddingOnly(right: 8),
      ],
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/app_icon/ic_logo_horizontal.png',
      height: 36,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('GS'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.logoGS,
            ),
          ),
          Text('TV'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.logoTV,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, HomeController controller) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final String roleID = GlobalVariables.roleID;
    final bool isRestrictedRole = roleID == '6' || roleID == '7';

    return Drawer(
      width: 270,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 20),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryLinearGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(),
                const SizedBox(height: 8),
                Text('Admin Panel'.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.dashboard,
                    Icons.dashboard_outlined,
                    'Dashboard',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.categories,
                    Icons.category_outlined,
                    'Categories',
                  ),
                _menuItem(
                  controller,
                  HomeMenuItem.news,
                  Icons.article_outlined,
                  'News',
                ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.users,
                    Icons.people_outlined,
                    'Users Listing',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.editorListing,
                    Icons.edit_note_outlined,
                    'Editor Listing',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.changePassword,
                    Icons.lock_outline,
                    'Change Password',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.poll,
                    Icons.poll_outlined,
                    'Poll',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.mediaGallery,
                    Icons.photo_library_outlined,
                    'Media Gallery',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.webStories,
                    Icons.auto_stories_outlined,
                    'Web Stories',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.frontendUsers,
                    Icons.person_outline,
                    'Frontend Users',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.feedbackList,
                    Icons.feedback_outlined,
                    'Feedback List',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.epaperCategories,
                    Icons.folder_outlined,
                    'Epaper Categories',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.epaper,
                    Icons.newspaper_outlined,
                    'Epaper',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.newsFlash,
                    Icons.flash_on_outlined,
                    'News Flash',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.imJournalist,
                    Icons.badge_outlined,
                    'I M Journalist',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.campusCorner,
                    Icons.school_outlined,
                    'Campus Corner',
                  ),
                if (!isRestrictedRole)
                  _menuItem(
                    controller,
                    HomeMenuItem.magazineReview,
                    Icons.menu_book_outlined,
                    'Magazine Review',
                  ),
              ],
            ),
          ),
          // Logout at bottom
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 22,
            ),
            title: Text(
              'logout'.tr,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            onTap: controller.logout,
          ),
          SizedBox(height: bottomPadding + 8),
        ],
      ),
    );
  }

  Widget _menuItem(
    HomeController controller,
    HomeMenuItem item,
    IconData icon,
    String label,
  ) {
    return Obx(() {
      final isSelected = controller.selectedMenu.value == item;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: isSelected
              ? AppColors.primaryWithOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            dense: true,
            leading: Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            trailing: isSelected
                ? Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                : null,
            onTap: () => controller.selectMenu(item),
          ),
        ),
      );
    });
  }

  Widget _buildBody(HomeMenuItem menu) {
    switch (menu) {
      case HomeMenuItem.dashboard:
        return const DashboardScreen();
      case HomeMenuItem.news:
        return const _NewsBody();
      case HomeMenuItem.mediaGallery:
        return const MediaGalleryScreen();
      case HomeMenuItem.categories:
        return const _ComingSoonBody(label: 'Categories');
      case HomeMenuItem.users:
        return const UsersScreen();
      case HomeMenuItem.editorListing:
        return const _ComingSoonBody(label: 'Editor Listing');
      case HomeMenuItem.changePassword:
        return const _ComingSoonBody(label: 'Change Password');
      case HomeMenuItem.poll:
        return const _ComingSoonBody(label: 'Poll');
      case HomeMenuItem.webStories:
        return const _ComingSoonBody(label: 'Web Stories');
      case HomeMenuItem.frontendUsers:
        return const _ComingSoonBody(label: 'Frontend Users');
      case HomeMenuItem.feedbackList:
        return const _ComingSoonBody(label: 'Feedback List');
      case HomeMenuItem.epaperCategories:
        return const _ComingSoonBody(label: 'Epaper Categories');
      case HomeMenuItem.epaper:
        return const _ComingSoonBody(label: 'Epaper');
      case HomeMenuItem.newsFlash:
        return const _ComingSoonBody(label: 'News Flash');
      case HomeMenuItem.imJournalist:
        return const _ComingSoonBody(label: 'I M Journalist');
      case HomeMenuItem.campusCorner:
        return const _ComingSoonBody(label: 'Campus Corner');
      case HomeMenuItem.magazineReview:
        return const _ComingSoonBody(label: 'Magazine Review');
    }
  }
}

// News body — embeds NewslistScreen content without its own appbar
class _NewsBody extends StatelessWidget {
  const _NewsBody();

  @override
  Widget build(BuildContext context) {
    return const NewslistScreen();
  }
}

class _ComingSoonBody extends StatelessWidget {
  final String label;
  const _ComingSoonBody({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text('Coming Soon'.tr,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
