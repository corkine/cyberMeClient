import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Flutter Apps"),
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        child: Column(
                            children: R.toMenu.entries
                                .map((e) => Card(
                                    child: ListTile(
                                        onTap: () {
                                          if ((e.value["replace"] as bool?) ??
                                              false) {
                                            Navigator.of(context)
                                                .pushReplacementNamed(
                                                    e.key.route);
                                          } else {
                                            Navigator.of(context)
                                                .pushNamed(e.key.route);
                                          }
                                        },
                                        title: Text(e.value["name"]),
                                        subtitle: Text(e.key.name))))
                                .toList(growable: false)),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: () =>
                                  SystemNavigator.pop(animated: true),
                              child: const Text("退出 Flutter")),
                          TextButton(
                              onPressed: () => exit(0),
                              child: const Text("退出 App"))
                        ],
                      )
                    ]))));
  }
}
