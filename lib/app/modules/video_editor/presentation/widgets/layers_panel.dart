import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/layer_model.dart';

/// Layer panel shared by the Text and Stickers tabs — [layerType]
/// determines which "add" action is offered and which existing layers of
/// that type are listed for editing/removal.
class LayersPanel extends StatelessWidget {
  const LayersPanel({
    super.key,
    required this.layerType,
    required this.layers,
    required this.onAdd,
    required this.onRemove,
    required this.onAnimationChanged,
  });

  final LayerType layerType;
  final List<LayerModel> layers;
  final VoidCallback onAdd;
  final ValueChanged<LayerModel> onRemove;
  final void Function(LayerModel layer, LayerAnimationType type) onAnimationChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = layers.where((l) => l.type == layerType).toList();

    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: Icon(layerType == LayerType.text ? Icons.text_fields_rounded : Icons.emoji_emotions_rounded),
            label: Text(layerType == LayerType.text ? 'Add text' : 'Add sticker'),
          ),
          const SizedBox(height: AppDimens.space12),
          if (filtered.isEmpty)
            Text(
              'No layers yet — tap add to place one on the canvas',
              style: context.textTheme.bodySmall
                  ?.copyWith(color: context.colors.onSurface.withValues(alpha: 0.6)),
            )
          else
            ...filtered.map(
              (layer) => Card(
                child: ListTile(
                  dense: true,
                  title: Text(layer.text ?? layer.assetPath ?? layer.id),
                  subtitle: DropdownButton<LayerAnimationType>(
                    value: layer.animation.type,
                    isDense: true,
                    items: LayerAnimationType.values
                        .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onAnimationChanged(layer, value);
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => onRemove(layer),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
