import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../models/subscription_plan.dart';
import '../../services/auth_service.dart';
import '../../utils/farsi_utils.dart';
import '../../widgets/support_contact_sheet.dart';
import '../../widgets/back_arrow_icon.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  final String planId;
  const PurchaseScreen({super.key, required this.planId});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _phoneError;
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();

  SubscriptionPlan get _plan {
    return SubscriptionPlan.plans.firstWhere(
      (p) => p.id == widget.planId,
      orElse: () => SubscriptionPlan.plans.first,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _processPurchase() async {
    setState(() {
      _isProcessing = true;
      _phoneError = null;
    });

    await Future.delayed(const Duration(seconds: 2));
    await ref.read(authProvider.notifier).setPro(_plan.months);

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) context.go('/home');
  }

  /// مهمان: بعد از «در حال اتصال به درگاه» به لاگین هدایت می‌شود
  Future<void> _guestPay() async {
    final phone = toLatiNumber(_phoneController.text.trim());
    if (!isValidIranianPhone(phone)) {
      setState(() => _phoneError = 'شماره وارد شده معتبر نیست');
      return;
    }
    setState(() {
      _phoneError = null;
      _isProcessing = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    context.pushReplacement('/login');
  }

  Widget _gradientBody(Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.15, -0.2),
          radius: 1.28,
          colors: [Color(0xFF171F36), Color(0xFF2B4589)],
          stops: [0.26, 0.88],
        ),
      ),
      child: SafeArea(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;

    return Scaffold(
      body: _gradientBody(
        Stack(
          children: [
            if (_isSuccess)
              _buildSuccessView()
            else if (_isProcessing)
              _buildGatewayLoading(isLoggedIn)
            else if (isLoggedIn)
              _buildLoggedInView()
            else
              _buildGuestView(),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
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
    );
  }

  /// تصویر ۱ — ارتقا وقتی کاربر لاگین نکرده: طرح انتخاب‌شده + شماره + پرداخت + پشتیبانی
  Widget _buildGuestView() {
    final hasPhone = _phoneController.text.trim().length >= 10;
    return SingleChildScrollView(
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
              _PlanChip(plan: _plan),
              const SizedBox(height: 24),
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
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 364),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
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
                            color: _phoneError != null
                                ? AppColors.errorLight
                                : Colors.white,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _phoneError != null
                                ? AppColors.errorLight
                                : Colors.white,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _phoneError != null
                                ? AppColors.errorLight
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() => _phoneError = null),
                    ),
                  ),
                ),
              ),
              if (_phoneError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _phoneError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14,
                    color: AppColors.errorLight,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                toFarsiPrice(_plan.price),
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 364),
                    child: SizedBox(
                      height: 52,
                      child: Material(
                        color: hasPhone
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: hasPhone ? _guestPay : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: DefaultTextStyle(
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: hasPhone
                                    ? const Color(0xFF1A1A1A)
                                    : const Color(0xFFE0E0E0),
                                height: 1.43,
                              ),
                              child: Text('پرداخت ${toFarsiPrice(_plan.price)}'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () => SupportContactSheet.show(context),
                icon: const Icon(Icons.headset_mic_outlined,
                    size: 20, color: Colors.white),
                label: const Text(
                  'ارتباط با پشتیبانی',
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
    );
  }

  /// تصویر ۲ — کاربر لاگین کرده: خلاصه طرح + پرداخت (بدون فیلد شماره)
  Widget _buildLoggedInView() {
    return SingleChildScrollView(
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
              _PlanChip(plan: _plan),
              const SizedBox(height: 32),
              Text(
                toFarsiPrice(_plan.price),
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 364),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _isProcessing ? null : _processPurchase,
                        borderRadius: BorderRadius.circular(10),
                        child: Center(
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A1A),
                              height: 1.43,
                            ),
                            child: Text('پرداخت ${toFarsiPrice(_plan.price)}'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'کد تخفیف دارید؟ وارد کردن کد',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => SupportContactSheet.show(context),
                icon: const Icon(Icons.headset_mic_outlined,
                    size: 20, color: Colors.white),
                label: const Text(
                  'ارتباط با پشتیبانی',
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
    );
  }

  Widget _buildGatewayLoading(bool isLoggedIn) {
    final text = isLoggedIn
        ? 'در حال انتقال به درگاه...'
        : 'در حال اتصال به درگاه...';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.plusGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                size: 52, color: AppColors.plusGreen),
          ),
          const SizedBox(height: 28),
          const Text(
            'پرداخت با موفقیت انجام شد',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.plusGreen,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          const Text(
            'اشتراک ویژه شما فعال شد',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 14,
              color: Color(0xFFE0E0E0),
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final SubscriptionPlan plan;

  const _PlanChip({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'اشتراک ${plan.displayName}',
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            toFarsiPrice(plan.price),
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE0E0E0),
            ),
          ),
        ],
      ),
    );
  }
}
