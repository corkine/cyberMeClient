import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../viewmodels/image.dart';
import '../../util.dart';

class RegistryView extends ConsumerStatefulWidget {
  const RegistryView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegistryViewState();
}

class _RegistryViewState extends ConsumerState<RegistryView> {
  final bg1 = Container(
      color: Colors.red,
      child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
              padding: EdgeInsets.only(right: 20),
              child: Text("删除",
                  style: TextStyle(color: Colors.white, fontSize: 15)))));
  final bg2 = Container(
      color: Colors.blue,
      child: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text("编辑",
                  style: TextStyle(color: Colors.white, fontSize: 15)))));
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(getRegistryProvider).value ?? [];
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return Dismissible(
              key: ValueKey(item.id),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  if (await showSimpleMessage(context, content: "确定删除此仓库吗?")) {
                    final res = await ref
                        .read(imageDbProvider.notifier)
                        .deleteRegistry(item.id);
                    await showSimpleMessage(context,
                        content: res, useSnackBar: true);
                    return true;
                  }
                } else {
                  await handleEdit(item);
                  return false;
                }
                return false;
              },
              secondaryBackground: bg1,
              background: bg2,
              child: ListTile(
                  title: Row(children: [
                    Container(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.2)),
                        child: Text(item.id.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 12, fontFamily: "Consolas"))),
                    Text(item.note,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold))
                  ]),
                  onTap: () => handleBatch(item),
                  trailing: IconButton(
                      onPressed: () => launchUrlString(item.manageUrl),
                      icon: const Icon(Icons.open_in_browser_sharp)),
                  dense: true,
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(item.user), Text(item.url)])));
        });
  }

  void handleBatch(Registry item) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => RepoBatchView(registry: item)));
  }

  Future<void> handleEdit(Registry item) async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => RepoAddEditView(registry: item)));
  }
}

class RepoBatchView extends ConsumerStatefulWidget {
  final Registry registry;
  const RepoBatchView({super.key, required this.registry});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RepoBatchViewState();
}

class _RepoBatchViewState extends ConsumerState<RepoBatchView> {
  late final registry = widget.registry;
  final input = TextEditingController();
  final input2 = TextEditingController();
  final prefix = TextEditingController();
  bool showOriginal = true;

  @override
  void dispose() {
    input.dispose();
    input2.dispose();
    prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: DefaultTextStyle(
              style: const TextStyle(fontSize: 13, color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(registry.id.toUpperCase()),
                  Text(registry.note)
                ],
              ),
            ),
            actions: [
              IconButton(
                  onPressed: () =>
                      {showOriginal = !showOriginal, setState(() {})},
                  icon: Icon(showOriginal ? Icons.raw_on : Icons.raw_off)),
              const SizedBox(width: 3)
            ]),
        body: Column(children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
                  child: TextField(
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(
                              left: 8, right: 8, top: 8, bottom: 8),
                          border: OutlineInputBorder(),
                          hintText: "输入多个仓库名称, 回车区分"),
                      controller: showOriginal ? input : input2,
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 12),
                      autocorrect: true))),
          Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: prefix,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(labelText: "前缀")))
              ])),
          const SizedBox(height: 10),
          Wrap(children: [
            TextButton(
                onPressed: () {
                  final cmd =
                      "docker login --username ${registry.user} ${registry.url}";
                  setState(() {
                    input2.text = cmd;
                    showOriginal = false;
                  });
                  Clipboard.setData(ClipboardData(text: cmd));
                  showSimpleMessage(context,
                      content: "已复制到剪贴板", useSnackBar: true, duration: 1000);
                },
                child: const Text("登录")),
            TextButton(
                onPressed: () {
                  if (input.text.isEmpty) {
                    showSimpleMessage(context,
                        content: "请输入仓库名称, 回车区分",
                        useSnackBar: true,
                        duration: 5000);
                    return;
                  }
                  final cmd = input.text
                      .split("\n")
                      .map((line) {
                        if (line.isEmpty) return "";
                        return "docker pull ${repoUrl2Normal(line)}";
                      })
                      .where((e) => e.isNotEmpty)
                      .join("\n");
                  setState(() {
                    showOriginal = false;
                    input2.text = cmd;
                  });
                  Clipboard.setData(ClipboardData(text: cmd));
                  showSimpleMessage(context,
                      content: "已复制到剪贴板", useSnackBar: true, duration: 1000);
                },
                child: const Text("拉取")),
            TextButton(
                onPressed: () {
                  if (input.text.isEmpty) {
                    showSimpleMessage(context,
                        content: "请输入仓库名称, 回车区分",
                        useSnackBar: true,
                        duration: 5000);
                    return;
                  }
                  final cmd = input.text
                      .split("\n")
                      .map((line) {
                        if (line.isEmpty) return "";
                        var origin = repoUrl2Normal(line);
                        final repline = origin.split("/").skip(1).join("/");
                        return "docker tag $origin ${registry.url}/${prefix.text.isEmpty ? "" : prefix.text + "/"}$repline";
                      })
                      .where((e) => e.isNotEmpty)
                      .join("\n");
                  setState(() {
                    input2.text = cmd;
                    showOriginal = false;
                  });
                  Clipboard.setData(ClipboardData(text: cmd));
                  showSimpleMessage(context,
                      content: "已复制到剪贴板", useSnackBar: true, duration: 1000);
                },
                child: const Text("打标签")),
            TextButton(
                onPressed: () {
                  if (input.text.isEmpty) {
                    showSimpleMessage(context,
                        content: "请输入仓库名称, 回车区分",
                        useSnackBar: true,
                        duration: 5000);
                    return;
                  }
                  final cmd = input.text
                      .split("\n")
                      .map((line) {
                        if (line.isEmpty) return "";
                        var origin = repoUrl2Normal(line);
                        final repline = origin.split("/").skip(1).join("/");
                        return "docker push ${registry.url}/${prefix.text.isEmpty ? "" : prefix.text + "/"}$repline";
                      })
                      .where((e) => e.isNotEmpty)
                      .join("\n");
                  setState(() {
                    input2.text = cmd;
                    showOriginal = false;
                  });
                  Clipboard.setData(ClipboardData(text: cmd));
                  showSimpleMessage(context,
                      content: "已复制到剪贴板", useSnackBar: true, duration: 1000);
                },
                child: const Text("推送")),
            TextButton(
                onPressed: () {
                  if (input.text.isEmpty) {
                    showSimpleMessage(context,
                        content: "请输入仓库名称, 回车区分",
                        useSnackBar: true,
                        duration: 5000);
                    return;
                  }
                  showSimpleMessage(context,
                      content: "已创建记录", useSnackBar: true, duration: 1000);
                },
                child: const Text("记录"))
          ]),
          const SizedBox(height: 60)
        ]));
  }

  String repoUrl2Normal(String url) {
    if (!url.contains(":")) url = url + ":latest";
    final sp = url.split("/");
    if (sp.length > 2) return url;
    if (sp.length > 1) return "docker.io/$url";
    return "docker.io/library/$url";
  }
}

class RepoAddEditView extends ConsumerStatefulWidget {
  final Registry registry;
  const RepoAddEditView({super.key, required this.registry});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RepoAddEditViewState();
}

class _RepoAddEditViewState extends ConsumerState<RepoAddEditView> {
  late Registry registry = widget.registry;
  late bool isAdd = widget.registry.id.isEmpty;
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(isAdd ? "添加仓库" : "编辑仓库")),
        body: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Column(children: [
                  TextFormField(
                      decoration: const InputDecoration(labelText: "标记"),
                      initialValue: registry.id,
                      readOnly: !isAdd,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(id: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: const InputDecoration(labelText: "优先级"),
                      initialValue: registry.priority.toString(),
                      validator: (v) =>
                          int.tryParse(v ?? "") == null ? "不能为空" : null,
                      onSaved: (e) => registry =
                          registry.copyWith(priority: int.parse(e!))),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: const InputDecoration(labelText: "名称"),
                      initialValue: registry.note,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(note: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: const InputDecoration(labelText: "用户名"),
                      initialValue: registry.user,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(user: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: InputDecoration(
                          labelText: "地址",
                          suffix: InkWell(
                              onTap: () {
                                if (registry.url.isNotEmpty) {
                                  launchUrlString("https://" + registry.url);
                                }
                              },
                              child:
                                  const Icon(Icons.open_in_browser, size: 18))),
                      initialValue: registry.url,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(url: e ?? "")),
                  const SizedBox(height: 3),
                  TextFormField(
                      decoration: InputDecoration(
                          labelText: "管理地址",
                          suffix: InkWell(
                              onTap: () {
                                if (registry.manageUrl.startsWith("http")) {
                                  launchUrlString(registry.manageUrl);
                                }
                              },
                              child:
                                  const Icon(Icons.open_in_browser, size: 18))),
                      initialValue: registry.manageUrl,
                      validator: (v) => v?.isNotEmpty == true ? null : "不能为空",
                      onSaved: (e) =>
                          registry = registry.copyWith(manageUrl: e ?? "")),
                  const SizedBox(height: 3),
                  TextButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          formKey.currentState?.save();
                          await ref
                              .read(imageDbProvider.notifier)
                              .editOrAddRegistry(registry);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("确定"))
                ]))));
  }
}
