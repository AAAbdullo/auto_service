import 'package:flutter/material.dart';

/// Unified search bar with text field and action buttons
class UnifiedSearchBar extends StatefulWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onNearestTap;
  final VoidCallback onFilterTap;
  final bool isNearestMode;
  final bool hasActiveFilters;
  final String? hintText;

  const UnifiedSearchBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onNearestTap,
    required this.onFilterTap,
    this.isNearestMode = false,
    this.hasActiveFilters = false,
    this.hintText,
  });

  @override
  State<UnifiedSearchBar> createState() => _UnifiedSearchBarState();
}

class _UnifiedSearchBarState extends State<UnifiedSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(UnifiedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        _controller.text != widget.searchQuery) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search TextField
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onSearchChanged,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Поиск сервисов...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 22,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                        onPressed: () {
                          _controller.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Nearest Button
          _ActionButton(
            icon: Icons.near_me_rounded,
            isActive: widget.isNearestMode,
            onTap: widget.onNearestTap,
            tooltip: 'Ближайшие',
          ),

          const SizedBox(width: 8),

          // Filter Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ActionButton(
                icon: Icons.tune_rounded,
                isActive: widget.hasActiveFilters,
                onTap: widget.onFilterTap,
                tooltip: 'Фильтры',
              ),
              if (widget.hasActiveFilters)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardColor, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isActive
                  ? null
                  : (isDark ? Colors.grey[800] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
