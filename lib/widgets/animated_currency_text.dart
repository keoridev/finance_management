import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class AnimatedCurrencyText extends StatefulWidget {
  final double amount;
  final TextStyle? style;
  final String currency;
  final bool showSign;
  final Duration duration;
  final bool animateOnMount;

  const AnimatedCurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.currency = 'сом',
    this.showSign = false,
    this.duration = const Duration(milliseconds: 550),
    this.animateOnMount = true,
  });

  @override
  State<AnimatedCurrencyText> createState() => _AnimatedCurrencyTextState();
}

class _AnimatedCurrencyTextState extends State<AnimatedCurrencyText>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    final beginVal = widget.animateOnMount ? 0.0 : widget.amount;
    _currentValue = beginVal;

    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: beginVal, end: widget.amount).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.addListener(() {
      _currentValue = _animation.value;
    });

    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCurrencyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      final fromVal = _currentValue;
      _animation = Tween<double>(begin: fromVal, end: widget.amount).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Text(
          CurrencyFormatter.format(
            _animation.value,
            currency: widget.currency,
            showSign: widget.showSign,
          ),
          style: widget.style,
        );
      },
    );
  }
}
