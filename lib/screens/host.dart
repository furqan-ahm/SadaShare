import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sada_share/utils/client.dart';
import 'package:sada_share/widgets/screen_select_dialog.dart';

class Host extends StatefulWidget {
  const Host({ Key? key }) : super(key: key);

  @override
  _HostState createState() => _HostState();
}

class _HostState extends State<Host> {
  
  SignalingClient? client;
  RTCVideoRenderer localRenderer=RTCVideoRenderer();
  DesktopCapturerSource? source;

  bool sourceSelected = false;

  @override
  void initState() {
    localRenderer.initialize();
    super.initState();
  }

  getDesktopSource() async{
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RTCVideoView(
          localRenderer
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: (){
              getDesktopSource();
            },
            child: const Icon(Icons.screen_share),
          ),
          FloatingActionButton(
            onPressed: (){
              getDesktopSource();
            },
            child: const Icon(Icons.screen_share),
          ),
        ],
      ),
    );
  }
}