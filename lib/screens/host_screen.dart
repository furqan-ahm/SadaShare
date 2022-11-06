import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:sada_share/utils/client.dart';
import 'package:sada_share/utils/server.dart';
import 'package:sada_share/widgets/screen_select_dialog.dart';
import 'package:sada_share/widgets/windows_title_bar.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({Key? key}) : super(key: key);

  @override
  _HostState createState() => _HostState();
}

class _HostState extends State<HostScreen> {
  SignalingClient? client;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  DesktopCapturerSource? source;

  NetworkInfo info = NetworkInfo();

  bool started = false;

  String ipAddress = '';

  bool sourceSelected = false;

  @override
  void initState() {
    appWindow.size = const Size(1024, 720);
    localRenderer.initialize();
    super.initState();
  }

  getDesktopSource() async {
    
    source = await showDialog(context: context, builder: (context)=>ScreenSelectDialog());

    if(source!= null){
      try {
        var stream =
            await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
          'video': source == null
              ? true
              : {
                  'deviceId': {'exact': source!.id},
                  'mandatory': {'frameRate': 60.0}
                }
        });
        stream.getVideoTracks()[0].onEnded = () {
          print(
              'By adding a listener on onEnded you can: 1) catch stop video sharing on Web');
        };

        localRenderer.srcObject = stream;
        setState(() {
          sourceSelected=true;
        });
      } catch (e) {
        print(e.toString());
      }
    }
  }

  startStream() async {
    client = SignalingClient('localhost', true, localRenderer);
    client?.initialize();
    setState(() {
      started = true;
    });

    ipAddress = (await info.getWifiIP()) ?? 'Error';
    setState(() {});

    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Join Using Below IP'),
                  Text(
                    ipAddress,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  FloatingActionButton.extended(
                      backgroundColor: Colors.white,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      label: Row(
                        children: const [
                          Icon(Icons.check),
                          Text('OK'),
                        ],
                      ))
                ],
              ),
            ),
          );
        });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const WindowsTitleBar(
            showMaximize: true,
          ),
          Expanded(
            child: Center(
              child: source!=null?RTCVideoView(localRenderer):Text(':( Nothing to Share', style: TextStyle(fontSize: 20),),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Text('IP: $ipAddress'),
              ],
            ),
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: started
          ? FloatingActionButton.extended(
              backgroundColor: Colors.redAccent,
              heroTag: 'rip me',
              onPressed: () {
                Navigator.pop(context);
              },
              label: const Text('Stop Hosting'),
            )
          : source != null
              ? FloatingActionButton.extended(
                  backgroundColor: Colors.white,
                  heroTag: 'totally not depressed',
                  onPressed: () {
                    startStream();
                  },
                  label: const Text('Start Hosting'),
                )
              : FloatingActionButton.extended(
                  backgroundColor: Colors.white,
                  heroTag: 'ahahaha',
                  onPressed: () {
                    getDesktopSource();
                  },
                  label: const Text('Share Something'),
                ),
    );
  }

  @override
  void dispose() {
    client!.hangUp(localRenderer);
    MyServer.getInstance().stop();
    super.dispose();
  }
}
