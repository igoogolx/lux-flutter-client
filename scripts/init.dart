// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:lux/const/const.dart';

final dio = Dio();

// https://github.com/dart-lang/sdk/issues/31610
final assetsPath = path.normalize(path.join(Platform.script.toFilePath(), '../../assets'));
final binDir = Directory(path.join(assetsPath, 'bin'));

const rawCoreName ='itun2socks';
const rawCoreVersion ='0.4.2';


Future downloadLatestCore() async {
  final String luxCoreName = '${rawCoreName}_${rawCoreVersion}_${LuxCoreName.platform}_${LuxCoreName.arch}';
  print(luxCoreName);

  final info = await dio.get('https://api.github.com/repos/igoogolx/itun2socks/releases/tags/v$rawCoreVersion');
  final Map<String, dynamic> latest = (info.data['assets'] as List<dynamic>).firstWhere((it) => (it['name'] as String).contains(luxCoreName));

  final String name = latest['name'];
  final tempFile = File(path.join(binDir.path, '$name.temp'));

  print('Downloading $name');
  await dio.download(latest['browser_download_url'], tempFile.path);
  print('Download Success');

  print('Unarchiving $name');
  final tempBetys = await tempFile.readAsBytes();
  if (name.contains('.tar.gz')) {
    final tarBytes = GZipDecoder().decodeBytes(tempBetys);
    final file = TarDecoder().decodeBytes(tarBytes).findFile('$rawCoreName${LuxCoreName.ext}');
    final String filePath = path.join(binDir.path, LuxCoreName.name);
    if(file==null){
      throw Exception("No Fount");
    }
    await File(path.join(binDir.path, LuxCoreName.name)).writeAsBytes(file.content);
    await Process.run('chmod', ['+x', filePath]);
  } else {
    final file = ZipDecoder().decodeBytes(tempBetys).findFile('$rawCoreName${LuxCoreName.ext}');
    if(file==null){
      throw Exception("No Fount");
    }
    await File(path.join(binDir.path, LuxCoreName.name)).writeAsBytes(file.content);
  }
  await tempFile.delete();
  print('Unarchive Success');
}




void main() async {
  if (!(await binDir.exists())) await binDir.create();
  await downloadLatestCore();
}
