import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_features.dart';
import '../../theme/colors.dart';
import '../../models/subscription_plan.dart';
import '../../services/auth_service.dart';
import '../../utils/farsi_utils.dart';
import '../../widgets/support_contact_sheet.dart';
import '../../widgets/back_arrow_icon.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String? _selectedPlanId;

  @override
  Widget build(BuildContext context) {
    if (kAllFeaturesFreeForNow) {
      return _buildAllFreeView();
    }

    final authState = ref.watch(authProvider);
    final isPro = authState.isPro;
    final isLoggedIn = authState.isLoggedIn;

    // تصویر ۲ — ارتقا وقتی کاربر لاگین کرده: لوگو، طرح‌ها، تخفیف، پشتیبانی
    if (isLoggedIn && !isPro) {
      return _buildLoggedInUpgradeView();
    }

    // مهمان یا قبلاً پرو: همان محتوا با گرادیان و وسط‌چین (یکدست با لاگین/خرید)
    if (isPro) {
      return _buildProAlreadyView();
    }
    return _buildGuestUpgradeView();
  }

  /// فعلاً همه امکانات رایگان — بدون طرح اشتراک.
  Widget _buildAllFreeView() {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/icons/boma_logo.png',
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'ارتقای حساب',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Text(
                          'عشق و حال به راه! می‌تونی از همه امکانات رایگان استفاده کنی ❤️',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

  /// صفحه اشتراک ویژه برای مهمان — گرادیان، وسط عمودی/افقی، ادامه و پرداخت
  Widget _buildGuestUpgradeView() {
    return Scaffold(
      body: Container(
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
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/icons/boma_logo.png',
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ارتقاء به نسخه حرفه‌ای',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'به همه فونت‌ها، افکت‌ها و امکانات دسترسی داشته باشید',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 14,
                              color: Color(0xFFE0E0E0),
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const SizedBox(
                            width: double.infinity,
                            child: Text(
                              'بدون محدودیت وتبلیغ از تمامی امکانات بوما استفاده کنید',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'انتخاب گزینه اشتراک',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...SubscriptionPlan.plans.map((plan) => _LoggedInPlanCard(
                              plan: plan,
                              isSelected: _selectedPlanId == plan.id,
                              onTap: () => setState(() => _selectedPlanId = plan.id),
                            )),
                        const SizedBox(height: 24),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 364),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: Material(
                                color: _selectedPlanId != null
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  onTap: _selectedPlanId != null
                                      ? () => context.push('/purchase', extra: _selectedPlanId)
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Center(
                                    child: DefaultTextStyle(
                                      style: TextStyle(
                                        fontFamily: 'Vazir',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedPlanId != null
                                            ? const Color(0xFF1A1A1A)
                                            : const Color(0xFFE0E0E0),
                                      ),
                                      child: const Text('ادامه و پرداخت'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
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

  /// کاربر قبلاً اشتراک ویژه دارد
  Widget _buildProAlreadyView() {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.plusGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.plusGreen.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.plusGreen, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'شما اشتراک ویژه دارید',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 16,
                          color: AppColors.plusGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

  /// تصویر ۲ — وقتی کاربر لاگین کرده: پس‌زمینه گرادیان، لوگو باما، طرح‌ها با هایلایت زرد، خرید/پرداخت، کد تخفیف، پشتیبانی
  Widget _buildLoggedInUpgradeView() {
    SubscriptionPlan? selectedPlan;
    if (_selectedPlanId != null) {
      try {
        selectedPlan = SubscriptionPlan.plans
            .firstWhere((p) => p.id == _selectedPlanId);
      } catch (_) {}
    }

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    // لوگو باما
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/icons/boma_logo.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'boma',
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // کارت‌های اشتراک با هایلایت زرد وقتی انتخاب شده
                    ...SubscriptionPlan.plans.map((plan) {
                      final isSelected = _selectedPlanId == plan.id;
                      return _LoggedInPlanCard(
                        plan: plan,
                        isSelected: isSelected,
                        onTap: () =>
                            setState(() => _selectedPlanId = plan.id),
                      );
                    }),
                    const SizedBox(height: 24),
                    // دکمه خرید اشتراک / پرداخت X تومان
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Material(
                        color: selectedPlan != null
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: selectedPlan != null
                              ? () => context.push('/purchase',
                                  extra: selectedPlan!.id)
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: DefaultTextStyle(
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: selectedPlan != null
                                    ? const Color(0xFF1A1A1A)
                                    : const Color(0xFFE0E0E0),
                                height: 1.43,
                              ),
                              child: Text(
                                selectedPlan != null
                                    ? 'پرداخت ${toFarsiPrice(selectedPlan.price)}'
                                    : 'خرید اشتراک',
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
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

class _LoggedInPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoggedInPlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF5C842).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF5C842)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF5C842)
                      : Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFF5C842) : null,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 16, color: Color(0xFF171F36)),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                plan.displayName,
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
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
      ),
    );
  }
}
