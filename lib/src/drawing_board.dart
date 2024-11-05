import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/constants.dart';
import 'drawing_controller.dart';
import 'helper/ex_value_builder.dart';
import 'helper/get_size.dart';
import 'paint_contents/circle.dart';
import 'paint_contents/eraser.dart';
import 'paint_contents/rectangle.dart';
import 'paint_contents/simple_line.dart';
import 'paint_contents/smooth_line.dart';
import 'paint_contents/straight_line.dart';
import 'painter.dart';
import 'widgets/selectable_color.dart';

/// 默认工具栏构建器
typedef DefaultToolsBuilder = List<DefToolItem> Function(
  Type currType,
  DrawingController controller,
);

/// 画板
class DrawingBoard extends StatefulWidget {
  const DrawingBoard({
    super.key,
    required this.background,
    this.controller,
    this.showDefaultActions = false,
    this.showDefaultTools = false,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.clipBehavior = Clip.antiAlias,
    this.defaultToolsBuilder,
    this.boardClipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boardBoundaryMargin,
    this.boardConstrained = false,
    this.maxScale = 20,
    this.minScale = 0.2,
    this.boardPanEnabled = true,
    this.boardScaleEnabled = true,
    this.boardScaleFactor = 200.0,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.transformationController,
    this.alignment = Alignment.topCenter,
  });

  /// 画板背景控件
  final Widget background;

  /// 画板控制器
  final DrawingController? controller;

  /// 显示默认样式的操作栏
  final bool showDefaultActions;

  /// 显示默认样式的工具栏
  final bool showDefaultTools;

  /// 开始拖动
  final Function(PointerDownEvent pde)? onPointerDown;

  /// 正在拖动
  final Function(PointerMoveEvent pme)? onPointerMove;

  /// 结束拖动
  final Function(PointerUpEvent pue)? onPointerUp;

  /// 边缘裁剪方式
  final Clip clipBehavior;

  /// 默认工具栏构建器
  final DefaultToolsBuilder? defaultToolsBuilder;

  /// 缩放板属性
  final Clip boardClipBehavior;
  final PanAxis panAxis;
  final EdgeInsets? boardBoundaryMargin;
  final bool boardConstrained;
  final double maxScale;
  final double minScale;
  final void Function(ScaleEndDetails)? onInteractionEnd;
  final void Function(ScaleStartDetails)? onInteractionStart;
  final void Function(ScaleUpdateDetails)? onInteractionUpdate;
  final bool boardPanEnabled;
  final bool boardScaleEnabled;
  final double boardScaleFactor;
  final TransformationController? transformationController;
  final AlignmentGeometry alignment;

  /// 默认工具项列表
  static List<DefToolItem> defaultTools(Type currType, DrawingController controller) {
    return <DefToolItem>[
      DefToolItem(
          isActive: currType == SimpleLine,
          icon: const Icon(Icons.edit),
          onTap: () => controller.setPaintContent(SimpleLine())),
      DefToolItem(
          isActive: currType == SmoothLine,
          icon: const Icon(Icons.brush),
          onTap: () => controller.setPaintContent(SmoothLine())),
      DefToolItem(
          isActive: currType == StraightLine,
          icon: const Icon(Icons.show_chart),
          onTap: () => controller.setPaintContent(StraightLine())),
      DefToolItem(
          isActive: currType == Rectangle,
          icon: const Icon(CupertinoIcons.stop),
          onTap: () => controller.setPaintContent(Rectangle())),
      DefToolItem(
          isActive: currType == Circle,
          icon: const Icon(CupertinoIcons.circle),
          onTap: () => controller.setPaintContent(Circle())),
      DefToolItem(
          isActive: currType == Eraser,
          icon: const Icon(CupertinoIcons.bandage),
          onTap: () => controller.setPaintContent(Eraser())),
    ];
  }

  static Widget buildDefaultActions(DrawingController controller) {
    return _DrawingBoardState.buildDefaultActions(controller);
  }

  static Widget buildDefaultTools(DrawingController controller,
      {DefaultToolsBuilder? defaultToolsBuilder, Axis axis = Axis.horizontal}) {
    return _DrawingBoardState.buildDefaultTools(controller, defaultToolsBuilder: defaultToolsBuilder, axis: axis);
  }

  /// ------- custom tools and actions build:
  /// ------ tools:
  static List<DefToolItem> customTools(
    Type currType,
    DrawingController controller,
    Color activeColor,
    Function({bool isColor}) showAdditionalToolbar,
    Color selectedColor,
    int selectedIndex,
    double initialPosition,
    bool isColorOn,
  ) {
    return <DefToolItem>[
      /// ------- open colors toolbar
      DefToolItem(
          icon: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: selectedColor == Colors.transparent
                  ? activeColor == Colors.white
                      ? const Color(0xff3a3a3a)
                      : Colors.white
                  : selectedColor,
              border: Border.all(
                  color: isColorOn
                      ? activeColor
                      : activeColor == Colors.white
                          ? const Color(0xff3a3a3a)
                          : Colors.white),
              borderRadius: const BorderRadius.all(
                Radius.circular(2),
              ),
            ),
          ),
          onTap: () {
            showAdditionalToolbar(isColor: true);
          },
          isActive: isColorOn),

      /// ------- open shapes toolbar
      DefToolItem(
          isActive: (currType == Rectangle || currType == Circle || currType == StraightLine) && !isColorOn,
          icon: SvgPicture.asset(
            'assets/icons/shapes.svg',
            fit: BoxFit.scaleDown,
            colorFilter: (currType == Rectangle || currType == Circle || currType == StraightLine) && !isColorOn
                ? ColorFilter.mode(activeColor, BlendMode.srcIn)
                : null,
          ),
          onTap: () {
            if (currType == Rectangle) {
              controller.setPaintContent(Rectangle());
            } else if (currType == Circle) {
              controller.setPaintContent(Circle());
            } else {
              controller.setPaintContent(StraightLine());
            }
            showAdditionalToolbar();
          }),

      /// ------ pencil
      DefToolItem(
          isActive: currType == SimpleLine && !isColorOn,
          icon: SvgPicture.asset(
            'assets/icons/pencil.svg',
            fit: BoxFit.scaleDown,
            colorFilter: currType == SimpleLine && !isColorOn ? ColorFilter.mode(activeColor, BlendMode.srcIn) : null,
          ),
          onTap: () {
            controller.setPaintContent(SimpleLine());
            showAdditionalToolbar();
          }),

      /// -------- pen
      DefToolItem(
          isActive: currType == SmoothLine && !isColorOn,
          icon: SvgPicture.asset(
            'assets/icons/pen.svg',
            fit: BoxFit.scaleDown,
            colorFilter: currType == SmoothLine && !isColorOn ? ColorFilter.mode(activeColor, BlendMode.srcIn) : null,
          ),
          onTap: () {
            controller.setPaintContent(SmoothLine());
            showAdditionalToolbar();
          }),

      /// ----------- eraser
      DefToolItem(
        isActive: currType == Eraser && !isColorOn,
        icon: SvgPicture.asset(
          'assets/icons/eraser.svg',
          fit: BoxFit.scaleDown,
          colorFilter: currType == Eraser && !isColorOn ? ColorFilter.mode(activeColor, BlendMode.srcIn) : null,
        ),
        onTap: () {
          controller.setPaintContent(
            Eraser(),
          );
          showAdditionalToolbar();
        },
      ),

      /// ----------- undo
      DefToolItem(
          icon: InkWell(
            onTap: controller.undo,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              width: 30,
              height: 30,
              child: SvgPicture.asset(
                'assets/icons/left_arrow.svg',
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
          isActive: false),

      /// --------- redo
      DefToolItem(
        isActive: false,
        icon: InkWell(
          onTap: controller.redo,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: 30,
            height: 30,
            child: SvgPicture.asset(
              'assets/icons/right_arrow.svg',
              fit: BoxFit.scaleDown,
            ),
          ),
        ),
      ),

      /// --------- clear
      DefToolItem(
        isActive: false,
        icon: InkWell(
          onTap: controller.clear,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: 30,
            height: 30,
            child: SvgPicture.asset(
              'assets/icons/trash.svg',
              fit: BoxFit.scaleDown,
            ),
          ),
        ),
      ),
    ];
  }

  /// ------ shapes
  static List<DefToolItem> customToolsShapes(Type currType, DrawingController controller, Color activeColor,
      Function() showAdditionalToolbar, Function(int)? colorToolbarOnClick) {
    return <DefToolItem>[
      /// ---------- straight line
      DefToolItem(
          isActive: currType == StraightLine,
          icon: SvgPicture.asset(
            'assets/icons/minus.svg',
            fit: BoxFit.scaleDown,
            colorFilter: currType == StraightLine ? ColorFilter.mode(activeColor, BlendMode.srcIn) : null,
          ),
          onTap: () {
            controller.setPaintContent(StraightLine());
            showAdditionalToolbar();
          }),

      /// ----------- rectangle
      DefToolItem(
          isActive: currType == Rectangle,
          icon: SvgPicture.asset(
            'assets/icons/rectangle.svg',
            fit: BoxFit.scaleDown,
            colorFilter: currType == Rectangle ? ColorFilter.mode(activeColor, BlendMode.srcIn) : null,
          ),
          onTap: () {
            controller.setPaintContent(Rectangle());
            showAdditionalToolbar();
          }),

      /// -------- circle
      DefToolItem(
          isActive: currType == Circle,
          icon: SvgPicture.asset(
            'assets/icons/circle.svg',
            fit: BoxFit.scaleDown,
            colorFilter: currType == Circle ? ColorFilter.mode(activeColor, BlendMode.srcIn) : null,
          ),
          onTap: () {
            controller.setPaintContent(Circle());
            showAdditionalToolbar();
          }),
    ];
  }

  static Widget buildCustomTools(DrawingController controller,
      {required Color activeColor,
      required Function({bool isColor}) showAdditionalToolbar,
      required Function(int) colorToolbarOnClick,
      required Function(int, bool) colorToolbarOnDrag,
      Axis axis = Axis.horizontal,
      bool showShapes = false,
      bool showSize = false,
      bool showColors = false,
      int selectedIndex = 0,
      double initialPosition = 30.0,
      bool isColorOn = false}) {
    return _DrawingBoardState.buildCustomTools(controller,
        axis: axis,
        activeColor: activeColor,
        showShapes: showShapes,
        showSize: showSize,
        showColors: showColors,
        showAdditionalToolbar: showAdditionalToolbar,
        colorToolbarOnClick: colorToolbarOnClick,
        colorToolbarOnDrag: colorToolbarOnDrag,
        selectedIndex: selectedIndex,
        initialPosition: initialPosition,
        isColorOn: isColorOn);
  }

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  late final DrawingController _controller = widget.controller ?? DrawingController();

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  bool showShapes = false;
  bool showSize = false;
  bool showColors = false;

  List<Type> toolsWithSize = <Type>[SimpleLine, SmoothLine, StraightLine, Rectangle, Circle, Eraser];
  List<Type> toolsWithShape = <Type>[StraightLine, Rectangle, Circle];

  Color selectedColor = Colors.transparent;

  double initialPosition = 30.0;
  int selectedIndex = 0;

  List<Color> colors = Constants().selectableColors;

  Type? activeTool;
  bool isColorOn = false;

  /// FUNCTIONS:
  /// ----------- show additional toolbar
  void showAdditionalToolbar({bool isColor = false}) {
    setState(() {
      if (isColor) {
        isColorOn = !isColorOn;
        showColors = isColorOn;
        showSize = false;
        showShapes = false;
      } else {
        showColors = false;
        isColorOn = false;
        if (activeTool == _controller.drawConfig.value.contentType) {
          activeTool = null;
          showSize = false;
          showShapes = false;
        } else {
          activeTool = _controller.drawConfig.value.contentType;
          if (toolsWithSize.contains(_controller.drawConfig.value.contentType)) {
            showSize = true;
          }
          if (toolsWithShape.contains(_controller.drawConfig.value.contentType)) {
            showShapes = true;
          } else {
            showShapes = false;
          }
        }
      }
    });
  }

  /// ------ color toolbar on click
  void colorToolbarOnClick(int index) {
    setState(() {
      selectedIndex = index;
      initialPosition = 30.0 + selectedIndex * 14.0;
      if (selectedIndex == 0) {
        selectedColor =
            Theme.of(context).brightness == Brightness.light ? colors.elementAt(selectedIndex) : Colors.white;
      } else {
        selectedColor = colors.elementAt(selectedIndex);
      }
      _controller.setStyle(color: selectedColor);
    });
  }

  /// ------- color toolbar on drag

  void colorToolbarOnDrag(int currentIndex, bool increase) {
    setState(() {
      if (increase) {
        if (currentIndex < colors.length - 1) {
          selectedIndex = currentIndex + 1;
        }
      } else {
        if (currentIndex > 0) {
          selectedIndex = currentIndex - 1;
        }
      }
      initialPosition = 30.0 + selectedIndex * 14.0;
      if (selectedIndex == 0) {
        selectedColor =
            Theme.of(context).brightness == Brightness.light ? colors.elementAt(selectedIndex) : Colors.white;
      } else {
        selectedColor = colors.elementAt(selectedIndex);
      }
      _controller.setStyle(color: selectedColor);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = InteractiveViewer(
      maxScale: widget.maxScale,
      minScale: widget.minScale,
      boundaryMargin: widget.boardBoundaryMargin ?? EdgeInsets.all(MediaQuery.of(context).size.width),
      clipBehavior: widget.boardClipBehavior,
      panAxis: widget.panAxis,
      constrained: widget.boardConstrained,
      onInteractionStart: widget.onInteractionStart,
      onInteractionUpdate: widget.onInteractionUpdate,
      onInteractionEnd: widget.onInteractionEnd,
      scaleFactor: widget.boardScaleFactor,
      panEnabled: widget.boardPanEnabled,
      scaleEnabled: widget.boardScaleEnabled,
      transformationController: widget.transformationController,
      child: Align(alignment: widget.alignment, child: _buildBoard),
    );

    if (widget.showDefaultActions || widget.showDefaultTools) {
      content = Column(
        children: <Widget>[
          Expanded(child: content),
          if (widget.showDefaultActions) buildDefaultActions(_controller),
          if (widget.showDefaultTools) buildDefaultTools(_controller, defaultToolsBuilder: widget.defaultToolsBuilder),
        ],
      );
    } else {
      content = Column(
        children: <Widget>[
          Expanded(child: content),
          buildCustomTools(_controller,
              activeColor: Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF3a3a3a),
              showShapes: showShapes,
              showSize: showSize,
              showColors: showColors,
              showAdditionalToolbar: showAdditionalToolbar,
              selectedColor: selectedColor,
              colorToolbarOnClick: colorToolbarOnClick,
              colorToolbarOnDrag: colorToolbarOnDrag,
              selectedIndex: selectedIndex,
              initialPosition: initialPosition,
              isColorOn: isColorOn),
        ],
      );
    }

    return Listener(
      onPointerDown: (PointerDownEvent pde) => _controller.addFingerCount(pde.localPosition),
      onPointerUp: (PointerUpEvent pue) => _controller.reduceFingerCount(pue.localPosition),
      onPointerCancel: (PointerCancelEvent pce) => _controller.reduceFingerCount(pce.localPosition),
      child: content,
    );
  }

  /// 构建画板
  Widget get _buildBoard {
    return RepaintBoundary(
      key: _controller.painterKey,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: _controller.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) => p.angle != n.angle || p.size != n.size,
        builder: (_, DrawConfig dc, Widget? child) {
          Widget c = child!;

          if (dc.size != null) {
            final bool isHorizontal = dc.angle.toDouble() % 2 == 0;
            final double max = dc.size!.longestSide;

            if (!isHorizontal) {
              c = SizedBox(width: max, height: max, child: c);
            }
          }

          return Transform.rotate(angle: dc.angle * pi / 2, child: c);
        },
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[_buildImage, _buildPainter],
          ),
        ),
      ),
    );
  }

  /// 构建背景
  Widget get _buildImage => GetSize(
        onChange: (Size? size) => _controller.setBoardSize(size),
        child: widget.background,
      );

  /// 构建绘制层
  Widget get _buildPainter {
    return ExValueBuilder<DrawConfig>(
      valueListenable: _controller.drawConfig,
      shouldRebuild: (DrawConfig p, DrawConfig n) => p.size != n.size,
      builder: (_, DrawConfig dc, Widget? child) {
        return SizedBox(
          width: dc.size?.width,
          height: dc.size?.height,
          child: child,
        );
      },
      child: Painter(
        drawingController: _controller,
        onPointerDown: widget.onPointerDown,
        onPointerMove: widget.onPointerMove,
        onPointerUp: widget.onPointerUp,
      ),
    );
  }

  /// 构建默认操作栏
  static Widget buildDefaultActions(DrawingController controller) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
            valueListenable: controller.drawConfig,
            builder: (_, DrawConfig dc, ___) {
              return Row(
                children: <Widget>[
                  SizedBox(
                    height: 24,
                    width: 160,
                    child: Slider(
                      value: dc.strokeWidth,
                      max: 50,
                      min: 1,
                      onChanged: (double v) => controller.setStyle(strokeWidth: v),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.arrow_turn_up_left,
                      color: controller.canUndo() ? null : Colors.grey,
                    ),
                    onPressed: () => controller.undo(),
                  ),
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.arrow_turn_up_right,
                      color: controller.canRedo() ? null : Colors.grey,
                    ),
                    onPressed: () => controller.redo(),
                  ),
                  IconButton(icon: const Icon(CupertinoIcons.rotate_right), onPressed: () => controller.turn()),
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash),
                    onPressed: () => controller.clear(),
                  ),
                ],
              );
            }),
      ),
    );
  }

  /// 构建默认工具栏
  static Widget buildDefaultTools(
    DrawingController controller, {
    DefaultToolsBuilder? defaultToolsBuilder,
    Axis axis = Axis.horizontal,
  }) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: axis,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: controller.drawConfig,
          shouldRebuild: (DrawConfig p, DrawConfig n) => p.contentType != n.contentType,
          builder: (_, DrawConfig dc, ___) {
            final Type currType = dc.contentType;

            final List<Widget> children =
                (defaultToolsBuilder?.call(currType, controller) ?? DrawingBoard.defaultTools(currType, controller))
                    .map((DefToolItem item) => _DefToolItemWidget(item: item))
                    .toList();

            return axis == Axis.horizontal ? Row(children: children) : Column(children: children);
          },
        ),
      ),
    );
  }

  /// Custom toolbar
  static Widget buildCustomTools(DrawingController controller,
      {required Color activeColor,
      required Function({bool isColor}) showAdditionalToolbar,
      required Function(int) colorToolbarOnClick,
      required Function(int, bool) colorToolbarOnDrag,
      Axis axis = Axis.horizontal,
      bool showShapes = false,
      bool showSize = false,
      bool showColors = false,
      Color selectedColor = Colors.transparent,
      int selectedIndex = 0,
      double initialPosition = 30.0,
      bool isColorOn = false}) {
    return Material(
      color: Colors.white,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: controller.drawConfig,
// shouldRebuild: (DrawConfig p, DrawConfig n) => p.contentType != n.contentType,
        builder: (_, DrawConfig dc, ___) {
          final Type currType = dc.contentType;

          final List<Widget> children = DrawingBoard.customTools(currType, controller, activeColor,
                  showAdditionalToolbar, selectedColor, selectedIndex, initialPosition, isColorOn)
              .map((DefToolItem item) => _DefToolItemWidget(item: item))
              .toList();

          final List<Widget> childrenShapes = DrawingBoard.customToolsShapes(
                  currType, controller, activeColor, showAdditionalToolbar, colorToolbarOnClick)
              .map((DefToolItem item) => _DefToolItemWidget(item: item))
              .toList();

          return axis == Axis.horizontal
              ? ColoredBox(
                  color: activeColor == Colors.white ? const Color(0xFFF6F6F6) : const Color(0xFF474747),
                  child: Column(
                    children: <Widget>[
                      if (showColors)
                        ColorsToolbar(
                          selectedColor: selectedColor,
                          selectedIndex: selectedIndex,
                          initialPosition: initialPosition,
                          colorToolbarOnClick: (int selectedIndex) => colorToolbarOnClick(selectedIndex),
                          colorToolbarOnDrag: (int selectedIndex, bool increase) =>
                              colorToolbarOnDrag(selectedIndex, increase),
                        ),
                      if (showShapes)
                        SizedBox(
                            height: 45,
                            width: 150,
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: childrenShapes)),
                      if (showSize)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            height: 50,
                            child: SliderTheme(
                              data: const SliderThemeData(
                                trackHeight: 1,
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: RoundSliderThumbShape(enabledThumbRadius: 5, pressedElevation: 0),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    dc.strokeWidth.round().toString(),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      InkWell(
                                        onTap: () {
                                          if (controller.drawConfig.value.strokeWidth - 1 > 0) {
                                            controller.setStyle(
                                                strokeWidth: controller.drawConfig.value.strokeWidth - 1);
                                          }
                                        },
                                        customBorder: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: SvgPicture.asset(
                                            'assets/icons/minus.svg',
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 14,
                                      ),
                                      Expanded(
                                        child: Slider(
                                          activeColor:
                                              activeColor == Colors.white ? const Color(0xFF3a3a3a) : Colors.white,
                                          value: dc.strokeWidth,
                                          max: 50,
                                          min: 1,
                                          onChanged: (double v) {
                                            controller.setStyle(strokeWidth: v);
                                          },
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 14,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          if (controller.drawConfig.value.strokeWidth + 1 < 50) {
                                            controller.setStyle(
                                                strokeWidth: controller.drawConfig.value.strokeWidth + 1);
                                          }
                                        },
                                        customBorder: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: SvgPicture.asset(
                                            'assets/icons/plus.svg',
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                            height: 45,
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children)),
                      ),
                    ],
                  ),
                )
              : Column(children: children);
        },
      ),
    );
  }
}

class ColorsToolbar extends StatefulWidget {
  const ColorsToolbar({
    super.key,
    required this.selectedColor,
    required this.colorToolbarOnClick,
    required this.colorToolbarOnDrag,
    this.selectedIndex = 0,
    this.initialPosition = 30.0,
  });

  final Color selectedColor;
  final Function(int) colorToolbarOnClick;
  final Function(int, bool) colorToolbarOnDrag;
  final int selectedIndex;
  final double initialPosition;

  @override
  State<ColorsToolbar> createState() => _ColorsToolbarState();
}

class _ColorsToolbarState extends State<ColorsToolbar> {
  @override
  Widget build(BuildContext context) {
    final List<Color> colors = Constants().selectableColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      height: 45,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<SelectableColor>.generate(
              colors.length,
              (int index) => SelectableColor(
                    color: colors.elementAt(index),
                    onDrag: (DragUpdateDetails value) {
                      if ((widget.initialPosition < value.globalPosition.dx) &&
                          value.globalPosition.dx > 14 * widget.selectedIndex + 60) {
                        widget.colorToolbarOnDrag(widget.selectedIndex, true);
                      } else {
                        if ((value.globalPosition.dx < widget.initialPosition) &&
                            (value.globalPosition.dx < 14 * widget.selectedIndex)) {
                          widget.colorToolbarOnDrag(widget.selectedIndex, false);
                        }
                      }
                    },
                    onClick: () => widget.colorToolbarOnClick(index),
                    isOn: (widget.selectedColor == colors.elementAt(index)) ||
                        (widget.selectedColor == Colors.transparent && widget.selectedIndex == index),
                    borderLeft: index == 0,
                    borderRight: index == colors.length - 1,
                  ))),
    );
  }
}

/// 默认工具项配置文件
class DefToolItem {
  DefToolItem({
    required this.icon,
    required this.isActive,
    this.onTap,
    this.color,
    this.activeColor = Colors.blue,
    this.iconSize,
  });

  final Function()? onTap;
  final bool isActive;

  final Widget icon;
  final double? iconSize;
  final Color? color;
  final Color activeColor;
}

/// 默认工具项 Widget
class _DefToolItemWidget extends StatelessWidget {
  const _DefToolItemWidget({
    required this.item,
  });

  final DefToolItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        alignment: Alignment.center,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
            color: item.isActive
                ? Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF3a3a3a)
                    : Colors.white
                : Colors.transparent),
        child: item.icon,
      ),
    );
  }
}
