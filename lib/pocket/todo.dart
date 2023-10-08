import 'dart:convert';

import 'package:cyberme_flutter/pocket/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'config.dart';

class TodoView extends StatefulWidget {
  const TodoView({super.key});

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView> {
  Config? config;
  int start = 0;
  int end = 30;
  Map<String, List<Todo>> data = {};
  List<Todo> todo = [];
  List<Todo> todoFiltered = [];
  Set<String> lists = {};
  Set<String> selectLists = {};

  @override
  void didChangeDependencies() {
    if (config == null) {
      config = Provider.of<Config>(context);
      fetchTodo().then((value) => setState(() {}));
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("待办事项"), centerTitle: true, actions: [
          PopupMenuButton(
              itemBuilder: (c) {
                return lists
                    .map((e) => PopupMenuItem(
                        child: Row(
                          children: [
                            Opacity(
                                opacity: selectLists.contains(e) ? 1 : 0,
                                child: const Icon(Icons.check)),
                            const SizedBox(width: 4),
                            Text(e)
                          ],
                        ),
                        onTap: () {
                          if (selectLists.contains(e)) {
                            selectLists.remove(e);
                          } else {
                            selectLists.add(e);
                          }
                          setState(() {});
                          updateFiltered();
                        }))
                    .toList(growable: false);
              },
              icon: const Icon(Icons.filter_alt))
        ]),
        body: ListView.builder(
            itemBuilder: (c, i) {
              final t = todoFiltered[i];
              return ListTile(
                  title: Text(t.title ?? ""),
                  subtitle: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Row(children: [
                        Text(t.list ?? ""),
                        const Spacer(),
                        Text(dateRich(t.date))
                      ])));
            },
            itemCount: todoFiltered.length));
  }

  dateRich(DateTime? date) {
    if (date == null) return "未知日期";
    final df = DateFormat("yyyy-MM-dd");
    switch (date.weekday) {
      case 1:
        return "${df.format(date)} 周一";
      case 2:
        return "${df.format(date)} 周二";
      case 3:
        return "${df.format(date)} 周三";
      case 4:
        return "${df.format(date)} 周四";
      case 5:
        return "${df.format(date)} 周五";
      case 6:
        return "${df.format(date)} 周六";
      default:
        return "${df.format(date)} 周日";
    }
  }

  updateFiltered() {
    todoFiltered = selectLists.isEmpty
        ? todo
        : todo
            .where((element) => selectLists.contains(element.list))
            .toList(growable: false);
    setState(() {});
  }

  Future fetchTodo() async {
    final r = await get(Uri.parse(Config.todoUrl(start, end)),
        headers: config!.cyberBase64Header);
    final d = jsonDecode(r.body);
    final m = d["message"] ?? "";
    final s = d["status"] as int? ?? -1;
    if (s <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      return;
    }
    data = (d["data"] as Map).map((k, v) {
      final date = k as String;
      final todos = v as List;
      return MapEntry(
          date, todos.map((e) => Todo.fromJson(e)).toList(growable: false));
    });
    todo = [];
    for (final t in data.values) {
      todo.addAll(t);
      for (final tt in t) {
        if (!lists.contains(tt.list) && tt.list != null) {
          lists.add(tt.list!);
        }
      }
    }
    todo.sort((t2, t1) {
      return t1.time?.compareTo(t2.time ?? "") ?? 0;
    });
    updateFiltered();
  }
}
