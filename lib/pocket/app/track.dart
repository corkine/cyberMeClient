import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../config.dart';
import '../models/track.dart';

class TrackView extends StatefulWidget {
  const TrackView({super.key});

  @override
  State<TrackView> createState() => _TrackViewState();
}

Future call() async {}

class _TrackViewState extends State<TrackView> {
  Config? config;

  @override
  void didChangeDependencies() {
    if (config == null) {
      config = Provider.of<Config>(context);
      fetchSvc(config!).then((value) => setState(() {
            data = value;
          }));
    }
    super.didChangeDependencies();
  }

  List<(String, String)> data = [];

  bool justShowTrack = true;

  bool sortByUrl = false;

  @override
  Widget build(BuildContext context) {
    var d = justShowTrack
        ? data
            .where((element) => element.$1.startsWith("/cyber/go/track"))
            .toList(growable: false)
        : data;
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Track System"),
          actions: [
            IconButton(
                onPressed: () => setState(() {
                      sortByUrl = !sortByUrl;
                      if (sortByUrl) {
                        data.sort((a, b) => b.$1.compareTo(a.$1));
                      } else {
                        data.sort((a, b) =>
                            int.parse(b.$2).compareTo(int.parse(a.$2)));
                      }
                    }),
                icon: Icon(sortByUrl
                    ? Icons.sort_by_alpha
                    : Icons.format_list_numbered)),
            IconButton(
                onPressed: () => setState(() => justShowTrack = !justShowTrack),
                icon: Icon(
                    justShowTrack ? Icons.filter_alt_off : Icons.filter_alt))
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            data = await fetchSvc(config!);
            debugPrint("reload svc done!");
          },
          child: ListView.builder(
              itemBuilder: (ctx, idx) {
                final c = d[idx];
                return ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text(c.$1),
                    subtitle: Text(c.$2),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) =>
                            TrackDetailView(url: c.$1, count: c.$2))));
              },
              itemCount: d.length),
        ));
  }

  Future<List<(String, String)>> fetchSvc(Config config) async {
    final Response r = await get(Uri.parse(Config.visitsUrl),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    if ((d["status"] as int?) == 1) {
      final res = (d["data"] as List)
          .map((e) => e as List)
          .map((e) => (e.first.toString(), e.last.toString()))
          .toList(growable: false);
      if (sortByUrl) {
        res.sort((a, b) {
          return a.$1.compareTo(b.$1);
        });
      } else {
        res.sort((a, b) {
          return int.parse(b.$2).compareTo(int.parse(a.$2));
        });
      }
      return res;
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(d["message"])));
      return [];
    }
  }
}

class TrackDetailView extends StatefulWidget {
  final String url;
  final String count;

  const TrackDetailView({super.key, required this.url, required this.count});

  @override
  State<TrackDetailView> createState() => _TrackDetailViewState();
}

class _TrackDetailViewState extends State<TrackDetailView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime today;
  Config? config;

  @override
  void initState() {
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    weekDayOne = now.subtract(Duration(
        days: now.weekday - 1,
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond));
    lastWeekDayOne = weekDayOne.subtract(const Duration(days: 7));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (config == null) {
      config = Provider.of<Config>(context);
      fetchDetail(config!).then((value) => setState(() {
            logs = value?.logs ?? [];
            isTrack = value?.monitor ?? false;
          }));
    }
    super.didChangeDependencies();
  }

  List<Logs> logs = [];
  bool isTrack = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.url.split("/").last),
          actions: [
            IconButton(
                onPressed: () async {
                  await setTrack(config!, widget.url, !isTrack);
                  final d = await fetchDetail(config!);
                  logs = d?.logs ?? [];
                  isTrack = d?.monitor ?? false;
                  setState(() {});
                },
                icon: Icon(isTrack
                    ? Icons.visibility
                    : Icons.visibility_off_outlined)),
            IconButton(
                onPressed: () async {
                  await handleAddShortLink(config!);
                  setState(() {});
                },
                icon:
                    const RotatedBox(quarterTurns: 1, child: Icon(Icons.link)))
          ],
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              final d = await fetchDetail(config!);
              logs = d?.logs ?? [];
              debugPrint("reload svc details done!");
            },
            child: ListView.builder(
                itemBuilder: (ctx, idx) {
                  final c = logs[idx];
                  return ListTile(
                      visualDensity: VisualDensity.compact,
                      onTap: () async {
                        await FlutterClipboard.copy(c.ip ?? "");
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("已拷贝地址到剪贴板")));
                      },
                      onLongPress: () async {
                        await launchUrlString(
                            "https://www.ipshudi.com/${c.ip}.htm");
                      },
                      title: Text(c.ip ?? "No IP"),
                      subtitle: dateRich(c.timestamp?.split(".").first),
                      trailing: Text(c.ipInfo ?? ""));
                },
                itemCount: logs.length)));
  }

  Future<Track?> fetchDetail(Config config) async {
    final Response r = await get(
        Uri.parse(Config.logsUrl(base64Encode(utf8.encode(widget.url)))),
        headers: config.cyberBase64Header);
    final d = jsonDecode(r.body);
    if ((d["status"] as int?) == 1) {
      return Track.fromJson(d["data"]);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(d["message"])));
      return null;
    }
  }

  Future setTrack(Config config, String key, bool trackStatus) async {
    final r = await post(Uri.parse(Config.trackUrl),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({"key": "visit:" + key, "add": trackStatus}));
    final data = jsonDecode(r.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(data["message"])));
  }

  Future handleAddShortLink(Config config) async {
    final kw = TextEditingController();
    var overwrite = false;
    var keyword = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text("请输入短链接关键字"),
                content: StatefulBuilder(
                    builder: (c, setState) =>
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(
                            controller: kw,
                            decoration: const InputDecoration(
                                labelText: "短链",
                                prefix: Text("go.mazhangjing.com/")),
                          ),
                          const SizedBox(height: 10),
                          Transform.translate(
                              offset: const Offset(-5, 0),
                              child: Row(children: [
                                Checkbox(
                                    value: overwrite,
                                    onChanged: (v) => setState(() {
                                          overwrite = v!;
                                        })),
                                const Text("覆盖现有关键字")
                              ]))
                        ])),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(kw.text);
                      },
                      child: const Text("确定"))
                ]),
        barrierDismissible: false);
    if (keyword!.isEmpty) return;
    final r = await post(Uri.parse(Config.goPostUrl),
        headers: config.cyberBase64JsonContentHeader,
        body: jsonEncode({
          "keyword": keyword,
          "redirectURL":
              "https://cyber.mazhangjing.com/visits/${base64Encode(utf8.encode(widget.url))}/logs",
          "note": "由 CyberMe Flutter 添加",
          "override": overwrite
        }));
    final d = jsonDecode(r.body);
    final m = d["message"] ?? "没有消息";
    final s = (d["status"] as int?) ?? -1;
    var fm = m;
    if (s > 0) {
      await FlutterClipboard.copy("https://go.mazhangjing.com/$keyword");
      fm = fm + "，已将链接拷贝到剪贴板。";
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(fm),
        action: SnackBarAction(label: "OK", onPressed: () {})));
  }

  Widget dateRich(String? date) {
    if (date == null) return const Text("未知日期");
    final date1 = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(date);
    final df = DateFormat("yyyy-MM-dd HH:mm");
    bool isToday = !today.isAfter(date1);
    bool thisWeek = !weekDayOne.isAfter(date1);
    bool lastWeek = !thisWeek && !lastWeekDayOne.isAfter(date1);
    final style = TextStyle(
        decoration: isToday ? TextDecoration.underline : null,
        decorationColor: Colors.lightGreen,
        color: isToday
            ? Colors.lightGreen
            : thisWeek
                ? Colors.lightGreen
                : lastWeek
                    ? Colors.blueGrey
                    : Colors.grey);
    switch (date1.weekday) {
      case 1:
        return Text("${df.format(date1)} 周一", style: style);
      case 2:
        return Text("${df.format(date1)} 周二", style: style);
      case 3:
        return Text("${df.format(date1)} 周三", style: style);
      case 4:
        return Text("${df.format(date1)} 周四", style: style);
      case 5:
        return Text("${df.format(date1)} 周五", style: style);
      case 6:
        return Text("${df.format(date1)} 周六", style: style);
      default:
        return Text("${df.format(date1)} 周日", style: style);
    }
  }
}
