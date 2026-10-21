import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/duration_extensions.dart';
import '../../domain/repository/editor_repository.dart';

/// Full-screen-ish modal shown while exporting. Mirrors Canva's export
/// treatment: circular progress with percentage, estimated remaining time,
/// and cancel/retry actions depending on [progress.status].
class ExportProgressDialog extends StatelessWidget {
  const ExportProgressDialog({
    super.key,
    required this.progress,
    required this.onCancel,
    required this.onRetry,
    required this.onDone,
  });

  final ExportProgress progress;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress.status == ExportStatus.failed)
              _FailedState(message: progress.errorMessage, onRetry: onRetry)
            else if (progress.status == ExportStatus.success)
              _SuccessState(onDone: onDone)
            else
              _RenderingState(progress: progress, onCancel: onCancel),
          ],
        ),
      ),
    );
  }
}

class _RenderingState extends StatelessWidget {
  const _RenderingState({required this.progress, required this.onCancel});
  final ExportProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.progress,
                strokeWidth: 6,
                backgroundColor: AppColors.timelineTrack,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
              Text('${(progress.progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space20),
        Text(AppStrings.exportingTitle,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          progress.estimatedRemaining != null
              ? '${progress.estimatedRemaining!.toTimecode()} remaining'
              : AppStrings.exportingSubtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: AppDimens.space20),
        TextButton(onPressed: onCancel, child: Text(AppStrings.exportCancel)),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 72),
        const SizedBox(height: AppDimens.space16),
        Text(AppStrings.exportDone, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: AppDimens.space20),
        ElevatedButton(onPressed: onDone, child: const Text('Continue')),
      ],
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState({required this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_rounded, color: AppColors.error, size: 72),
        const SizedBox(height: AppDimens.space16),
        Text(AppStrings.exportFailed, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(message!, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
        ],
        const SizedBox(height: AppDimens.space20),
        ElevatedButton(onPressed: onRetry, child: Text(AppStrings.exportRetry)),
      ],
    );
  }
}
