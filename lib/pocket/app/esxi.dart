import 'dart:math';

import 'package:cyberme_flutter/api/esxi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StatusPainter extends CustomPainter {
  final double width;
  final double height;
  final Color color;

  StatusPainter(this.color, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(-1, 10 - height, width, height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class EsxiView extends ConsumerStatefulWidget {
  const EsxiView({super.key});

  @override
  ConsumerState<EsxiView> createState() => _EsxiViewState();
}

class _EsxiViewState extends ConsumerState<EsxiView> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(esxiInfosProvider).value;
    Widget content;
    if (data == null) {
      content = const Padding(
          padding: EdgeInsets.only(top: 50),
          child: CupertinoActivityIndicator());
    } else if (data.$2.isNotEmpty) {
      content = Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Center(child: Text(data.$2)));
    } else {
      final d = data.$1!;
      content = Padding(
          padding: const EdgeInsets.only(left: 0, right: 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
                padding: EdgeInsets.only(left: 15, top: 8, bottom: 0),
                child: Text("ADDRESS",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            ...d.ips.map((e) {
              return ListTile(
                  title: Text(e.ip_address),
                  subtitle:
                      Text(e.ip_family + " / " + e.type.replaceAll("__", ", ")),
                  trailing: Text(e.interface),
                  dense: true);
            }).toList(),
            const Padding(
                padding: EdgeInsets.only(left: 15, top: 8, bottom: 0),
                child:
                    Text("VMS", style: TextStyle(fontWeight: FontWeight.bold))),
            ...d.vms.indexed.map((e) {
              return ListTile(
                  onTap: () => popVmMenu(e.$2),
                  title: Row(children: [
                    status2Logo(e.$2, index: e.$1),
                    Text(e.$2.name)
                  ]),
                  subtitle: Text(vmOs(e.$2) + " / ${e.$2.version}"),
                  trailing: Container(
                      padding: const EdgeInsets.only(
                          left: 5, right: 5, bottom: 3, top: 1),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade200,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text("服务 ${e.$2.vmid}",
                          style: const TextStyle(color: Colors.white))),
                  dense: true);
            }).toList(),
            const SizedBox(height: 100),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(d.version,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 10))
            ]),
            const SizedBox(height: 10)
          ]));
    }
    return Scaffold(
        body: CustomScrollView(slivers: [
      SliverAppBar.large(
          title:
              const Text("Pocket ESXi", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showMaterialBanner(
                      MaterialBanner(
                          content: const Text("正在刷新数据，请稍后..."),
                          actions: [
                        TextButton(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .clearMaterialBanners(),
                            child: const Text("OK"))
                      ]));
                  ref.read(esxiInfosProvider.notifier).sync().then((value) =>
                      ScaffoldMessenger.of(context).clearMaterialBanners());
                },
                icon: const Icon(Icons.sync))
          ],
          expandedHeight: 220,
          pinned: true,
          stretch: true,
          flexibleSpace: Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("images/server.png"),
                      fit: BoxFit.cover)))),
      SliverToBoxAdapter(child: content)
    ]));
  }

  Widget status2Logo(EsxiVm e, {int index = 0}) {
    return TweenAnimationBuilder(
        key: ValueKey(e.power),
        //key: UniqueKey(),
        tween: IntTween(begin: max(30 - index * 30, 0), end: 100),
        curve: Curves.easeOutQuad,
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return CustomPaint(
              painter: StatusPainter(
                  e.powerEnum == VmPower.on
                      ? Colors.green
                      : e.powerEnum == VmPower.off
                          ? Colors.red
                          : e.powerEnum == VmPower.suspended
                              ? Colors.yellow
                              : Colors.grey,
                  30 * value * 0.01,
                  10 * value * 0.01));
        });
  }

  String vmOs(EsxiVm e) {
    final os = e.os.toLowerCase();
    if (os.contains("windows")) {
      return "Windows";
    } else if (os.contains("ubuntu")) {
      return "Ubuntu Linux";
    } else if (os.contains("cent")) {
      return "CentOS Linux";
    } else if (os.contains("mac") || os.contains("darwin")) {
      return "macOS";
    } else if (os.contains("linux")) {
      return "Linux";
    } else {
      return os;
    }
  }

  popVmMenu(EsxiVm vm) async {
    change(VmPower power) async {
      Navigator.of(context).pop();
      final res =
          await ref.read(esxiInfosProvider.notifier).changeState(vm, power);
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text("结果"),
                  content: Text(res),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("确定"))
                  ]));
    }

    await showDialog(
        context: context,
        builder: (context) => SimpleDialog(
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(vm.name.toUpperCase()),
                        const Spacer(),
                        status2Logo(vm),
                        Text("may ${vm.power}",
                            style: const TextStyle(fontSize: 12))
                      ]),
                      Text(
                          "id: ${vm.vmid}\nfile: ${vm.guest}\nos: ${vm.os}\nversion: ${vm.version}",
                          style: const TextStyle(fontSize: 12))
                    ]),
                children: [
                  SimpleDialogOption(
                      onPressed: () => change(VmPower.on),
                      child: const Text("启动此虚拟机")),
                  SimpleDialogOption(
                      onPressed: () => change(VmPower.suspended),
                      child: const Text("暂停此虚拟机")),
                  SimpleDialogOption(
                      onPressed: () => change(VmPower.off),
                      child: Text("关闭此虚拟机",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)))
                ]));
  }
}
