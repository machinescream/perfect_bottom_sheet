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
  final int borderRadius;

  late final _controller = controller!;
  var _ignoring = false;
  late final _innerSc = ScrollController();

  PerfectBottomSheetRoute({
    required this.builder,
    this.openPercentage = 0.3,
    this.backgroundColor = Colors.white,
    this.borderRadius = 24,
  });

  @override
  void dispose() {
    _innerSc.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final bottomSheetHeight = _screenHeight * openPercentage;
    return RawGestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      gestures: {
        _AllowGestureVertical:
            GestureRecognizerFactoryWithHandlers<_AllowGestureVertical>(
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
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(), //constructor
          (TapGestureRecognizer instance) {
            instance.onTapUp = (upd) {
              if (upd.localPosition.dy < _screenHeight - bottomSheetHeight) {
                Navigator.of(context).pop();
              }
            };
          },
        ),
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipPath(
          clipBehavior: Clip.hardEdge,
          clipper: _SuperellipseClipper(borderRadius),
          child: ColoredBox(
            color: backgroundColor,
            child: SizedBox(
              height: bottomSheetHeight,
              child: builder(context, _innerSc),
            ),
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
    if (delta > 0 && _innerSc.offset <= 0) {
      _innerSc.jumpTo(0);
    }
    if (_innerSc.offset == 0) {
      _controller.value -= delta / _screenHeight;
    }
  }

  Future<void> _onEnd(DragEndDetails upd, VoidCallback onClose) async {
    final val = _controller.value;
    final velocity = _innerSc.offset > 0 ? 0 : upd.primaryVelocity ?? 0;
    final toTop = val > openPercentage && velocity < 2000;
    setState(() {
      _ignoring = true;
    });
    await _controller.animateTo(
      toTop ? 1.0 : 0.0,
      duration: transitionDuration,
      curve: Curves.decelerate,
    );
    setState(() {
      _ignoring = false;
    });
    if (!toTop) {
      onClose();
    }
  }

  double get _screenHeight => MediaQuery.of(navigator!.context).size.height;


}

class _AllowGestureVertical extends VerticalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class _SuperellipseClipper extends CustomClipper<Path> {
  final int clipValue;

  _SuperellipseClipper(this.clipValue);

  @override
  Path getClip(Size size) {
    var path = Path();
    var r = size.height / clipValue; // Change this value to adjust the curve

    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, r);
    path.quadraticBezierTo(size.width, 0, size.width - r, 0);
    path.lineTo(r, 0);
    path.quadraticBezierTo(0, 0, 0, r);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _PopupRouteSettings<T> extends PopupRoute<T>{
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
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    throw UnimplementedError();
  }
}
