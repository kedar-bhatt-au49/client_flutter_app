/// ---------------------------------------------------------------------------
/// Searchable selector bottom sheet.
///
/// Shows a top search bar, a "Select <title>" header with X close button,
/// and a scrollable, filterable list.  Used for all searchable dropdowns
/// (panel name, inverter name, wattage, module count, GST profiles, etc.).
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SearchableSelectorSheet<T> extends StatefulWidget {
  final String title;
  final String hint;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final String Function(T item)? sublabelBuilder;
  final T? initialValue;
  final void Function(T selected) onSelected;
  final bool showSearch;
  final double? maxHeight;

  const SearchableSelectorSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    this.sublabelBuilder,
    this.initialValue,
    required this.onSelected,
    this.showSearch = true,
    this.maxHeight,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String hint,
    required List<T> items,
    required String Function(T item) labelBuilder,
    String Function(T item)? sublabelBuilder,
    T? initialValue,
    bool showSearch = true,
    double? maxHeight,
    required void Function(T selected) onSelected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchableSelectorSheet<T>(
        title: title,
        hint: hint,
        items: items,
        labelBuilder: labelBuilder,
        sublabelBuilder: sublabelBuilder,
        initialValue: initialValue,
        showSearch: showSearch,
        maxHeight: maxHeight,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<SearchableSelectorSheet<T>> createState() =>
      _SearchableSelectorSheetState<T>();
}

class _SearchableSelectorSheetState<T> extends State<SearchableSelectorSheet<T>> {
  final _searchCtrl = TextEditingController();
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<T>.from(widget.items);
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) {
      _filtered = List<T>.from(widget.items);
    } else {
      _filtered = widget.items.where((item) {
        final label = widget.labelBuilder(item).toLowerCase();
        final sub = widget.sublabelBuilder != null
            ? widget.sublabelBuilder!(item).toLowerCase()
            : '';
        return label.contains(q) || sub.contains(q);
      }).toList();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = widget.maxHeight ??
        (MediaQuery.of(context).size.height * 0.6).clamp(300.0, 420.0);

    return Container(
      decoration: const BoxDecoration(
        color: GSColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: GSColors.ink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header: title + close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select ${widget.title}',
                  style: GSTextStyles.headlineSmall
                      .copyWith(color: GSColors.navy900),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: GSColors.ink.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18,
                        color: GSColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search bar
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GSTextStyles.bodyMedium
                      .copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: GSColors.ink),
                  filled: true,
                  fillColor: GSColors.pageBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                style: GSTextStyles.bodyMedium,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
              ),
            ),
          // Results list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No ${widget.title.toLowerCase()} found',
                      style: GSTextStyles.bodyMedium
                          .copyWith(color: GSColors.ink.withValues(alpha: 0.5)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: GSColors.ink,
                        indent: 56),
                    itemBuilder: (context, i) {
                      final item = _filtered[i];
                      final selected = item == widget.initialValue;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: (selected
                                  ? GSColors.teal500
                                  : GSColors.navy500)
                              .withValues(alpha: 0.12),
                          child: Icon(Icons.check_circle,
                              size: 18,
                              color: selected
                                  ? GSColors.teal500
                                  : GSColors.navy500.withValues(alpha: 0.4)),
                        ),
                        title: Text(
                          widget.labelBuilder(item),
                          style: GSTextStyles.bodyMediumSemiBold.copyWith(
                            color: selected
                                ? GSColors.teal500
                                : GSColors.navy900,
                          ),
                        ),
                        subtitle: widget.sublabelBuilder != null
                            ? Text(
                                widget.sublabelBuilder!(item),
                                style: GSTextStyles.bodySmall
                                    .copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
                              )
                            : null,
                        trailing: selected
                            ? const Icon(Icons.check,
                                color: GSColors.teal500, size: 20)
                            : null,
                        onTap: () {
                          widget.onSelected(item);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
