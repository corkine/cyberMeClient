import 'dart:convert';
import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:system_tray/system_tray.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart' as pb;

class Util {
  /// 返回常用的时间信息
  static String clock(
      {bool justDate = false,
      bool justSeconds = false,
      bool justBeforeSeconds = false}) {
    var now = DateTime.now().toLocal();
    if (justDate) {
      return sprintf("%04d-%02d-%02d", [now.year, now.month, now.day]);
    } else if (justSeconds) {
      return sprintf("%02d", [now.second]);
    } else if (justBeforeSeconds) {
      return sprintf("%02d-%02d-%02d %02d:%02d:",
          [now.year, now.month, now.day, now.hour, now.minute]);
    } else {
      return sprintf("%02d-%02d-%02d %02d:%02d",
          [now.year, now.month, now.day, now.hour, now.minute]);
    }
  }

  /// 采样时间为上午，则不显示采样信息，采样时间为下午才显示采样信息
  static String? pickTime() {
    var now = DateTime.now().toLocal();

    /// 暂时不显示 核酸已采样 字样
    if (false && now.hour >= 12) {
      return clock(justDate: true);
    } else {
      return null;
    }
  }

  static Widget waiting = const Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
        CircularProgressIndicator(),
        Padding(
          padding: EdgeInsets.all(18.0),
          child: Text('正在检索数据'),
        )
      ]));

  static const pt10 = Padding(padding: EdgeInsets.only(top: 10));
  static const pt20 = Padding(padding: EdgeInsets.only(top: 20));
  static const pt30 = Padding(padding: EdgeInsets.only(top: 30));
  static const pl10 = Padding(padding: EdgeInsets.only(left: 10));
  static const Padding pl20 = Padding(padding: EdgeInsets.only(left: 20));
  static const pl30 = Padding(padding: EdgeInsets.only(left: 30));
  static const Padding pa10 = Padding(padding: EdgeInsets.all(10));
  static const pa20 = Padding(padding: EdgeInsets.all(20));
  static const Padding pa30 = Padding(padding: EdgeInsets.all(30));
}

late AppWindow appWindow;

Future<void> initSystemTray() async {
  String path = Platform.isWindows
      ? 'images/tray/app_icon.ico'
      : 'images/tray/app_icon.png';

  appWindow = AppWindow();
  final SystemTray systemTray = SystemTray();

  await systemTray.initSystemTray(iconPath: path);

  final Menu menu = Menu();
  await menu.buildFrom([
    SubMenu(
        label: "关于此应用",
        children: [MenuItemLabel(label: '关于应用', onClicked: (a) {})]),
    MenuItemLabel(
        label: '剪贴板图片上传',
        onClicked: (menuItem) => readClipboardAndUploadImage()),
    MenuItemLabel(
        label: 'Web 版本',
        onClicked: (a) => launchUrlString("https://cyber.mazhangjing.com")),
    MenuSeparator(),
    MenuItemLabel(label: '显示', onClicked: (_) => appWindow.show()),
    MenuItemLabel(label: '隐藏', onClicked: (_) => appWindow.hide()),
    MenuItemLabel(label: '退出', onClicked: (_) => exit(0))
  ]);

  // set context menu
  await systemTray.setContextMenu(menu);

  // handle system tray event
  systemTray.registerSystemTrayEventHandler((eventName) {
    if (eventName == kSystemTrayEventClick) {
      appWindow.show();
    } else if (eventName == kSystemTrayEventRightClick) {
      systemTray.popUpContextMenu();
    }
  });
}

void readClipboardAndUploadImage() async {
  //read clipboard's image
  var files = await pb.Pasteboard.files();
  if (files.isNotEmpty &&
      (files.first.endsWith(".png") ||
          files.first.endsWith(".jpg") ||
          files.first.endsWith(".bmp") ||
          files.first.endsWith(".jpeg") ||
          files.first.endsWith(".gif"))) {
    debugPrint("handling image... ${files.first}");
    var uri = Uri.parse(
        "https://cyber.mazhangjing.com/api/files/upload?secret=i_am_cool");
    var req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', files.first));
    var response = await http.Response.fromStream(await req.send());
    var body = jsonDecode(response.body);
    debugPrint(body.toString());
    var url = body["data"] as String;
    FlutterClipboard.copy(url);
  }
}
