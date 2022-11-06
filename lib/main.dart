import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:sada_share/screens/host_screen.dart';
import 'package:sada_share/utils/server.dart';
import 'package:sada_share/widgets/windows_title_bar.dart';

import 'screens/join_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  if (Platform.isWindows) {
    doWhenWindowReady(() {
      const initialSize = Size(400, 600);
      appWindow.minSize = initialSize;
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = 'SadaShare';
      appWindow.show();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sada Share',
      theme: ThemeData.dark(),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MenuScreen> {
  final TextEditingController controller = TextEditingController();

  bool joinMode = Platform.isAndroid;

  host() async {
    await MyServer.getInstance().start();
    Navigator.push(
            context, MaterialPageRoute(builder: (context) => HostScreen()))
        .then((value) {
      if (Platform.isWindows) appWindow.size = const Size(400, 600);
    });
  }

  join() async {
    if (joinMode && controller.text.isNotEmpty) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JoinScreen(
              serverAddress: controller.text,
            ),
          )).then((value) {
        if (Platform.isWindows) appWindow.size = const Size(400, 600);
      });
    } else if (Platform.isWindows) {
      setState(() {
        joinMode = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          (Platform.isAndroid)
              ? const SizedBox.shrink()
              : const WindowsTitleBar(),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          'Sada',
                          style: TextStyle(
                              fontSize: 40,
                              color: Theme.of(context).backgroundColor),
                        ),
                      ),
                      Text(
                        'Share',
                        style: TextStyle(fontSize: 60),
                      ),
                    ],
                  ),
                  Spacer(),
                  const Text('What would you like to do?'),
                  const SizedBox(
                    height: 20,
                  ),
                  joinMode
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            (Platform.isWindows)?IconButton(
                                onPressed: () {
                                  setState(() {
                                    joinMode = false;
                                  });
                                },
                                icon: Icon(Icons.arrow_back)
                            ):const SizedBox.shrink(),
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                  labelText: 'Ip Address',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(10)),
                                  floatingLabelStyle:
                                      TextStyle(color: Colors.white),
                                  focusColor: Colors.white),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                child: InkWell(
                                    onTap: () {
                                      host();
                                    },
                                    child: Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        width: double.infinity,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Host',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              color: Theme.of(context)
                                                  .backgroundColor),
                                        )))),
                            const SizedBox(
                              height: 20,
                            ),
                            const Text('- or -'),
                          ],
                        ),
                  const SizedBox(
                    height: 20,
                  ),
                  Material(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side:
                              const BorderSide(color: Colors.white, width: 2)),
                      color: joinMode ? Colors.white : Colors.transparent,
                      child: InkWell(
                          onTap: () {
                            join();
                          },
                          child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: Text(
                                'Join',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: joinMode
                                        ? Theme.of(context).backgroundColor
                                        : Colors.white),
                              )))),
                  Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
