import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SlideToLearn extends StatefulWidget {
  final VoidCallback onOk;
  final Future<void> Function() onLearned;
  final String completedLabel;
  final bool isReadMode;
  final bool leftHanded;

  const SlideToLearn({
    super.key,
    required this.onOk,
    required this.onLearned,
    this.completedLabel = 'Жаттадым!',
    this.isReadMode = false,
    this.leftHanded = false,
  });

  @override
  State<SlideToLearn> createState() => _SlideToLearnState();
}

class _SlideToLearnState extends State<SlideToLearn> {
  double _slideX = 0;
  bool _triggered = false;

  static const double _height = 60;
  static const double _thumbSize = 52;

  Color get _activeColorMid =>
      widget.isReadMode ? const Color(0xFF1976D2) : const Color(0xFF2D7A55);

  double get _maxWidth => MediaQuery.of(context).size.width * 0.5;
  double get _maxSlide => _maxWidth - _thumbSize - 8;
  double get _progress =>
      _maxSlide > 0 ? (_slideX / _maxSlide).clamp(0.0, 1.0) : 0.0;

  Color _trackColor(Color borderColor) => Color.lerp(
        borderColor,
        _activeColorMid,
        _progress,
      )!;

  Future<void> _complete() async {
    if (_triggered) return;
    setState(() {
      _triggered = true;
      _slideX = _maxSlide;
    });
    try {
      await widget.onLearned();
    } catch (_) {
      // ignore errors so the button always resets
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _slideX = 0;
          _triggered = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.of(context).border;
    final lh = widget.leftHanded;
    final thumbLeft = lh ? (4 + _maxSlide - _slideX) : (4 + _slideX);

    return Center(
      child: GestureDetector(
        onTap: _triggered ? null : widget.onOk,
        onHorizontalDragUpdate: (details) {
          if (_triggered) return;
          setState(() {
            final delta = lh ? -details.delta.dx : details.delta.dx;
            _slideX = (_slideX + delta).clamp(0.0, _maxSlide);
          });
        },
        onHorizontalDragEnd: (_) {
          if (_triggered) return;
          if (_slideX > _maxSlide * 0.6) {
            _complete();
          } else {
            setState(() => _slideX = 0);
          }
        },
        child: Container(
          width: _maxWidth,
          height: _height,
          decoration: BoxDecoration(
            color: _trackColor(borderColor),
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // "Ок" label — fades out as progress grows
              Opacity(
                opacity: (1 - (_progress * 2)).clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: lh
                      ? [
                          const Text(
                            '✅  Ок',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6E6E73),
                            ),
                          ),
                          const SizedBox(width: _thumbSize + 16),
                        ]
                      : [
                          const SizedBox(width: _thumbSize + 16),
                          const Text(
                            '✅  Ок',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6E6E73),
                            ),
                          ),
                        ],
                ),
              ),
              // Completed label — fades in past halfway
              Opacity(
                opacity: ((_progress - 0.5) * 2).clamp(0.0, 1.0),
                child: Text(
                  '🎉  ${widget.completedLabel}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Thumb — transparent circle with border
              Positioned(
                left: thumbLeft,
                child: Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _triggered
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            lh ? Icons.chevron_left : Icons.chevron_right,
                            size: 28,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
