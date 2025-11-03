import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final String? searchText;
  final String? resultsCount;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    this.onFilterTap,
    this.onChanged,
    this.searchText,
    this.resultsCount,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchText ?? '');
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText) {
      _controller.text = widget.searchText ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;
    final iconColor = theme.colorScheme.primary;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black87;

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.15);

    final borderColor = _isFocused
        ? theme.colorScheme.primary
        : (isDark ? Colors.grey[800]! : Colors.grey[300]!);

    return Row(
      children: [
        // 🔍 Поисковик с анимацией фокуса
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: _isFocused ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: borderColor, width: 1.3),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: iconColor),
                suffixText: widget.resultsCount,
                suffixStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ),

        // ⚙️ Кнопка фильтра (опционально)
        if (widget.onFilterTap != null) ...[
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_alt_outlined, color: iconColor),
              onPressed: widget.onFilterTap,
            ),
          ),
        ],
      ],
    );
  }
}
