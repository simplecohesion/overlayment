import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:overlayment/src/types/animations/over_animation.dart';
import 'package:overlayment/src/types/overlay_base.dart';

import '../../overlayment.dart';
import '../helpres/paltform/view_padding_web.dart'
    if (dart.library.io) '../helpres/paltform/view_padding_io.dart';
import '../types/animations/overlay_animation.dart';
import 'filter_widget.dart';
import 'overlay_widget.dart';

/// Create a widget that can be expanded and collapsed as an overlay.
/// This widget can be used for example to create a dropdown list.
/// ```dart
/// OverExpander<int>(
///    child: the child widget,
///    onSelect: an event handler that is called when the user selects an item
///    expandChild: children to be displayed when the widget is expanded,
/// ),
/// ```
class OverExpander<T> extends StatefulWidget {
  OverExpander({
    required this.child,
    required this.expandChild,
    this.color,
    this.margin,
    this.onSelect,
    this.width,
    this.height,
    this.duration,
    this.animation,
    this.decoration,
    this.globalAlignment,
    this.expand = false,
    this.addInsetsPaddings = false,
    this.isClickable = true,
    this.offset = Offset.zero,
    this.fitParentWidth = true,
    this.alignment = Alignment.center,
    this.actions = const OverlayActions(),
    this.backgroundSettings = const BackgroundSettings(dismissOnClick: true),
    String? name,
    Key? key,
  })  : name = name ?? 'Expander${child.hashCode}',
        super(key: key);

  /// an event handler that is called when the user selects an item
  final Function(T?)? onSelect;

  /// {@macro overlay_base.actions}
  final OverlayActions actions;

  /// {@macro overlay_base.addInsetsPaddings}
  final bool addInsetsPaddings;

  /// The alignment of the overlay relative to the parent.
  /// default is the center
  final Alignment alignment;

  /// {@macro overlay_base.animation}
  final OverAnimation? animation;

  /// {@macro Overlayment.BackgroundSettings}
  final BackgroundSettings? backgroundSettings;

  /// The child widget which will be clicked to expand the overlay
  final Widget child;

  /// {@macro overlay_base.color}
  final Color? color;

  /// {@macro overlay_base.decoration}
  final BoxDecoration? decoration;

  /// {@macro overlay_base.duration}
  final Duration? duration;

  /// should expanded child be visible as default
  final bool expand;

  /// the children to show when the overlay is expanded
  final Widget expandChild;

  /// set this to true if you want the overlay to take the same width as
  /// the parent, otherwise it will take the width of the content
  final bool fitParentWidth;

  /// The overlay position relative to the screen
  /// if this alignment is set the [alignment] will be ignored
  final Alignment? globalAlignment;

  /// The expander width, if null, the expander will try to fit the content
  final double? height;

  /// can user click on the child to show the overlay
  /// if false then the expander should be expanded with [expand] set to true
  final bool isClickable;

  /// {@macro overlay_base.margin}
  final EdgeInsets? margin;

  /// {@macro overlay_base.name}
  final String name;

  /// The overlay offset relative to the child
  final Offset offset;

  /// The expander width, if null, the expander will try to fit the content
  final double? width;

  @override
  State<OverExpander<T>> createState() => _OverExpanderState<T>();
}

class _OverExpanderState<T> extends State<OverExpander<T>> {
  final containerKey = GlobalKey();
  late final name = widget.name;

  bool _expanded = false;

  @override
  void didUpdateWidget(covariant OverExpander<T> oldWidget) {
    _checkExpand();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Overlayment.dismissName(name);
    super.deactivate();
  }

  void _checkExpand() {
    if (widget.expand && !_expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onTap();
      });
      _expanded = true;
      return;
    }
    if (!widget.expand && _expanded) {
      Overlayment.dismissName(name);
      _expanded = false;
    }
  }

  void _onTap() {
    _QExpander(
      widget: widget,
      parentKey: containerKey,
      name: name,
    ).show<T>(context: containerKey.currentContext).then((value) {
      if (widget.onSelect != null) {
        widget.onSelect!(value);
      }
      _expanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _checkExpand();
    return widget.isClickable
        ? InkWell(
            onTap: _onTap,
            key: containerKey,
            child: widget.child,
          )
        : SizedBox(key: containerKey, child: widget.child);
  }
}

/// Show a window at any position on the screen.
class _QExpander with OverlayBase {
  _QExpander({
    required this.widget,
    required this.parentKey,
    required this.name,
  });

  final GlobalKey parentKey;
  final OverExpander widget;

  @override
  late final OverAnimation animation;

  @override
  final String name;

  @override
  late final OverlayAnimation overlayAnimation;

  @override
  OverlayActions get actions => widget.actions;

  @override
  bool get addInsetsPaddings => widget.addInsetsPaddings;

  @override
  List<OverlayEntry> buildEntries() {
    animation = widget.animation ??
        OverFadeAnimation(
          child: OverScaleAnimation(
            alignment: widget.alignment * -1,
            child: OverSlideAnimation(begin: _getBegin()),
          ),
        );

    return [
      if (widget.backgroundSettings != null)
        OverlayEntry(
          builder: (context) =>
              FilterWidget(this, widget.backgroundSettings!, animation),
          maintainState: false,
          opaque: false,
        ),
      OverlayEntry(
          builder: (context) => OverlayWidget(
                overlay: this,
                height: () => widget.height,
                width: _getWidth,
                position: (s, _) => _calcPosition(context, s),
              ))
    ];
  }

  @override
  Widget get child => widget.globalAlignment == null
      ? widget.expandChild
      : SafeArea(
          top: widget.globalAlignment!.y == -1,
          bottom: widget.globalAlignment!.y == 1,
          left: widget.globalAlignment!.x < 1,
          right: widget.globalAlignment!.x > -1,
          child: widget.expandChild,
        );

  @override
  Color? get color => widget.color;

  @override
  BoxDecoration? get decoration => widget.decoration;

  @override
  Duration? get duration => widget.duration;

  @override
  EdgeInsets? get margin => widget.margin;

  @override
  Future<T?> show<T>({BuildContext? context}) =>
      Overlayment.show(this, context: context);

  double? _getWidth() {
    if (!widget.fitParentWidth || parentKey.currentContext == null) {
      return widget.width;
    }
    return (parentKey.currentContext!.findRenderObject() as RenderBox)
        .size
        .width;
  }

  Offset _calcPosition(BuildContext context, Size? size) {
    final screen = MediaQuery.of(context).size;
    if (widget.globalAlignment != null) {
      return _getGlobalPosition(screen, size);
    }

    var screenPadding = MediaQuery.of(context).viewPadding;
    size = size ?? const Size(0, 0);

    // If there is no padding, it could be that there is a safe area widget,
    // which removed the view padding from the context
    // so we need to get it again
    if (screenPadding == EdgeInsets.zero) screenPadding = windowsPadding;

    if (parentKey.currentContext == null) return Offset.zero;

    final renderBox = parentKey.currentContext!.findRenderObject() as RenderBox;
    final parentPosition = renderBox.localToGlobal(
      Offset.zero,
      ancestor: Navigator.of(context).context.findRenderObject(),
    );
    final parentSize = renderBox.size;

    final alignment = widget.globalAlignment ?? widget.alignment;
    final position = alignment.withinRect(Rect.fromLTRB(
      parentPosition.dx,
      parentPosition.dy,
      parentPosition.dx + parentSize.width,
      parentPosition.dy + parentSize.height,
    ));

    final x = position.dx + (size.width * 0.5 * alignment.x - size.width * 0.5);

    final y =
        position.dy + (size.height * 0.5 * alignment.y - size.height * 0.5);

    final maxXPoint = screen.width - size.width * alignment.x;
    final maxYPoint = screen.height - size.height * alignment.x;
    return Offset(max(0, min(x, maxXPoint)), max(0, min(y, maxYPoint)));
  }

  Offset _getGlobalPosition(Size screen, Size? size) {
    size = size ?? const Size(0, 0);
    final x =
        (screen.width / 2 + screen.width / 2 * widget.globalAlignment!.x) -
            (size.width * 0.5 + size.width * 0.5 * widget.globalAlignment!.x);
    final y =
        (screen.height / 2 + screen.height / 2 * widget.globalAlignment!.y) -
            (size.height * 0.5 + size.height * 0.5 * widget.globalAlignment!.y);
    return Offset(x, y);
  }

  Offset _getBegin() {
    final alignment = widget.globalAlignment ?? widget.alignment;
    var x = -alignment.x;
    var y = -alignment.y;

    return Offset(x, y);
  }
}
