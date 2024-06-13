import 'package:cyberme_flutter/api/backup.dart';
import 'package:cyberme_flutter/pocket/app/util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class BackupView extends ConsumerStatefulWidget {
  const BackupView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BackupViewState();
}

class _BackupViewState extends ConsumerState<BackupView> {
  late DateTime weekDayOne;
  late DateTime lastWeekDayOne;
  late DateTime today;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(backupsProvider).value ?? [];
    return Scaffold(
        appBar: AppBar(title: const Text("Backups"), actions: [
          IconButton(
              onPressed: () async =>
                  await ref.read(backupsProvider.notifier).append(),
              icon: const Icon(Icons.add))
        ]),
        body: ListView.builder(
            itemBuilder: (context, index) {
              final item = data[index];
              final start = DateTime.fromMillisecondsSinceEpoch(item.start);
              final cost = (item.cost / 60.0).toStringAsFixed(2);
              return Dismissible(
                  key: ValueKey(item.id),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      ref.read(backupsProvider.notifier).delete(item.id);
                      return true;
                    } else {
                      return false;
                    }
                  },
                  background: Container(color: Colors.amber),
                  secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white)),
                  child: ListTile(
                    dense: true,
                    title: Text(item.from),
                    onTap: () async {
                      await showSimpleMessage(context,
                          content:
                              "[Message]\n${item.message}\n\n[Log]\n${item.log}");
                    },
                    subtitle: Row(children: [
                      buildRichDate(start,
                          today: today,
                          weekDayOne: weekDayOne,
                          lastWeekDayOne: lastWeekDayOne),
                      const SizedBox(width: 4),
                      Text("耗时 $cost 分钟")
                    ]),
                    trailing: item.result == "success"
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.error, color: Colors.red),
                  ));
            },
            itemCount: data.length));
  }
}
