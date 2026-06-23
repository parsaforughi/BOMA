import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fa')
  ];

  /// No description provided for @appName.
  ///
  /// In fa, this message translates to:
  /// **'BOMA'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In fa, this message translates to:
  /// **'خانه'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات'**
  String get settings;

  /// No description provided for @premium.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک ویژه'**
  String get premium;

  /// No description provided for @purchase.
  ///
  /// In fa, this message translates to:
  /// **'خرید'**
  String get purchase;

  /// No description provided for @login.
  ///
  /// In fa, this message translates to:
  /// **'ورود'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In fa, this message translates to:
  /// **'خروج از حساب'**
  String get logout;

  /// No description provided for @back.
  ///
  /// In fa, this message translates to:
  /// **'بازگشت'**
  String get back;

  /// No description provided for @save.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fa, this message translates to:
  /// **'لغو'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fa, this message translates to:
  /// **'تایید'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In fa, this message translates to:
  /// **'بستن'**
  String get close;

  /// No description provided for @done.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد'**
  String get done;

  /// No description provided for @error.
  ///
  /// In fa, this message translates to:
  /// **'خطا'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fa, this message translates to:
  /// **'موفقیت'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In fa, this message translates to:
  /// **'در حال بارگذاری...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In fa, this message translates to:
  /// **'تلاش مجدد'**
  String get retry;

  /// No description provided for @phoneNumber.
  ///
  /// In fa, this message translates to:
  /// **'شماره موبایل'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In fa, this message translates to:
  /// **'مثلا ۰۹۱۲۱۲۳۴۵۶۷'**
  String get phoneHint;

  /// No description provided for @phoneRequired.
  ///
  /// In fa, this message translates to:
  /// **'شماره موبایل الزامی است.'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In fa, this message translates to:
  /// **'شماره موبایل معتبر نیست.'**
  String get phoneInvalid;

  /// No description provided for @enterPhone.
  ///
  /// In fa, this message translates to:
  /// **'شماره همراه خود را وارد کنید'**
  String get enterPhone;

  /// No description provided for @sendCode.
  ///
  /// In fa, this message translates to:
  /// **'دریافت کد'**
  String get sendCode;

  /// No description provided for @verifyCode.
  ///
  /// In fa, this message translates to:
  /// **'تایید کد'**
  String get verifyCode;

  /// No description provided for @otpTitle.
  ///
  /// In fa, this message translates to:
  /// **'کد تایید'**
  String get otpTitle;

  /// No description provided for @otpSent.
  ///
  /// In fa, this message translates to:
  /// **'کد به شماره {phone} ارسال شد'**
  String otpSent(String phone);

  /// No description provided for @resendCode.
  ///
  /// In fa, this message translates to:
  /// **'ارسال مجدد کد'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In fa, this message translates to:
  /// **'ارسال مجدد تا {seconds} ثانیه'**
  String resendIn(String seconds);

  /// No description provided for @contactSupport.
  ///
  /// In fa, this message translates to:
  /// **'ارتباط با پشتیبانی'**
  String get contactSupport;

  /// No description provided for @orContactSupport.
  ///
  /// In fa, this message translates to:
  /// **'یا با پشتیبانی تماس بگیرید'**
  String get orContactSupport;

  /// No description provided for @font.
  ///
  /// In fa, this message translates to:
  /// **'فونت'**
  String get font;

  /// No description provided for @style.
  ///
  /// In fa, this message translates to:
  /// **'قالب'**
  String get style;

  /// No description provided for @color.
  ///
  /// In fa, this message translates to:
  /// **'رنگ'**
  String get color;

  /// No description provided for @colors.
  ///
  /// In fa, this message translates to:
  /// **'رنگ‌ها'**
  String get colors;

  /// No description provided for @background.
  ///
  /// In fa, this message translates to:
  /// **'بک گراند'**
  String get background;

  /// No description provided for @backgroundColors.
  ///
  /// In fa, this message translates to:
  /// **'رنگ پس‌زمینه'**
  String get backgroundColors;

  /// No description provided for @sticker.
  ///
  /// In fa, this message translates to:
  /// **'استیکر'**
  String get sticker;

  /// No description provided for @history.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه'**
  String get history;

  /// No description provided for @effects.
  ///
  /// In fa, this message translates to:
  /// **'افکت‌ها'**
  String get effects;

  /// No description provided for @text.
  ///
  /// In fa, this message translates to:
  /// **'متن'**
  String get text;

  /// No description provided for @writeText.
  ///
  /// In fa, this message translates to:
  /// **'متنت رو بنویس'**
  String get writeText;

  /// No description provided for @fontSize.
  ///
  /// In fa, this message translates to:
  /// **'اندازه فونت'**
  String get fontSize;

  /// No description provided for @letterSpacing.
  ///
  /// In fa, this message translates to:
  /// **'فاصله حروف'**
  String get letterSpacing;

  /// No description provided for @wordSpacing.
  ///
  /// In fa, this message translates to:
  /// **'فاصله کلمات'**
  String get wordSpacing;

  /// No description provided for @lineHeight.
  ///
  /// In fa, this message translates to:
  /// **'فاصله خطوط'**
  String get lineHeight;

  /// No description provided for @opacity.
  ///
  /// In fa, this message translates to:
  /// **'شفافیت'**
  String get opacity;

  /// No description provided for @fontWeight.
  ///
  /// In fa, this message translates to:
  /// **'ضخامت فونت'**
  String get fontWeight;

  /// No description provided for @alignment.
  ///
  /// In fa, this message translates to:
  /// **'تراز متن'**
  String get alignment;

  /// No description provided for @alignLeft.
  ///
  /// In fa, this message translates to:
  /// **'چپ‌چین'**
  String get alignLeft;

  /// No description provided for @alignCenter.
  ///
  /// In fa, this message translates to:
  /// **'وسط‌چین'**
  String get alignCenter;

  /// No description provided for @alignRight.
  ///
  /// In fa, this message translates to:
  /// **'راست‌چین'**
  String get alignRight;

  /// No description provided for @stroke.
  ///
  /// In fa, this message translates to:
  /// **'خط دور'**
  String get stroke;

  /// No description provided for @shadow.
  ///
  /// In fa, this message translates to:
  /// **'سایه'**
  String get shadow;

  /// No description provided for @bubble.
  ///
  /// In fa, this message translates to:
  /// **'حباب'**
  String get bubble;

  /// No description provided for @gradient.
  ///
  /// In fa, this message translates to:
  /// **'گرادیان'**
  String get gradient;

  /// No description provided for @filter.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر'**
  String get filter;

  /// No description provided for @allFonts.
  ///
  /// In fa, this message translates to:
  /// **'همه فونت‌ها'**
  String get allFonts;

  /// No description provided for @favoriteFonts.
  ///
  /// In fa, this message translates to:
  /// **'علاقه‌مندی‌ها'**
  String get favoriteFonts;

  /// No description provided for @standardFonts.
  ///
  /// In fa, this message translates to:
  /// **'ساده'**
  String get standardFonts;

  /// No description provided for @fancyFonts.
  ///
  /// In fa, this message translates to:
  /// **'فانتزی'**
  String get fancyFonts;

  /// No description provided for @formalFonts.
  ///
  /// In fa, this message translates to:
  /// **'رسمی'**
  String get formalFonts;

  /// No description provided for @saveToGallery.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره در گالری'**
  String get saveToGallery;

  /// No description provided for @shareToInstagram.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک در اینستاگرام'**
  String get shareToInstagram;

  /// No description provided for @shareToWhatsapp.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک در واتساپ'**
  String get shareToWhatsapp;

  /// No description provided for @shareToTelegram.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک در تلگرام'**
  String get shareToTelegram;

  /// No description provided for @copyImage.
  ///
  /// In fa, this message translates to:
  /// **'کپی تصویر'**
  String get copyImage;

  /// No description provided for @download.
  ///
  /// In fa, this message translates to:
  /// **'دانلود'**
  String get download;

  /// No description provided for @savedSuccess.
  ///
  /// In fa, this message translates to:
  /// **'با موفقیت ذخیره شد'**
  String get savedSuccess;

  /// No description provided for @shareSuccess.
  ///
  /// In fa, this message translates to:
  /// **'با موفقیت ارسال شد'**
  String get shareSuccess;

  /// No description provided for @language.
  ///
  /// In fa, this message translates to:
  /// **'زبان'**
  String get language;

  /// No description provided for @languageFarsi.
  ///
  /// In fa, this message translates to:
  /// **'فارسی'**
  String get languageFarsi;

  /// No description provided for @languageArabic.
  ///
  /// In fa, this message translates to:
  /// **'عربی'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In fa, this message translates to:
  /// **'انگلیسی'**
  String get languageEnglish;

  /// No description provided for @upgradeToPro.
  ///
  /// In fa, this message translates to:
  /// **'ارتقاء به نسخه حرفه‌ای'**
  String get upgradeToPro;

  /// No description provided for @proFeatures.
  ///
  /// In fa, this message translates to:
  /// **'امکانات ویژه'**
  String get proFeatures;

  /// No description provided for @selectPlan.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب گزینه اشتراک'**
  String get selectPlan;

  /// No description provided for @month1.
  ///
  /// In fa, this message translates to:
  /// **'۱ ماهه'**
  String get month1;

  /// No description provided for @month3.
  ///
  /// In fa, this message translates to:
  /// **'۳ ماهه'**
  String get month3;

  /// No description provided for @month6.
  ///
  /// In fa, this message translates to:
  /// **'۶ ماهه'**
  String get month6;

  /// No description provided for @month12.
  ///
  /// In fa, this message translates to:
  /// **'۱۲ ماهه'**
  String get month12;

  /// No description provided for @toman.
  ///
  /// In fa, this message translates to:
  /// **'تومان'**
  String get toman;

  /// No description provided for @discount.
  ///
  /// In fa, this message translates to:
  /// **'تخفیف'**
  String get discount;

  /// No description provided for @payNow.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت'**
  String get payNow;

  /// No description provided for @paymentSuccess.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت با موفقیت انجام شد'**
  String get paymentSuccess;

  /// No description provided for @paymentFailed.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت با مشکلی مواجه شد'**
  String get paymentFailed;

  /// No description provided for @proExpiry.
  ///
  /// In fa, this message translates to:
  /// **'پایان اشتراک'**
  String get proExpiry;

  /// No description provided for @freeVersion.
  ///
  /// In fa, this message translates to:
  /// **'نسخه رایگان'**
  String get freeVersion;

  /// No description provided for @proVersion.
  ///
  /// In fa, this message translates to:
  /// **'نسخه حرفه‌ای'**
  String get proVersion;

  /// No description provided for @locked.
  ///
  /// In fa, this message translates to:
  /// **'قفل'**
  String get locked;

  /// No description provided for @splashTitle.
  ///
  /// In fa, this message translates to:
  /// **'BOMA'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'استوری ساز حرفه‌ای'**
  String get splashSubtitle;

  /// No description provided for @noHistory.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه‌ای وجود ندارد'**
  String get noHistory;

  /// No description provided for @saveCurrentDraft.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره پیش‌نویس فعلی'**
  String get saveCurrentDraft;

  /// No description provided for @appVersion.
  ///
  /// In fa, this message translates to:
  /// **'نسخه برنامه'**
  String get appVersion;

  /// No description provided for @support.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبانی'**
  String get support;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
