import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/export_settings_model.dart';

/// Bottom sheet for choosing export resolution/fps/codec/container before
/// handing off to [ExportProgressDialog]. Returns the chosen settings, or
/// null if the user dismissed without exporting.
class ExportSettingsSheet extends StatefulWidget {
  const ExportSettingsSheet({super.key, required this.initial});

  final ExportSettingsModel initial;

  static Future<ExportSettingsModel?> show(
    BuildContext context, {
    required ExportSettingsModel initial,
  }) {
    return showModalBottomSheet<ExportSettingsModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExportSettingsSheet(initial: initial),
    );
  }

  @override
  State<ExportSettingsSheet> createState() => _ExportSettingsSheetState();
}

class _ExportSettingsSheetState extends State<ExportSettingsSheet> {
  late ExportSettingsModel _settings = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export settings',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimens.space16),
            Text('Resolution', style: context.textTheme.labelLarge),
            Wrap(
              spacing: AppDimens.space8,
              children: ExportResolution.values.map((res) {
                return ChoiceChip(
                  label: Text(res.label),
                  selected: _settings.resolution == res,
                  onSelected: (_) => setState(() => _settings = _settings.copyWith(resolution: res)),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space16),
            Text('Frame rate', style: context.textTheme.labelLarge),
            Wrap(
              spacing: AppDimens.space8,
              children: [24, 30, 60].map((fps) {
                return ChoiceChip(
                  label: Text('$fps FPS'),
                  selected: _settings.fps == fps,
                  onSelected: (_) => setState(() => _settings = _settings.copyWith(fps: fps)),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space16),
            Text('Codec', style: context.textTheme.labelLarge),
            Wrap(
              spacing: AppDimens.space8,
              children: ExportCodec.values.map((codec) {
                return ChoiceChip(
                  label: Text(codec.name.toUpperCase()),
                  selected: _settings.codec == codec,
                  onSelected: (_) => setState(() => _settings = _settings.copyWith(codec: codec)),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space16),
            Text('Container', style: context.textTheme.labelLarge),
            Wrap(
              spacing: AppDimens.space8,
              children: ExportContainer.values.map((container) {
                return ChoiceChip(
                  label: Text(container.name.toUpperCase()),
                  selected: _settings.container == container,
                  onSelected: (_) =>
                      setState(() => _settings = _settings.copyWith(container: container)),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_settings),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }
}
