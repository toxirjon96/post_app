import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

/// A generic, searchable, clearable dropdown built on [DropdownButton2].
///
/// Usage:
/// ```dart
/// AppDropdown<MyEnum>(
///   items: MyEnum.values,
///   value: _selected,
///   displayBuilder: (e) => e.name,
///   onChanged: (v) => setState(() => _selected = v),
///   hint: 'Select option',
///   searchable: true,
///   clearable: true,
/// )
/// ```
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.displayBuilder,
    required this.onChanged,
    this.value,
    this.hint,
    this.label,
    this.prefixIcon,
    this.searchable = true,
    this.clearable = true,
    this.searchHint = 'Search...',
    this.validator,
    this.isExpanded = true,
    this.maxHeight = 300,
  });

  final List<T> items;
  final T? value;
  final String? hint;
  final String? label;
  final IconData? prefixIcon;
  final String Function(T item) displayBuilder;
  final void Function(T? value) onChanged;
  final bool searchable;
  final bool clearable;
  final String searchHint;
  final String? Function(T?)? validator;
  final bool isExpanded;
  final double maxHeight;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final _searchController = TextEditingController();
  late final ValueNotifier<T?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier(widget.value);
  }

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _valueNotifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _valueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final bgColor = isDark ? const Color(0xFF1A1F3A) : Colors.white;
    final borderColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.3)
        : Colors.grey.shade300;
    final focusBorderColor = colorScheme.primary;

    return FormField<T>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
            ],
            ValueListenableBuilder<T?>(
              valueListenable: _valueNotifier,
              builder: (context, currentValue, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: field.hasError
                          ? colorScheme.error
                          : currentValue != null
                              ? focusBorderColor.withValues(alpha: 0.6)
                              : borderColor,
                      width: currentValue != null ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<T>(
                      isExpanded: widget.isExpanded,
                      valueListenable: _valueNotifier,
                      hint: Row(
                        children: [
                          if (widget.prefixIcon != null) ...[
                            Icon(
                              widget.prefixIcon,
                              size: 18,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              widget.hint ?? 'Select...',
                              style: TextStyle(
                                fontSize: 14,
                                color: !isDark
                                    ? Colors.grey.shade500
                                    : Colors.white38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      items: widget.items.map((item) {
                        return DropdownItem<T>(
                          value: item,
                          child: Text(
                            widget.displayBuilder(item),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.grey.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (context) {
                        return widget.items.map((item) {
                          return Row(
                            children: [
                              if (widget.prefixIcon != null) ...[
                                Icon(
                                  widget.prefixIcon,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  widget.displayBuilder(item),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                      onChanged: (v) {
                        _valueNotifier.value = v;
                        field.didChange(v);
                        widget.onChanged(v);
                      },
                      buttonStyleData: ButtonStyleData(
                        padding: EdgeInsets.only(
                          left: 12,
                          right: widget.clearable && currentValue != null ? 4 : 8,
                        ),
                        height: 48,
                      ),
                      iconStyleData: IconStyleData(
                        icon: widget.clearable && currentValue != null
                            ? GestureDetector(
                                onTap: () {
                                  _valueNotifier.value = null;
                                  field.didChange(null);
                                  widget.onChanged(null);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 22,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500,
                              ),
                        iconSize: 22,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: widget.maxHeight,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        scrollbarTheme: ScrollbarThemeData(
                          radius: const Radius.circular(4),
                          thumbColor: WidgetStatePropertyAll(
                            colorScheme.primary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      menuItemStyleData: MenuItemStyleData(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        selectedMenuItemBuilder: (ctx, child) => Container(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          child: child,
                        ),
                      ),
                      dropdownSearchData: widget.searchable
                          ? DropdownSearchData<T>(
                              searchController: _searchController,
                              searchBarWidgetHeight: 52,
                              searchBarWidget: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    hintText: widget.searchHint,
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withValues(alpha: 0.07)
                                        : Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              searchMatchFn: (item, searchValue) {
                                final text = widget.displayBuilder(item.value as T);
                                return text
                                    .toLowerCase()
                                    .contains(searchValue.toLowerCase());
                              },
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}