# Stickers

Put sticker PNGs in this folder or in a category subfolder (Arrow, Emoji, Frame, Like, Memes, Nowruz, Sale, Social Media).

- **Format:** PNG
- **Suggested size:** about 200×200 to 400×400 pixels

The sticker list is built from the files on disk. After you add a new category folder, list it under `assets` in `pubspec.yaml` and rebuild the path list in `lib/models/sticker_item.dart` with:

```bash
find assets/stickers -name '*.png' -type f | sort
```
