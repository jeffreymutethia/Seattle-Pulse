import 'package:flutter/material.dart';

class Reaction {
  final String name;
  final String emoji;
  final Color color;
  final String label;

  const Reaction({
    required this.name,
    required this.emoji,
    required this.color,
    required this.label,
  });
}

class ReactionPopup extends StatefulWidget {
  final Function(Reaction) onReactionSelected;
  final List<Reaction> reactions;
  final VoidCallback onDismiss;

  const ReactionPopup({
    Key? key,
    required this.onReactionSelected,
    required this.reactions,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _ReactionPopupState createState() => _ReactionPopupState();
}

class _ReactionPopupState extends State<ReactionPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _staggeredScales;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // One Interval per emoji, each starting 0.1s later.
    _staggeredScales = List.generate(widget.reactions.length, (i) {
      final start = (i * 0.1).clamp(0.0, 0.9);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, 1.0, curve: Curves.easeOutBack),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller, // overall pop
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.reactions.length, (i) {
            final reaction = widget.reactions[i];
            final isHovered = _hoveredIndex == i;

            return AnimatedBuilder(
              animation: _staggeredScales[i],
              builder: (context, child) {
                // raw value may overshoot >1.0 because of easeOutBack
                final raw = _staggeredScales[i].value;
                // clamp opacity strictly between 0 and 1
                final opacity = raw.clamp(0.0, 1.0) as double;
                // let scale overshoot for the "pop" effect
                final scale = raw * (isHovered ? 1.4 : 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  widget.onReactionSelected(reaction);
                },
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = i),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      reaction.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class ReactionPopupOverlay {
  OverlayEntry? _entry;
  final BuildContext context;
  final GlobalKey anchorKey;
  final List<Reaction> reactions;
  final Function(Reaction) onReactionSelected;

  ReactionPopupOverlay({
    required this.context,
    required this.anchorKey,
    required this.reactions,
    required this.onReactionSelected,
  });

  void show() {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: (ctx) {
      return Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: dismiss,
          child: Stack(
            children: [_buildPositionedPopup()],
          ),
        ),
      );
    });
    Overlay.of(context)!.insert(_entry!);
  }

  void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  Widget _buildPositionedPopup() {
    final renderBox =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox();
    final pos = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return Positioned(
      left: pos.dx + size.width / 2 - 60,
      top: pos.dy - 60,
      child: ReactionPopup(
        reactions: reactions,
        onReactionSelected: (r) {
          onReactionSelected(r);
          dismiss();
        },
        onDismiss: dismiss,
      ),
    );
  }
}
