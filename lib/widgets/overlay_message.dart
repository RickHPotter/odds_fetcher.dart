import "package:flutter/material.dart";

enum MessageType { info, success, warning, error }

Color getColorFromType(MessageType type) {
  switch (type) {
    case MessageType.info:
      return Colors.blue;
    case MessageType.success:
      return Colors.green;
    case MessageType.warning:
      return Colors.orange;
    case MessageType.error:
      return Colors.red;
  }
}

Icon getIconFromType(MessageType type) {
  switch (type) {
    case MessageType.info:
      return const Icon(Icons.info, color: Colors.white);
    case MessageType.success:
      return const Icon(Icons.check, color: Colors.white);
    case MessageType.warning:
      return const Icon(Icons.warning, color: Colors.white);
    case MessageType.error:
      return const Icon(Icons.error, color: Colors.white);
  }
}

void showOverlayMessage(
  BuildContext context,
  String message, {
  MessageType type = MessageType.success,
  Duration duration = const Duration(seconds: 2),
}) {
  Color color = getColorFromType(type);
  Icon icon = getIconFromType(type);

  final OverlayEntry overlayEntry = OverlayEntry(
    builder:
        (BuildContext context) => Positioned(
          top: MediaQuery.of(context).size.height * 0.002,
          left: MediaQuery.of(context).size.width * 0.75,
          child: Material(
            color: Colors.transparent,
            child: AnimatedOverlayMessage(content: message, color: color, icon: icon),
          ),
        ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3)).then((_) => overlayEntry.remove());
}

class AnimatedOverlayMessage extends StatefulWidget {
  final String content;
  final Color color;
  final Icon icon;
  const AnimatedOverlayMessage({super.key, required this.content, required this.color, required this.icon});

  @override
  State<AnimatedOverlayMessage> createState() => _AnimatedOverlayMessageState();
}

class _AnimatedOverlayMessageState extends State<AnimatedOverlayMessage> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    opacityAnimation = Tween(begin: 0.0, end: 3.0).animate(_controller!);
    _controller!.forward();

    Future.delayed(const Duration(seconds: 3)).then((_) {
      if (mounted) _controller?.reverse();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller!.drive(CurveTween(curve: Curves.easeInOut)),
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.icon,
            SizedBox(width: 8),
            Flexible(child: Text(widget.content, style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
