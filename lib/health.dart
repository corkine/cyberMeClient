import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintf/sprintf.dart';

import 'package:flutter/material.dart';

class Info {
  String name;
  String id;
  String lastTestTime;
  String testInfo;
  String lastVaccineDate;
  int vaccineTimes;

  Info(
      {required this.name,
      required this.id,
      required this.lastTestTime,
      required this.testInfo,
      required this.lastVaccineDate,
      required this.vaccineTimes});

  @override
  String toString() {
    return 'Info{name: $name, id: $id, lastTestTime: $lastTestTime, testInfo: $testInfo, lastVaccineDate: $lastVaccineDate, vaccineTimes: $vaccineTimes}';
  }

  static savingData(Info info) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("name", info.name);
    prefs.setString("id", info.id);
    prefs.setString("lastTestTime", info.lastTestTime);
    prefs.setString("testInfo", info.testInfo);
    prefs.setString("lastVaccineDate", info.lastVaccineDate);
    prefs.setInt("vaccineTimes", info.vaccineTimes);
  }

  static Future<Info> readData() {
    var f = SharedPreferences.getInstance().then((prefs) => Info(
        name: prefs.getString("name") ?? "张三",
        id: prefs.getString("id") ?? "122333444555553321",
        lastTestTime: prefs.getString("lastTestTime") ?? "2022-04-23 00:39",
        testInfo: prefs.getString("testInfo") ?? "48小时阴性",
        lastVaccineDate: prefs.getString("lastVaccineDate") ?? "2022-04-01",
        vaccineTimes: prefs.getInt("vaccineTimes") ?? 3));
    return f;
  }
}

class HealthCard extends StatefulWidget {
  final Info info;

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

  const HealthCard({Key? key, required this.info}) : super(key: key);

  @override
  State<HealthCard> createState() => _HealthCardState();
}

class _HealthCardState extends State<HealthCard> {
  Color blue = const Color.fromRGBO(88, 145, 235, 1);

  TextStyle normalStyle = const TextStyle(
      fontSize: 17,
      color: Colors.white,
      fontWeight: FontWeight.w400,
      fontFamily: ".SF UI Text");
  TextStyle titleStyle = const TextStyle(
      fontSize: 17,
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontFamily: ".SF UI Text");
  TextStyle nameStyle = const TextStyle(
      fontSize: 19,
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontFamily: ".SF UI Text");

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildTitleBar(titleStyle),
        elevation: 0,
        backgroundColor: blue,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Stack(
          fit: StackFit.loose,
          alignment: Alignment.topCenter,
          children: [
            buildBlue(),
            buildUserInfo(),
            HealthInfo(info: widget.info),
          ],
        ),
      ),
    );
  }

  Positioned buildBlue() {
    return Positioned(
        //蓝色背景
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 180,
          color: blue,
        ));
  }

  Widget buildUserInfo() {
    return Container(
      padding: const EdgeInsets.only(top: 25),
      height: 100,
      child: Row(
        children: [
          const SizedBox(
            width: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "姓名",
                style: normalStyle,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                List.generate(widget.info.name.length - 1, (index) => "*")
                        .reduce((value, element) => value + element) +
                    widget.info.name[widget.info.name.length - 1],
                style: nameStyle,
              ),
            ],
          ),
          const SizedBox(
            width: 50,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  "身份证号",
                  style: normalStyle,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                List.generate(widget.info.id.length - 4, (index) => "*")
                        .reduce((value, element) => value + element) +
                    widget.info.id.substring(widget.info.id.length - 4),
                style: nameStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  final formKey = GlobalKey<FormState>();

  handleSetData() {
    return showDialog<Info>(
        context: context,
        builder: (BuildContext c) {
          return SimpleDialog(
            title: const Text('自定义看板'),
            contentPadding: const EdgeInsets.all(10),
            children: [
              Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: "姓名",
                            hintText: "张三",
                            hintStyle: TextStyle(color: Colors.grey)),
                        initialValue: widget.info.name,
                        validator: (v) =>
                            (v != null && v.isNotEmpty && v.length >= 2)
                                ? null
                                : "需要输入名字",
                        onSaved: (e) => widget.info.name = e!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: "身份证号",
                            hintText: "必须输入合法长度的身份证号",
                            hintStyle: TextStyle(color: Colors.grey)),
                        initialValue: widget.info.id,
                        validator: (v) =>
                            (v != null && v.isNotEmpty && v.length == 18)
                                ? null
                                : "需要输入完整身份证号",
                        onSaved: (e) => widget.info.id = e!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "最后检测时间 ",
                          hintText: "YYYY-MM-DD HH:mm",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        initialValue: widget.info.lastTestTime,
                        validator: (v) =>
                            (v != null && v.isNotEmpty && v.length >= 10)
                                ? null
                                : "输入非法",
                        onSaved: (e) => widget.info.lastTestTime = e!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "最后测试结果",
                          hintText: "48小时阴性",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        initialValue: widget.info.testInfo,
                        validator: (v) =>
                            (v != null && v.isNotEmpty && v.length >= 2)
                                ? null
                                : "输入非法",
                        onSaved: (e) => widget.info.testInfo = e!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "最后疫苗日期",
                          hintText: "2022-03-01",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        initialValue: widget.info.lastVaccineDate,
                        validator: (v) =>
                            (v != null && v.isNotEmpty && v.length >= 2)
                                ? null
                                : "输入非法",
                        onSaved: (e) => widget.info.lastVaccineDate = e!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "疫苗次数",
                          hintText: "3",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        initialValue: widget.info.vaccineTimes.toString(),
                        validator: (v) => (v != null &&
                                v.isNotEmpty &&
                                int.tryParse(v) != null)
                            ? null
                            : "输入一个整数",
                        onSaved: (e) =>
                            widget.info.vaccineTimes = int.parse(e!),
                      )
                    ],
                  )),
              ButtonBar(
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(null);
                      },
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () {
                        if (formKey.currentState != null &&
                            formKey.currentState!.validate()) {
                          formKey.currentState?.save();
                          setState(() {
                            Info.savingData(widget.info);
                          });
                          print("info: ${widget.info}");
                          Navigator.of(context).pop(null);
                        }
                      },
                      child: const Text('确定')),
                ],
              )
            ],
          );
        });
  }

  Stack buildTitleBar(TextStyle titleStyle) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Text(
            "湖北健康码",
            style: titleStyle,
          ),
        ),
        const Positioned(
            left: 0,
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 19,
            )),
        Positioned(
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: const Color.fromRGBO(78, 118, 207, 1)),
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 8, right: 8, top: 3, bottom: 3),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        handleSetData();
                      },
                      child: Image.asset(
                        "images/more.png",
                        width: 23,
                        height: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6, right: 6),
                      child: Container(
                        width: 1,
                        height: 16,
                        color: const Color.fromRGBO(73, 113, 200, 1),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        exit(0);
                      },
                      child: const Icon(
                        Icons.adjust,
                        color: Colors.white,
                        size: 19,
                      ),
                    )
                  ],
                ),
              ),
            ))
      ],
    );
  }
}

class HealthInfo extends StatefulWidget {
  final Info info;

  const HealthInfo({Key? key, required this.info}) : super(key: key);

  @override
  State<HealthInfo> createState() => _HealthInfoState();
}

class _HealthInfoState extends State<HealthInfo> {
  final Color blue = const Color.fromRGBO(88, 145, 235, 1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 115),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(
                      color: Color.fromARGB(10, 20, 30, 40),
                      blurRadius: 10,
                      spreadRadius: 0.3)
                ]),
            child: Column(
              children: [
                buildMainInfo(),
                buildHealthButtonBar(),
                const Divider(
                  thickness: 0.5,
                ),
                buildTravelCardButton()
              ],
            ),
          ),
          buildVaccineCard(),
          buildTravelBar(),
          const SizedBox(
            height: 100,
          )
        ],
      ),
    );
  }

  Padding buildTravelBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                  color: Color.fromARGB(10, 20, 30, 40),
                  blurRadius: 10,
                  spreadRadius: 0.3)
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "通信行程卡",
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.only(left: 15, right: 15, top: 8, bottom: 8),
              decoration: BoxDecoration(
                  color: blue,
                  borderRadius: const BorderRadius.all(Radius.circular(7)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color.fromARGB(10, 20, 30, 40),
                        blurRadius: 10,
                        spreadRadius: 0.3)
                  ]),
              child: const Text(
                "点击核验",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Padding buildVaccineCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: widget.info.testInfo.contains("48")
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                              Color.fromRGBO(116, 186, 130, 1),
                              Color.fromRGBO(158, 224, 138, 0.95)
                            ])
                      : const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                              Color.fromRGBO(90, 136, 248, 1),
                              Color.fromRGBO(129, 178, 247, 0.95)
                            ]),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color.fromARGB(10, 20, 30, 40),
                        blurRadius: 10,
                        spreadRadius: 0.3)
                  ]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: widget.info.testInfo.contains("48") ?
                        Image.asset(
                          "images/refresh3.png",
                          width: 19,
                          height: 19,
                        ) :
                        Image.asset(
                          "images/refresh.png",
                          width: 19,
                          height: 19,
                        ),
                      ),
                      const Text(
                        "核酸检测",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      const RotatedBox(
                          quarterTurns: -2,
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 15,
                          ))
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(
                      widget.info.testInfo,
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    widget.info.lastTestTime,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w300),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                        color: Color.fromARGB(10, 20, 30, 40),
                        blurRadius: 10,
                        spreadRadius: 0.3)
                  ]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Image.asset(
                          "images/refresh2.png",
                          width: 19,
                          height: 19,
                        ),
                      ),
                      const Text(
                        "疫苗接种",
                        style: TextStyle(color: Colors.black87, fontSize: 15),
                      ),
                      const RotatedBox(
                          quarterTurns: -2,
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black87,
                            size: 15,
                          ))
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 7),
                    child: Text(
                      widget.info.vaccineTimes.toString() + "次",
                      style: TextStyle(
                          fontSize: 20,
                          color: blue,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    widget.info.lastVaccineDate,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w300),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Padding buildTravelCardButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 10, top: 3),
                child: Image.asset(
                  "images/card.png",
                  width: 23,
                  height: 23,
                ),
              ),
              const Text(
                "查询我的行程卡",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          const RotatedBox(
              quarterTurns: -2,
              child: Icon(
                Icons.arrow_back_ios_sharp,
                color: Color.fromRGBO(148, 148, 148, 1.0),
                size: 19,
              ))
        ],
      ),
    );
  }

  Padding buildHealthButtonBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, top: 30, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          simpleButton("images/report.png", "健康上报"),
          simpleButton("images/manage.png", "健康码管理"),
          simpleButton("images/help.png", "客服")
        ],
      ),
    );
  }

  Row simpleButton(String ico, String text) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Image.asset(
            ico,
            width: 20,
            height: 20,
          ),
        ),
        const SizedBox(
          width: 1,
        ),
        Text(
          text,
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: blue),
        )
      ],
    );
  }

  late Timer timer;

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  initState() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
    super.initState();
  }

  Stack buildMainInfo() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        //白色卡片
        Container(height: 310),
        Positioned(
            top: 17,
            child: RichText(
                text: TextSpan(
                    text: HealthCard.clock(justBeforeSeconds: true),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black),
                    children: [
                  TextSpan(
                      text: HealthCard.clock(justSeconds: true),
                      style: const TextStyle(fontSize: 27))
                ]))),
        Positioned(
            top: 54,
            child: Image.asset(
              "images/code.png",
              width: 220,
              height: 220,
            )),
        Positioned(
          top: 275,
          child: RichText(
              text: TextSpan(
                  text: "核酸 ",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Color.fromRGBO(28, 148, 77, 1)),
                  children: [
                const TextSpan(
                    text: "已采样",
                    style:
                        TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
                TextSpan(
                    text: " " + HealthCard.clock(justDate: true),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w400))
              ])),
        )
      ],
    );
  }
}
