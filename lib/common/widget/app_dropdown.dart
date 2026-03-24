import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Shared color helpers ─────────────────────────────────────────────────────

const _kDropBg = Color(0xFF1A1F3A);

// ═════════════════════════════════════════════════════════════════════════════
//  AppDropdown  –  single-select, searchable, clearable
// ═════════════════════════════════════════════════════════════════════════════

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
    this.accentColor,
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

  /// Tint color for border, icon, selected text. Defaults to [ColorScheme.primary].
  final Color? accentColor;

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
  bool _isOpen = false;

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
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    final bgColor = isDark ? _kDropBg : Colors.white;
    final neutralBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.grey.shade200;

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
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
            ],
            ValueListenableBuilder<T?>(
              valueListenable: _valueNotifier,
              builder: (context, currentValue, _) {
                final hasValue = currentValue != null;
                final borderColor = field.hasError
                    ? theme.colorScheme.error
                    : _isOpen
                        ? accent
                        : hasValue
                            ? accent.withValues(alpha: 0.50)
                            : neutralBorder;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: _isOpen || hasValue ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isOpen
                            ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
                            : Colors.black
                                .withValues(alpha: isDark ? 0.28 : 0.06),
                        blurRadius: _isOpen ? 16 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton2<T>(
                          isExpanded: widget.isExpanded,
                          valueListenable: _valueNotifier,
                          onMenuStateChange: (isOpen) =>
                              setState(() => _isOpen = isOpen),
                          hint: Row(
                            children: [
                              if (widget.prefixIcon != null) ...[
                                Icon(widget.prefixIcon,
                                    size: 17,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  widget.hint ?? 'Select...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          items: widget.items.map((item) {
                            return DropdownItem<T>(
                              value: item,
                              child: _DropdownItemRow(
                                label: widget.displayBuilder(item),
                                accent: accent,
                                isSelected: item == currentValue,
                                isDark: isDark,
                              ),
                            );
                          }).toList(),
                          selectedItemBuilder: (context) {
                            return widget.items.map((item) {
                              return Row(
                                children: [
                                  if (widget.prefixIcon != null) ...[
                                    Icon(widget.prefixIcon,
                                        size: 17, color: accent),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      widget.displayBuilder(item),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            _valueNotifier.value = v;
                            field.didChange(v);
                            widget.onChanged(v);
                          },
                          buttonStyleData: ButtonStyleData(
                            padding: EdgeInsets.only(
                              left: 14,
                              right: widget.clearable && hasValue ? 4 : 10,
                            ),
                            height: 50,
                          ),
                          iconStyleData: IconStyleData(
                            icon: widget.clearable && hasValue
                                ? GestureDetector(
                                    onTap: () {
                                      _valueNotifier.value = null;
                                      field.didChange(null);
                                      widget.onChanged(null);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.close_rounded,
                                          size: 17,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey.shade400),
                                    ),
                                  )
                                : AnimatedRotation(
                                    turns: _isOpen ? 0.5 : 0,
                                    duration:
                                        const Duration(milliseconds: 220),
                                    curve: Curves.easeInOut,
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 22,
                                      color: _isOpen
                                          ? accent
                                          : (isDark
                                              ? Colors.white30
                                              : Colors.grey.shade400),
                                    ),
                                  ),
                            iconSize: 22,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: widget.maxHeight,
                            offset: const Offset(0, -4),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.22)),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(
                                      alpha: isDark ? 0.18 : 0.10),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: isDark ? 0.50 : 0.10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            scrollbarTheme: ScrollbarThemeData(
                              radius: const Radius.circular(4),
                              thumbColor: WidgetStatePropertyAll(
                                  accent.withValues(alpha: 0.4)),
                            ),
                          ),
                          menuItemStyleData: MenuItemStyleData(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            selectedMenuItemBuilder: (ctx, child) =>
                                Container(
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: child,
                            ),
                          ),
                          dropdownSearchData: widget.searchable
                              ? DropdownSearchData<T>(
                                  searchController: _searchController,
                                  searchBarWidgetHeight: 56,
                                  searchBarWidget: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 10, 10, 4),
                                    child: TextField(
                                      controller: _searchController,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                        hintText: widget.searchHint,
                                        hintStyle: TextStyle(
                                          fontSize: 13.5,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey.shade400,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          size: 18,
                                          color: accent.withValues(alpha: 0.7),
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: accent
                                                  .withValues(alpha: 0.20)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: accent
                                                  .withValues(alpha: 0.20)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: accent, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                  searchMatchFn: (item, searchValue) {
                                    final text = widget
                                        .displayBuilder(item.value as T);
                                    return text
                                        .toLowerCase()
                                        .contains(searchValue.toLowerCase());
                                  },
                                )
                              : null,
                        ),
                      ),
                      // Left accent strip when a value is selected
                      if (hasValue)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (field.hasError) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 13, color: theme.colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      field.errorText!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Dropdown item row ────────────────────────────────────────────────────────

class _DropdownItemRow extends StatelessWidget {
  const _DropdownItemRow({
    required this.label,
    required this.accent,
    required this.isSelected,
    required this.isDark,
  });

  final String label;
  final Color accent;
  final bool isSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? accent : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? accent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.grey.shade300),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? accent
                  : (isDark ? Colors.white70 : Colors.grey.shade800),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 6),
          Icon(Icons.check_rounded, size: 15, color: accent),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  AppMultiDropdown  –  multi-select with inline panel
// ═════════════════════════════════════════════════════════════════════════════

class AppMultiDropdown<T> extends StatefulWidget {
  const AppMultiDropdown({
    super.key,
    required this.items,
    required this.displayBuilder,
    required this.onChanged,
    this.selectedItems = const [],
    this.hint = 'Select options...',
    this.label,
    this.prefixIcon,
    this.accentColor,
    this.searchable = true,
    this.searchHint = 'Search...',
    this.maxShownChips = 2,
    this.maxListHeight = 280,
    this.validator,
  });

  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) displayBuilder;
  final void Function(List<T>) onChanged;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Color? accentColor;
  final bool searchable;
  final String searchHint;
  final int maxShownChips;
  final double maxListHeight;
  final String? Function(List<T>)? validator;

  @override
  State<AppMultiDropdown<T>> createState() => _AppMultiDropdownState<T>();
}

class _AppMultiDropdownState<T> extends State<AppMultiDropdown<T>>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late List<T> _selected;
  final _searchCtrl = TextEditingController();
  String _query = '';
  late AnimationController _chevronCtrl;
  bool _hasError = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.selectedItems);
    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didUpdateWidget(covariant AppMultiDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItems != widget.selectedItems) {
      _selected = List<T>.from(widget.selectedItems);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _chevronCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _chevronCtrl.forward();
      } else {
        _chevronCtrl.reverse();
        _searchCtrl.clear();
        _query = '';
      }
    });
  }

  void _toggleItem(T item) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected.contains(item)
          ? _selected.remove(item)
          : _selected.add(item);
    });
    final err = widget.validator?.call(List<T>.from(_selected));
    setState(() {
      _hasError = err != null;
      _errorText = err;
    });
    widget.onChanged(List<T>.from(_selected));
  }

  void _selectAll(List<T> filtered) {
    HapticFeedback.lightImpact();
    setState(() {
      for (final item in filtered) {
        if (!_selected.contains(item)) _selected.add(item);
      }
    });
    widget.onChanged(List<T>.from(_selected));
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() => _selected.clear());
    widget.onChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final neutralBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.grey.shade200;
    final bgColor = isDark ? _kDropBg : Colors.white;
    final hasSelection = _selected.isNotEmpty;

    final borderColor = _hasError
        ? Theme.of(context).colorScheme.error
        : _isOpen
            ? accent
            : hasSelection
                ? accent.withValues(alpha: 0.50)
                : neutralBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
        ],

        // ── Trigger button ────────────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: _isOpen
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    )
                  : BorderRadius.circular(14),
              border: Border.all(
                  color: borderColor,
                  width: _isOpen || hasSelection ? 1.5 : 1),
              boxShadow: [
                BoxShadow(
                  color: _isOpen
                      ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
                      : Colors.black
                          .withValues(alpha: isDark ? 0.28 : 0.06),
                  blurRadius: _isOpen ? 16 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 44, 10),
                  child: Row(
                    children: [
                      if (widget.prefixIcon != null) ...[
                        Icon(widget.prefixIcon,
                            size: 17,
                            color: hasSelection || _isOpen
                                ? accent
                                : (isDark
                                    ? Colors.white30
                                    : Colors.grey.shade400)),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: hasSelection
                            ? _buildChips(accent, isDark)
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  widget.hint,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: _isOpen
                              ? accent
                              : (isDark
                                  ? Colors.white30
                                  : Colors.grey.shade400)),
                    ),
                  ),
                ),
                // Left accent strip
                if (hasSelection)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: _isOpen
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(14))
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Expandable panel ──────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          child: _isOpen
              ? _buildPanel(accent, isDark, bgColor, borderColor)
              : const SizedBox(width: double.infinity, height: 0),
        ),

        // ── Error text ────────────────────────────────────────────────
        if (_hasError && _errorText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 13,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 4),
                Text(_errorText!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.error,
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChips(Color accent, bool isDark) {
    final visibleCount =
        _selected.length.clamp(0, widget.maxShownChips);
    final visible = _selected.sublist(0, visibleCount);
    final overflow = _selected.length - visibleCount;

    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        ...visible.map((item) => _MultiChip(
              label: widget.displayBuilder(item),
              accent: accent,
              isDark: isDark,
              onRemove: () => _toggleItem(item),
            )),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: accent.withValues(alpha: 0.30), width: 1),
            ),
            child: Text(
              '+$overflow',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPanel(
      Color accent, bool isDark, Color bgColor, Color borderColor) {
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where((item) => widget
                .displayBuilder(item)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();

    final allFilteredSelected =
        filtered.every((item) => _selected.contains(item));

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxListHeight),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(
          left: BorderSide(color: borderColor, width: 1.5),
          right: BorderSide(color: borderColor, width: 1.5),
          bottom: BorderSide(color: borderColor, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: accent.withValues(alpha: 0.15),
          ),

          // Search bar
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  hintText: widget.searchHint,
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 17,
                      color: accent.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: accent.withValues(alpha: 0.20)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: accent.withValues(alpha: 0.20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: accent, width: 1.5),
                  ),
                ),
              ),
            ),

          // Select All / Clear row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: allFilteredSelected
                      ? null
                      : () => _selectAll(filtered),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: allFilteredSelected
                              ? accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: allFilteredSelected
                                ? accent
                                : (isDark
                                    ? Colors.white30
                                    : Colors.grey.shade400),
                            width: 1.5,
                          ),
                        ),
                        child: allFilteredSelected
                            ? const Icon(Icons.check_rounded,
                                size: 10, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Select All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: allFilteredSelected
                              ? accent
                              : (isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B)
                            .withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B)
                              .withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded,
                              size: 11, color: Color(0xFFFF6B6B)),
                          const SizedBox(width: 3),
                          Text(
                            'Clear (${_selected.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color:
                isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
          ),

          // Items list
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final isSel = _selected.contains(item);
                      return _MultiCheckItem(
                        label: widget.displayBuilder(item),
                        isSelected: isSel,
                        accent: accent,
                        isDark: isDark,
                        index: i,
                        onTap: () => _toggleItem(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Multi chip ───────────────────────────────────────────────────────────────

class _MultiChip extends StatelessWidget {
  const _MultiChip({
    required this.label,
    required this.accent,
    required this.isDark,
    required this.onRemove,
  });

  final String label;
  final Color accent;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.32), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 9, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Multi check item ─────────────────────────────────────────────────────────

class _MultiCheckItem extends StatefulWidget {
  const _MultiCheckItem({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  @override
  State<_MultiCheckItem> createState() => _MultiCheckItemState();
}

class _MultiCheckItemState extends State<_MultiCheckItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 28), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.accent.withValues(alpha: widget.isDark ? 0.16 : 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? widget.accent.withValues(alpha: 0.30)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color:
                        widget.isSelected ? widget.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: widget.isSelected
                          ? widget.accent
                          : (widget.isDark
                              ? Colors.white30
                              : Colors.grey.shade400),
                      width: 1.5,
                    ),
                  ),
                  child: widget.isSelected
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isSelected
                          ? widget.accent
                          : (widget.isDark
                              ? Colors.white70
                              : Colors.grey.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}