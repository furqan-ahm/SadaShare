import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sada_share/utils/client.dart';

class Host extends StatefulWidget {
  const Host({ Key? key }) : super(key: key);

  @override
  _HostState createState() => _HostState();
}

class _HostState extends State<Host> {
  
  SignalingClient? client;
  RTCVideoRenderer localRenderer=RTCVideoRenderer();
  

  @override
  void initState() {
    client = SignalingClient('127.0.0.1', true, localRenderer);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        child: Icon(Icons.screen_share),
      ),
    );
  }
}