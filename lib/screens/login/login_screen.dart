import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/auth_service.dart';
import '../../utils/farsi_utils.dart';
import '../../widgets/back_arrow_icon.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorText;
  bool _isLoading = false;
  String? _connectionError;

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = toLatiNumber(_phoneController.text.trim());
    if (!isValidIranianPhone(phone)) {
      setState(() => _errorText = 'شماره وارد شده معتبر نیست');
      return;
    }
    setState(() {
      _errorText = null;
      _connectionError = null;
      _isLoading = true;
    });

    final success = await ref.read(authProvider.notifier).sendOtp(phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.push('/otp', extra: phone);
    } else {
      setState(() => _connectionError = 'اشکال در برقراری ارتباط');
    }
  }

  bool get _hasPhone => _phoneController.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
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
              // محتوای اصلی — وسط صفحه (عمودی و افقی)
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
                    // عنوان — وسط
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'ورود | ثبت نام',
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
                    const SizedBox(height: 32),
                    // زیرنویس — وسط
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'لطفا شماره همراه خود را وارد کنید',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFE0E0E0),
                          height: 1.71,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // فیلد و دکمه وسط (مثل CSS: 364px و calc(50% - 364/2))
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 364),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // فیلد شماره — کل کادر قابل کلیک و ورود، درشت و واضح (بدون باکس تو در تو)
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextField(
                                controller: _phoneController,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.phone,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 18,
                                  color: Colors.white,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'مثلا: ۰۹۱۲۳۴۵۶۷۸۹',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 18,
                                    color: Colors.white.withValues(alpha: 0.35),
                                    height: 1.5,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.08),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
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
                                onChanged: (_) => setState(() => _errorText = null),
                                onSubmitted: (_) => _sendOtp(),
                              ),
                            ),
                            if (_errorText != null) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  _errorText!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 14,
                                    color: AppColors.errorLight,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 40),
                            // دکمه دریافت کد (Frame 502) — فعال: پس‌زمینه سفید و متن مشکی
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: Material(
                                color: _hasPhone && !_isLoading
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: _isLoading ? null : _sendOtp,
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
                                        : DefaultTextStyle(
                                            style: TextStyle(
                                              fontFamily: 'Vazir',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: _hasPhone && !_isLoading
                                                  ? const Color(0xFF1A1A1A)
                                                  : const Color(0xFFE0E0E0),
                                              height: 1.71,
                                            ),
                                            child: const Text('دریافت کد'),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                  ),
                ),
              ),
              // دکمه بازگشت (Frame 143) — بالا راست
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
              // بنر خطای ارتباط (اشکال در برقراری ارتباط)
              if (_connectionError != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: AppColors.error,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _connectionError!,
                                style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () =>
                                  setState(() => _connectionError = null),
                            ),
                          ],
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
