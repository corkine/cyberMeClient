import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cyberme_flutter/pocket/day.dart';
import 'package:provider/provider.dart';
import 'goods.dart';
import 'link.dart';
import 'config.dart';
import 'auth.dart' as auth;
import 'shortcut.dart' as short;
import 'diary.dart' as diary;
import 'ticket.dart';

class CMPocket {
  static Widget call() => ChangeNotifierProvider(
      create: (c) => Config(),
      child: MaterialApp(
          title: 'CMPocket',
          debugShowCheckedModeBanner: true,
          theme: ThemeData(useMaterial3: true),
          initialRoute: "/",
          routes: {
            "/": (c) => const PocketHome(),
            R.ticketParse.route: (c) => const TicketParsePage(),
            R.ticketShow.route: (c) => const TicketShowPage()
          }));
}

enum R {
  ticketParse,
  ticketShow;

  String get route {
    return "/" + name;
  }
}

class PocketHome extends StatefulWidget {
  const PocketHome({Key? key}) : super(key: key);

  @override
  _PocketHomeState createState() => _PocketHomeState();
}

class _PocketHomeState extends State<PocketHome> {
  int _index = Config.pageIndex;

  /// 决定显示的标题
  Widget _title(Config config) {
    switch (_index) {
      case 0:
        return DayInfo.titleWidget;
      case 1:
        return diary.title;
      case 2:
        return RichText(
            text: TextSpan(text: '短链接', style: Config.headerStyle, children: [
          TextSpan(
              text:
                  ' (最近 ${config.shortURLShowLimit} 天${config.filterDuplicate ? ' 去重' : ''})',
              style: Config.smallHeaderStyle)
        ]));
      case 3:
        return config.useReorderableListView
            ? const Text('拖动条目以排序', style: Config.headerStyle)
            : RichText(
                text: TextSpan(
                    text: '物品管理',
                    style: Config.headerStyle,
                    children: [
                    TextSpan(
                        text: ' ('
                            '${config.notShowRemoved ? '不' : ''}显示删除, '
                            '${config.notShowArchive ? '不' : ''}显示收纳)',
                        style: Config.smallHeaderStyle)
                  ]));
      default:
        return const Text('CM GO');
    }
  }

  /// 决定显示的页面
  _widgets(int index) {
    switch (index) {
      case 0:
        return DayInfo.mainWidget;
      case 1:
        return diary.mainWidget;
      case 2:
        return const QuickLinkPage();
      case 3:
        return const GoodsHome();
      default:
        return Container();
    }
  }

  /// 决定标题栏显示的菜单按钮
  List<Widget> _buildActions(Config config, int index) {
    if (index == 0) return DayInfo.menuActions(context, config);
    if (index == 1) return diary.menuActions(context, config);
    if (index == 2) {
      return [
        PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (e) {
              if (e is int) config.setShortUrlShowLimit(e);
              if (e is bool) config.setFilterDuplicate(!config.filterDuplicate);
            },
            itemBuilder: (c) {
              return [
                [0, '最近 5 天', 5],
                [0, '最近 10 天', 10],
                [0, '最近 20 天', 20],
                [0, '最近 30 天', 30],
                [1, '去除重复项', config.filterDuplicate]
              ].map((List e) {
                if (e[0] == 0) {
                  return PopupMenuItem(child: Text(e[1]), value: e[2]);
                } else {
                  return PopupMenuItem(
                      child: Text(e[2] ? '取消' + e[1] : e[1]), value: e[2]);
                }
              }).toList();
            })
      ];
    } else {
      return config.useReorderableListView
          ? [
              ElevatedButton(
                onPressed: () {
                  final position = config.controller.offset;
                  config.position = position;
                  config.setUseReorderableListView(false);
                },
                child: Row(
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(right: 3),
                      child: Icon(Icons.done),
                    ),
                    Text('确定')
                  ],
                ),
              )
            ]
          : [
              PopupMenuButton<int>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (e) {
                    switch (e) {
                      case 0:
                        config.setGoodsShortByName(!config.goodsShortByName);
                        break;
                      case 1:
                        config.setGoodsRecentFirst(!config.goodsRecentFirst);
                        break;
                      case 2:
                        config.setNotShowClothes(!config.notShowClothes);
                        break;
                      case 3:
                        config.setNotShowRemoved(!config.notShowRemoved);
                        break;
                      case 4:
                        config.setNotShowArchive(!config.notShowArchive);
                        break;
                      case 5:
                        config.setShowUpdateButNotCreateTime(
                            !config.showUpdateButNotCreateTime);
                        break;
                      case 6:
                        config.setAutoCopyToClipboard(
                            !config.autoCopyToClipboard);
                        break;
                      case 7:
                        final position = config.controller.offset;
                        config.position = position;
                        config.setUseReorderableListView(
                            !config.useReorderableListView);
                        break;
                      default:
                        return;
                    }
                  },
                  itemBuilder: (c) {
                    return [
                      /*[0, '按照名称排序', config.goodsShortByName],
                [1, '按照最近排序', config.goodsRecentFirst],*/
                      [2, '显示衣物', !config.notShowClothes],
                      [3, '显示已删除', !config.notShowRemoved],
                      [4, '显示收纳', !config.notShowArchive],
                      [5, '显示更新而非创建日期', config.showUpdateButNotCreateTime],
                      [6, '将链接拷贝到剪贴板', config.autoCopyToClipboard],
                      [7, '排序模式（仅限同状态和重要度项目排序）', config.useReorderableListView]
                    ].map((List e) {
                      return PopupMenuItem(
                          child: Text(e[2] ? '✅ ' + e[1] : '❎ ' + e[1]),
                          value: e[0] as int);
                    }).toList();
                  })
            ];
    }
  }

  /// 主操作按钮
  _callActionButton(Config config, int index) {
    switch (index) {
      case 1:
        diary.mainAction(context, config);
        break;
      case 2:
        showSearch(context: context, delegate: ItemSearchDelegate(config));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext c) {
          return const GoodAdd(null);
        }));
        break;
      default:
        return null;
    }
  }

  Widget _buildActionButtonWidget(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.search);
      case 1:
        return diary.mainButton;
      case 2:
        return const Icon(Icons.search);
      case 3:
        return const Icon(Icons.add);
      default:
        return const Icon(Icons.search);
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
      short.setupQuickAction(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Config>(
        builder: (BuildContext context, Config config, Widget? w) {
      return Scaffold(
          drawer: auth.userMenuDrawer(config, context),
          appBar: AppBar(
              elevation: 7,
              title: _title(config),
              leading: Builder(
                  builder: (BuildContext context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer())),
              centerTitle: true,
              toolbarHeight: Config.toolBarHeight,
              actions: _buildActions(config, _index)),
          floatingActionButton: _index == 0
              ? null
              : FloatingActionButton(
                  onPressed: () => _callActionButton(config, _index),
                  child: _buildActionButtonWidget(_index),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: _widgets(_index),
          bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              items: [
                BottomNavigationBarItem(
                    label: DayInfo.title,
                    icon: const Icon(Icons.calendar_today_outlined),
                    activeIcon: const Icon(Icons.calendar_today)),
                BottomNavigationBarItem(
                    label: diary.buttonTitle,
                    icon: const Icon(Icons.sticky_note_2_outlined),
                    activeIcon: const Icon(Icons.sticky_note_2_rounded)),
                const BottomNavigationBarItem(
                    label: '短链接',
                    icon: Icon(Icons.bookmark_border_rounded),
                    activeIcon: Icon(Icons.bookmark)),
                const BottomNavigationBarItem(
                    label: '物品管理',
                    icon: Icon(Icons.checkroom_outlined),
                    activeIcon: Icon(Icons.checkroom)),
              ]));
    });
  }
}
