import 'package:flutter/material.dart';

class SlidingButtonRow extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final bool isMultipleSelection;
  final List<int> initialSelection;
  final List<int> locked;
  final Function(List<int> selectedIndices) onSelectionChanged;
  final List<Widget> helpContent;
  final Color? optionTextColor;
  final Color? optionColor;
  final Color? selectTextColor;
  final Color? selectColor;
  final Color? decoColor;
  final bool hasShadow;
  final double parentPadding;

  SlidingButtonRow({
    required this.options,
    this.isMultipleSelection = false,
    this.initialSelection = const [],
    this.locked = const [],
    required this.onSelectionChanged,
    this.helpContent = const [],
    this.optionColor = null,
    this.optionTextColor = null,
    this.selectColor = null,
    this.selectTextColor = null,
    this.decoColor = null,
    this.hasShadow = false,
    this.parentPadding = 28,
  });

  @override
  _SlidingButtonRowState createState() => _SlidingButtonRowState();
}

class _SlidingButtonRowState extends State<SlidingButtonRow> {
  List<int> selectedIndices = [];

  @override
  void initState() {
    super.initState();
    selectedIndices = List.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.optionColor == null ? Theme.of(context).cardColor : widget.optionColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          width: widget.decoColor == null ? 0 : 2,
          color: widget.decoColor == null ? Theme.of(context).splashColor : widget.decoColor!,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.hasShadow
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.transparent,
            offset: Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background layers for single or multiple selection
          if (!widget.isMultipleSelection && selectedIndices.isNotEmpty)
            ..._buildSingleSelectionBackground(context),
          if (widget.isMultipleSelection && selectedIndices.isNotEmpty)
            ..._buildMultipleSelectionBackgrounds(context),
          // Options row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.options.asMap().entries.map((entry) {
              final int index = entry.key;
              final String optionText = entry.value['text'];
              final bool? active = entry.value['active'];

              return Expanded(
                child: Stack(
                  children: [
                    // Selection highlight (background layer)
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selectedIndices.contains(index)
                            ? widget.selectColor == null ? Theme.of(context).primaryColor : widget.selectColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    // Text (foreground layer)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (widget.isMultipleSelection) {
                            if (selectedIndices.contains(index)) {
                              selectedIndices.remove(index);
                            } else {
                              selectedIndices.add(index);
                            }
                          } else {
                            selectedIndices = [index];
                          }
                        });

                        widget.onSelectionChanged(selectedIndices);
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                optionText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedIndices.contains(index)
                                      ? widget.selectTextColor == null ? Theme.of(context).colorScheme.onPrimary : widget.selectTextColor
                                      : widget.optionTextColor == null ? Theme.of(context).colorScheme.onSurface : widget.optionTextColor,
                                  fontWeight: selectedIndices.contains(index)
                                      ? FontWeight.w400
                                      : FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSingleSelectionBackground(BuildContext context) {
    final int selectedIndex = selectedIndices.first;
    final double itemWidth = (MediaQuery.of(context).size.width - widget.parentPadding) / widget.options.length;

    return [
      AnimatedPositioned(
        duration: Duration(milliseconds: 200),
        left: selectedIndex * itemWidth,
        width: itemWidth,
        top: 0,
        bottom: 0,
        child: Container(
          decoration: BoxDecoration(
            color: widget.selectColor == null ? Theme.of(context).primaryColor : widget.selectColor,
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMultipleSelectionBackgrounds(BuildContext context) {
    final double itemWidth = (MediaQuery.of(context).size.width - widget.parentPadding) / widget.options.length;

    // Group adjacent selections
    List<List<int>> groupedSelections = [];
    List<int> currentGroup = [];

    for (int i = 0; i < widget.options.length; i++) {
      if (selectedIndices.contains(i)) {
        currentGroup.add(i);
      } else if (currentGroup.isNotEmpty) {
        groupedSelections.add(List.from(currentGroup));
        currentGroup.clear();
      }
    }

    if (currentGroup.isNotEmpty) {
      groupedSelections.add(List.from(currentGroup));
    }

    return groupedSelections.map((group) {
      final int startIndex = group.first;
      final int endIndex = group.last;
      final double left = startIndex * itemWidth;
      final double width = (endIndex - startIndex + 1) * itemWidth;

      return AnimatedPositioned(
        duration: Duration(milliseconds: 200),
        left: left,
        width: width,
        top: 0,
        bottom: 0,
        child: Container(
          decoration: BoxDecoration(
            color: widget.selectColor == null ? Theme.of(context).primaryColor : widget.selectColor,
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }).toList();
  }
}