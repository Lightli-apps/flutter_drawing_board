import 'package:flutter/material.dart';

class SelectableColor extends StatelessWidget {
  const SelectableColor({
    required this.color,
    super.key,
    this.isOn = false,
    this.onClick,
    this.onDrag,
    this.borderLeft = false,
    this.borderRight = false,
    this.showIcon = false,
  });

  final Color color;
  final bool isOn;
  final Function()? onClick;
  final Function(DragUpdateDetails)? onDrag;
  final bool borderLeft;
  final bool borderRight;
  final bool showIcon;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: isOn ? 27 : 18,
            width: isOn ? 62 : 15,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF3a3a3a),
              borderRadius: borderLeft && !isOn
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                    )
                  : borderRight && !isOn
                      ? const BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        )
                      : BorderRadius.all(
                          Radius.circular(isOn ? 5 : 0),
                        ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: GestureDetector(
              onTap: onClick,
              onHorizontalDragUpdate: onDrag,
              child: Container(
                width: isOn ? 60 : 14,
                height: isOn ? 25 : 16,
                decoration: BoxDecoration(
                    borderRadius: borderLeft && !isOn
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          )
                        : borderRight && !isOn
                            ? const BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              )
                            : BorderRadius.all(
                                Radius.circular(isOn ? 4 : 0),
                              ),
                    color: color),
              ),
            ),
          ),
        ],
      );
}
