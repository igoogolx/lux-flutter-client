import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:system_tray/system_tray.dart';
import 'package:lux/const/const.dart';
import 'package:path/path.dart' as path;

Process? process;

Future<void> copyAssetToFile(String assetPath, String filePath) async {
  final byteData = await rootBundle.load(assetPath);
  final bytes = byteData.buffer.asUint8List();

  // Write the file to disk
  await File(filePath).writeAsBytes(bytes);
}

Future<int> findAvailablePort(int startPort, int endPort) async {
  for (int port = startPort; port <= endPort; port++) {
    try {
      final serverSocket =
      await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await serverSocket.close();
      return port;
    } catch (e) {
      // Port is not available
    }
  }
  throw Exception('No available port found in range $startPort-$endPort');
}

Future<void> initSystemTray(Function openDashboard, exit) async {
  String path =
  Platform.isWindows ? 'assets/app_icon.ico' : 'assets/tray.png';

  final SystemTray systemTray = SystemTray();

  // We first init the systray menu
  await systemTray.initSystemTray(
    iconPath: path,
  );
  systemTray.setToolTip("Lux Flutter");

  // create context menu
  final Menu menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(label: 'Lux', enabled: false),
    MenuItemLabel(label: 'Show', onClicked: (menuItem) => openDashboard()),
    MenuItemLabel(label: 'Exit', onClicked: (menuItem) => exit()),
  ]);

  // set context menu
  await systemTray.setContextMenu(menu);

  // handle system tray event
  systemTray.registerSystemTrayEventHandler((eventName) {
    debugPrint("eventName: $eventName");
    if (eventName == kSystemTrayEventClick) {
      Platform.isWindows ? openDashboard() : systemTray.popUpContextMenu();
    } else if (eventName == kSystemTrayEventRightClick) {
      Platform.isWindows ? systemTray.popUpContextMenu() : openDashboard();
    }
  });
}

void exitApp() {
  process?.kill();
  exit(0);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final port = await findAvailablePort(8000, 9000);
  final Directory appDocumentsDir = await getApplicationSupportDirectory();
  process =
  await Process.start(path.join(Paths.assetsBin.path, LuxCoreName.name), ['-home_dir=${appDocumentsDir.path}', '-port=$port']);
  final Uri url = Uri.parse('http://localhost:$port');
  process?.stdout.transform(utf8.decoder).forEach(debugPrint);

  void openDashboard(){
    launchUrl(url);
  }
  openDashboard();
  initSystemTray(openDashboard, exitApp);
  ProcessSignal.sigint.watch().listen((signal) {
    // Run your function here before exiting
    process?.kill();
  });
}
