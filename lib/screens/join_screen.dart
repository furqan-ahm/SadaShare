import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sada_share/utils/client.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({ Key? key, required this.serverAddress }) : super(key: key);

  final String serverAddress;

  @override
  _ClientState createState() => _ClientState();
}

class _ClientState extends State<JoinScreen> {

  late SignalingClient client;
  RTCVideoRenderer remoteRenderer=RTCVideoRenderer();
  RTCVideoRenderer localRenderer=RTCVideoRenderer();
  bool ready=false;

  @override
  void initState() {
    super.initState();
    initRenderer();
  }


  initRenderer()async{
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    client=SignalingClient(widget.serverAddress, false, localRenderer);
    client.onAddRemoteStream=(stream) {
      print('got stream');
      remoteRenderer.srcObject=stream;
      setState(() {
        
      });
    };
    client.initialize();
    setState(() {
      ready=true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Joined'),
      ),
      body: Center(
        child: ready?RTCVideoView(
          remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain, 
        )
        :Container(),
      ),
    );
  }
}