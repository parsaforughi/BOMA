/// Resolves the dedicated picker covers shipped with BOMA.
///
/// A missing cover intentionally returns `null` so the picker can fall back to
/// the original style preview or the first sticker in a category.
class CoverAssetResolver {
  const CoverAssetResolver._();

  static const Map<String, String> _stickerCategoryCovers = {
    'Arrow': 'assets/covers/stickers/arrow.png',
    'Emoji': 'assets/covers/stickers/emoji.png',
    'Favorite': 'assets/covers/stickers/favorite.png',
    'Frame': 'assets/covers/stickers/frame.png',
    'Like': 'assets/covers/stickers/like.png',
    'Memes': 'assets/covers/stickers/memes.png',
    'Nowruz': 'assets/covers/stickers/nowruz.png',
    'Sale': 'assets/covers/stickers/sale.png',
    'Social Media': 'assets/covers/stickers/social_media.png',
  };

  static String? stickerCategoryCover(String category) =>
      _stickerCategoryCovers[category];

  /// کاورِ سطح فقط به شناسهٔ «پایه» داده می‌شود، نه به واریانت‌های آن.
  ///
  /// الگوی قبلی `_l(\d+)(?:_|$)` پسوندهای واریانت را نادیده می‌گرفت، پس
  /// `beg_p2_l1`، `beg_p2_l1_r_bw`، `beg_p2_l1_f_bw` و `beg_p2_l1_f_wb`
  /// هر چهارتا یک کاور می‌گرفتند و در پیکر یکسان دیده می‌شدند. حالا
  /// واریانت‌ها به previewAsset اختصاصی خودشان برمی‌گردند.
  static String? styleCoverForId(String id) {
    final beginnerPack1 = _level(id, r'^beg_p1_l(\d+)$');
    if (beginnerPack1 != null && beginnerPack1 <= 5) {
      return 'assets/covers/styles/update1_beg_p1_$beginnerPack1.jpg';
    }

    final beginnerPack2 = _level(id, r'^beg_p2_l(\d+)$');
    if (beginnerPack2 != null && beginnerPack2 <= 5) {
      return 'assets/covers/styles/update1_beg_p2_$beginnerPack2.jpg';
    }

    final intermediate = _level(id, r'^int_l(\d+)$');
    if (intermediate != null && intermediate <= 10) {
      return 'assets/covers/styles/update1_int_$intermediate.jpg';
    }

    final advanced = _level(id, r'^adv_l(\d+)$');
    if (advanced != null && advanced <= 18 && advanced != 13) {
      return 'assets/covers/styles/update1_adv_$advanced.jpg';
    }

    final instagramTag = _level(id, r'^tag_id_(\d+)$');
    if (instagramTag != null && instagramTag <= 10 && instagramTag != 6) {
      return 'assets/covers/styles/update1_tag_$instagramTag.jpg';
    }

    // These mappings make the supplied Update 2 covers ready for their style
    // definitions once those packs are imported into the catalog.
    final beginnerPack3 = _level(id, r'^beg_p3_l(\d+)$');
    if (beginnerPack3 != null && beginnerPack3 <= 5) {
      return 'assets/covers/styles/update2_beg_p3_$beginnerPack3.jpg';
    }
    final update2Intermediate = _level(id, r'^update2_int_l(\d+)(?:_|$)');
    if (update2Intermediate != null && update2Intermediate <= 4) {
      return 'assets/covers/styles/update2_int_$update2Intermediate.jpg';
    }
    final callout = _level(id, r'^call_?out_l?(\d+)$');
    if (callout != null && callout <= 10) {
      return 'assets/covers/styles/update2_callout_$callout.jpg';
    }
    final appNotification = _level(id, r'^app_notif_l?(\d+)$');
    if (appNotification != null && appNotification <= 4) {
      return 'assets/covers/styles/update2_app_notif_$appNotification.jpg';
    }

    return null;
  }

  static int? _level(String id, String pattern) {
    final match = RegExp(pattern).firstMatch(id);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
