import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/auth_service.dart';
import '../../utils/farsi_utils.dart';
import '../../widgets/back_arrow_icon.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _countdown = 119; // 1:59
  bool _canResend = false;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _countdown = 119;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  String get _timerText {
    final m = _countdown ~/ 60;
    final s = _countdown % 60;
    return '${toFarsiNumber(m)}:${toFarsiNumber(s.toString().padLeft(2, '0'))}';
  }

  Future<void> _verify() async {
    final code = _code;
    if (code.length != 4) {
      setState(() => _errorText = 'کد وارد شده معتبر نیست');
      return;
    }
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    final success =
        await ref.read(authProvider.notifier).verifyOtp(widget.phone, code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go('/home');
    } else {
      setState(() => _errorText = 'کد وارد شده معتبر نیست');
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() => _errorText = null);
    await ref.read(authProvider.notifier).sendOtp(widget.phone);
    if (mounted) _startTimer();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() => _errorText = null);
    if (_code.length == 4) {
      _verify();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFullCode = _code.length == 4;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.15, -0.2),
            radius: 1.28,
            colors: [
              Color(0xFF171F36),
              Color(0xFF2B4589),
            ],
            stops: [0.26, 0.88],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).top -
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'اعتبارسنجی',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.27,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        'کد ارسال شده به شماره ${toFarsiNumber(widget.phone)} را وارد کنید',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFE0E0E0),
                          height: 1.71,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // چهار باکس OTP — وسط
                    Center(
                      child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) => _onKeyEvent(index, event),
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  fontFamily: 'Vazir',
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _errorText != null
                                          ? AppColors.errorLight
                                          : Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _errorText != null
                                          ? AppColors.errorLight
                                          : Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _errorText != null
                                          ? AppColors.errorLight
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (value) =>
                                    _onCodeChanged(index, value),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
                          color: AppColors.errorLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // دکمه تایید
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: hasFullCode && !_isLoading
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: _isLoading ? null : _verify,
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  )
                                : Text(
                                    'تایید',
                                    style: TextStyle(
                                      fontFamily: 'Vazir',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: hasFullCode
                                          ? Colors.black
                                          : const Color(0xFFE0E0E0),
                                      height: 1.43,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_canResend)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: _resend,
                          child: const Text(
                            'دریافت مجدد کد',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        _timerText,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.43,
                        ),
                      ),
                    const SizedBox(height: 32),
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'ویرایش شماره',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                  ),
                ),
              ),
              // بازگشت — بالا راست
              Positioned(
                top: 16,
                right: 24,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const BackArrowIcon(size: 24, color: Color(0xFFE0E0E0), pointLeft: false),
                    label: const Text(
                      'بازگشت',
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.43,
                      ),
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
