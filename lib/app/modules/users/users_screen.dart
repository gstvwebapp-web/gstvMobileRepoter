import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_list_model.dart';
import 'users_controller.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with AutomaticKeepAliveClientMixin {
  late final UsersController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(UsersController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search users...'.tr,
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.primary),
                suffixIcon: Obx(() => controller.searchText.value.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          controller.searchController.clear();
                          controller.searchText.value = '';
                          controller.loadUsers(isRefresh: true);
                        },
                        child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                      )
                    : const SizedBox.shrink()),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value && controller.usersList.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.usersList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(controller.errorMessage.value,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.loadUsers(isRefresh: true),
                child: Text('Retry'.tr),
              ),
            ],
          ),
        );
      }

      if (controller.usersList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('No users found'.tr,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        );
      }

      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => controller.loadUsers(isRefresh: true),
              child: ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.zero,
                itemCount: controller.usersList.length +
                    (controller.isLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.usersList.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                    );
                  }
                  return _UserRow(user: controller.usersList[index]);
                },
              ),
            ),
          ),
          _buildFooter(),
        ],
      );
    });
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Obx(() => Row(
            children: [
              Text(
                'Showing ${controller.usersList.length} of ${controller.totalUsers.value}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.loadUsers(isRefresh: true),
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text('Refresh'.tr),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          )),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserListModel user;

  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user.status == 'Active';

    return InkWell(
      onTap: () => Get.toNamed(
        '/user-profile-news',
        arguments: {'userId': user.id, 'userName': user.name},
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(user.profileImg),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 5),
                Row(
                  children: [
                     Text(
                  user.role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 61, 150, 209),
                  ),
                ), const SizedBox(width: 15),
                    _CountBadge(label: 'Today'.tr, count: user.todayNewsCount, color: Colors.orange),
                    const SizedBox(width: 6),
                    _CountBadge(label: 'Total'.tr, count: user.totalNewsCount, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
