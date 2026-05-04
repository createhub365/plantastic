import 'package:flutter/material.dart';

import '../data/world_flowers_catalog.dart';
import '../theme/app_theme.dart';

typedef WorldFlowerChosen = void Function(WorldFlower flower);

/// Type-to-search flower names; catalogue pick or fully custom typed text.
class WorldFlowerTileField extends StatelessWidget {
  const WorldFlowerTileField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.theme,
    this.onCatalogFlowerChosen,
    this.dense = true,

    /// Uses [theme.inputDecorationTheme] (labels, borders) like [TextFormField].
    this.formStyle = false,
    this.labelText,
    this.hintText,
    this.suggestionsMaxWidth = 260,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ThemeData theme;

  /// When user selects a catalogue row — e.g. fill product subtitle from cover tile.
  final WorldFlowerChosen? onCatalogFlowerChosen;
  final bool dense;
  final bool formStyle;
  final String? labelText;
  final String? hintText;
  final double suggestionsMaxWidth;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<WorldFlower>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (w) => w.name,
      optionsBuilder: (value) => filterWorldFlowers(value.text, maxResults: 12),
      onSelected: (w) {
        controller.text = w.name;
        onCatalogFlowerChosen?.call(w);
        focusNode.unfocus();
      },
      fieldViewBuilder: (ctx, ctl, fn, _) {
        final InputDecoration dec;
        if (formStyle) {
          dec = InputDecoration(
            labelText: labelText,
            hintText:
                hintText ?? 'Type to search flowers or enter a custom name',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
            ),
          ).applyDefaults(theme.inputDecorationTheme);
        } else {
          dec = InputDecoration(
            isDense: dense,
            contentPadding: dense
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                : null,
            hintText: hintText ?? 'Type flower…',
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white38,
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
              ),
            ),
          );
        }
        return TextField(
          controller: ctl,
          focusNode: fn,
          style: formStyle
              ? theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary)
              : theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          decoration: dec,
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        final opts = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: dense ? 200 : 280,
                maxWidth: suggestionsMaxWidth,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opts.length,
                itemBuilder: (_, i) {
                  final o = opts[i];
                  return ListTile(
                    dense: dense,
                    title: Text(
                      o.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      o.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () => onSelected(o),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
