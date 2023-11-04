import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef BuilderWithScrollController = Widget Function(
  BuildContext context,
  ScrollController controller,
);

class PerfectBottomSheetRoute<T> extends _PopupRouteSettings<T> {
  final BuilderWithScrollController builder;
  final double openPercentage;
  final Color backgroundColor;
  final double borderRadius;
  final bool expandable;

  var _ignoring = false;
  late final _sizeController = AnimationController(
    vsync: navigator!,
    lowerBound: 0.0,
    upperBound: expandable ? _maxHeight : _bottomSheetHeight,
  )..value = _bottomSheetHeight;
  late final _innerSc = ScrollController();
  late final context = navigator!.context;
  late final double _screenHeight = MediaQuery.of(context).size.height;
  late final double _maxHeight = _screenHeight - MediaQuery.of(context).padding.top;
  late final _bottomSheetHeight = _screenHeight * openPercentage;
  late final _borderRadiusCircular = Radius.circular(borderRadius);

  PerfectBottomSheetRoute({
    required this.builder,
    this.openPercentage = 0.45,
    this.backgroundColor = Colors.white,
    this.borderRadius = 7,
    this.expandable = false,
  });

  @override
  void dispose() {
    _sizeController.dispose();
    _innerSc.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return RawGestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      gestures: {
        _AllowGestureVertical: GestureRecognizerFactoryWithHandlers<_AllowGestureVertical>(
          () => _AllowGestureVertical(), //constructor
          (_AllowGestureVertical instance) {
            instance.onUpdate = _onUpdate;
            instance.onEnd = (upd) {
              _onEnd(
                upd,
                () => Navigator.of(context).pop(),
              );
            };
          },
        ),
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(), //constructor
          (TapGestureRecognizer instance) {
            instance.onTapUp = (upd) {
              if (upd.localPosition.dy < _screenHeight - _bottomSheetHeight) {
                Navigator.of(context).pop();
              }
            };
          },
        ),
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ColoredBox(
          color: backgroundColor,
          child: ValueListenableBuilder<double>(
            valueListenable: _sizeController,
            builder: (context, value, _) {
              return SizedBox(
                height: value,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: _borderRadiusCircular,
                    topRight: _borderRadiusCircular,
                  ),
                  child: builder(context, _innerSc),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return DecoratedBoxTransition(
      position: DecorationPosition.background,
      decoration: animation.drive(
        DecorationTween(
          begin: const BoxDecoration(color: Colors.transparent),
          end: const BoxDecoration(color: Colors.black38),
        ),
      ),
      child: SlideTransition(
        transformHitTests: false,
        position: animation.drive(
          Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ),
        ),
        child: RepaintBoundary(
          child: IgnorePointer(
            ignoring: _ignoring,
            child: child,
          ),
        ),
      ),
    );
  }

  void _onUpdate(DragUpdateDetails upd) {
    final delta = upd.delta.dy;
    if (_draggable) {
      _sizeController.value -= delta;
    }
    if (_draggable && _sizeController.value < _maxHeight && expandable) {
      _innerSc.jumpTo(0);
      return;
    }
    if (delta > 0 && _innerSc.offset <= 0.0) {
      _innerSc.jumpTo(0);
    }
  }

  Future<void> _animateToTop(bool toTop) async {
    setState(() {
      _ignoring = true;
    });
    await _sizeController.animateTo(
      toTop ? _sizeController.upperBound : _bottomSheetHeight,
      duration: transitionDuration,
      curve: Curves.decelerate,
    );
    setState(() {
      _ignoring = false;
    });
  }

  Future<void> _onEnd(DragEndDetails upd, VoidCallback onClose) async {
    if (!_draggable) return;
    final velocity = upd.velocity.pixelsPerSecond.dy;
    if (velocity < -2000) {
      await _animateToTop(true);
      return;
    }
    if (velocity > 2000 || _sizeController.value < _bottomSheetHeight / 2) {
      if (_sizeController.value < _bottomSheetHeight) {
        onClose();
        return;
      }
      await _animateToTop(false);
      return;
    }
    final toTopValue = _sizeController.value > _maxHeight / 1.33;
    await _animateToTop(toTopValue);
    return;
  }

  bool get _draggable => _innerSc.offset <= 0.0;
}

class _AllowGestureVertical extends VerticalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class _PopupRouteSettings<T> extends PopupRoute<T> {
  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get barrierDismissible => true;

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    throw UnimplementedError();
  }
}
