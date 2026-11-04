import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Offline cache for سعد الغامدی verse MP3s (everyayah Ghamadi_40kbps).
class GhamdiAudioCache {
  GhamdiAudioCache._();
  static final instance = GhamdiAudioCache._();

  static const cdn = 'https://everyayah.com/data/Ghamadi_40kbps';

  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/audio/ghamdi');
    if (!await d.exists()) await d.create(recursive: true);
    return _dir = d;
  }

  /// everyayah SSSAAA code from `s:a` or `bismillah`.
  static String verseCode(String verseKey) {
    if (verseKey == 'bismillah') return '001001';
    final parts = verseKey.split(':');
    final surah = int.parse(parts[0]);
    final ayah = int.parse(parts[1]);
    return '${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}';
  }

  static String cdnUrl(String verseKey) => '$cdn/${verseCode(verseKey)}.mp3';

  Future<File> _fileFor(String verseKey) async {
    final d = await _cacheDir();
    return File('${d.path}/${verseCode(verseKey)}.mp3');
  }

  Future<String?> localPath(String verseKey) async {
    final f = await _fileFor(verseKey);
    if (await f.exists() && await f.length() > 1000) return f.path;
    return null;
  }

  /// Download to cache; returns local path or null on failure.
  Future<String?> ensureCached(String verseKey) async {
    final existing = await localPath(verseKey);
    if (existing != null) return existing;
    final f = await _fileFor(verseKey);
    final tmp = File('${f.path}.part');
    try {
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(cdnUrl(verseKey)));
        req.headers.set(HttpHeaders.userAgentHeader, 'ZekrApp/1.0');
        final res = await req.close().timeout(const Duration(seconds: 30));
        if (res.statusCode != 200) return null;
        final sink = tmp.openWrite();
        await res.pipe(sink);
        await sink.close();
        if (await tmp.length() < 1000) {
          await tmp.delete();
          return null;
        }
        if (await f.exists()) await f.delete();
        await tmp.rename(f.path);
        return f.path;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      return null;
    }
  }
}
