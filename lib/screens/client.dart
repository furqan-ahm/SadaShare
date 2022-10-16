import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sada_share/utils/client.dart';

class Client extends StatefulWidget {
  const Client({ Key? key, required this.serverAddress }) : super(key: key);

  final String serverAddress;

  @override
  _ClientState createState() => _ClientState();
}

class _ClientState extends State<Client> {

  RTCVideoRenderer localRenderer=RTCVideoRenderer();
  bool ready=false;

  @override
  void initState() {
    super.initState();
  }


  initRenderer()async{
    await localRenderer.initialize();
    SignalingClient client=SignalingClient(widget.serverAddress, false, localRenderer);
    setState(() {
      ready=true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: Size.infinite.width,
        height: Size.infinite.height,
        child: ready?RTCVideoView(
          localRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain, 
        )
        :Container(),
      ),
    );
  }
}