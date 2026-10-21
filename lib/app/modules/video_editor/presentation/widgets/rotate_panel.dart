import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/clip_model.dart';

class RotatePanel extends StatelessWidget {
  const RotatePanel({
    super.key,
    required this.clip,
    required this.onRotate90,
    required this.onCustomRotation,
    required this.onFlipHorizontal,
    required this.onFlipVertical,
  });

  final ClipModel clip;
  final VoidCallback onRotate90;
  final ValueChanged<double> onCustomRotation;
  final VoidCallback onFlipHorizontal;
  final VoidCallback onFlipVertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActionChip(
                icon: Icons.rotate_90_degrees_ccw_rounded,
                label: 'Rotate 90°',
                onTap: onRotate90,
              ),
              const SizedBox(width: AppDimens.space12),
              _ActionChip(
                icon: Icons.flip_rounded,
                label: 'Flip H',
                onTap: onFlipHorizontal,
              ),
              const SizedBox(width: AppDimens.space12),
              _ActionChip(
                icon: Icons.flip_camera_android_rounded,
                label: 'Flip V',
                onTap: onFlipVertical,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space20),
          Text('Custom rotation', style: context.textTheme.labelLarge),
          Slider(
            value: clip.customRotationDegrees,
            min: -45,
            max: 45,
            divisions: 90,
            label: '${clip.customRotationDegrees.round()}°',
            onChanged: onCustomRotation,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
