import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfDownloader {
  /// Stores pdf bytes in the documents folder and opens them in the system viewer.
  static Future<File> saveAndOpen(List<int> bytes, String fileName) async {
    final file = await save(bytes, fileName);
    await Process.run('cmd', ['/c', 'start', '', file.path], runInShell: true);
    return file;
  }

  static Future<File> save(List<int> bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}\$fileName.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Hands an already saved pdf to the Windows print flow.
  static Future<void> printFile(File file) async {
    await Process.run(
      'rundll32.exe',
      ['shell32.dll,ShellExec_RunDLL', 'print', file.path],
      runInShell: true,
    );
  }
}
