import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:socket_io_client/socket_io_client.dart';

typedef void StreamStateCallback(MediaStream stream);

class SignalingClient {
  Map<String, dynamic> configuration = {
  };

  bool isHost;
  int index=-1;
  bool initialized=false;
  RTCVideoRenderer localRenderer;

  SignalingClient(String serverAddress, this.isHost, this.localRenderer){
    socket = io('http://127.0.0.1:3200', 
    OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Dart VM
      .disableAutoConnect() 
      .build()
    );
  }


  Future initialize() async{
    socket.onConnect((data){

      //candidate handling
      socket.on('candidate-recieved',(data)async{
        connections[data['from']]?.addCandidate(
            RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ),
          );
        print('recieved candidate');
      });
      ///
      ///answer handling
      socket.on('answer-recieved', (data) async{
        
        print('answer recieved from ${data['from']}');

        var answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );

        print("setting answer from ${data['from']}");
        await connections[data['from']]!.setRemoteDescription(answer);
      });
      ///
      
      
      ///offer handling
      socket.on('offer-recieved',(data)async{
        connections[data['from']]=await createPeerConnection(configuration);

        print('offer recieved from ${data['from']}');

        registerPeerConnectionListener(connections[data['from']], data['from']);

        localStream?.getTracks().forEach((track) {
          connections[data['from']]?.addTrack(track, localStream!);
        });

        connections[data['from']]!.onIceCandidate = (RTCIceCandidate? candidate) {
          if (candidate == null) {
            print('onIceCandidate: complete!');
            return;
          }
          socket.emit('add-candidate',{'to':data['from'],'from':index,'candidate':candidate.toMap()});    
        };

        connections[data['from']]?.onTrack = (RTCTrackEvent event) {
          print('Got remote track: ${event.streams[0]}');
          event.streams[0].getTracks().forEach((track) {
            print('Add a track to the remoteStream: $track');
            remoteStreams[data['from']]?.addTrack(track);
          });
        };

        var offer = RTCSessionDescription(
          data['offer']['sdp'],
          data['offer']['type'],
        );
        await connections[data['from']]?.setRemoteDescription(offer);

        var answer = await connections[data['from']]!.createAnswer();
        
        await connections[data['from']]?.setLocalDescription(answer);


        socket.emit('send-answer',{'to':data['from'],'from':index,'answer':answer.toMap()});
      });
      ///
      ///initializing connections
      socket.on('index', (data)async{
        index=data;
        print('connected at index: $index');
        if(index!=0){
          for(int i=0;i<index;i++){

            connections[i]=await createPeerConnection(configuration);
            registerPeerConnectionListener(connections[i], i);

            localStream?.getTracks().forEach((track) {
              connections[i]?.addTrack(track, localStream!);
            });
            connections[i]!.onIceCandidate = (RTCIceCandidate? candidate) {
              if (candidate == null) {
                print('onIceCandidate: complete!');
                return;
              }
              print('executes');
              socket.emit('add-candidate',{'to':i,'from':index,'candidate':candidate.toMap()});    
            };

            var offer=await connections[i]!.createOffer();
            await connections[i]?.setLocalDescription(offer);
            socket.emit('send-offer',{
              'from':index,
              'to':i,
              'offer':offer.toMap()
            });

            peerConnection?.onTrack = (RTCTrackEvent event) {
              print('Got remote track: ${event.streams[0]}');

              event.streams[0].getTracks().forEach((track) {
                print('Add a track to the remoteStream $track');
                remoteStreams[i]?.addTrack(track);
              });
            };

          }
        }
      });
      ///
    });
    socket.connect();
    initialized=true;
  }

  late Socket socket;

  RTCPeerConnection? peerConnection;

  Map<int, RTCPeerConnection> connections={};
  Map<int, MediaStream> remoteStreams={}; 

  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  List clientCandidates=[];
  List hostCandidates=[];
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;


  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    remoteStreams.forEach((key, value) {value.getTracks().forEach((track) => track.stop());});
      
    if (peerConnection != null) peerConnection!.close();

    socket.emit('hangup');
    socket.disconnect();

    localStream!.dispose();
    remoteStreams.forEach((key, value) {value.dispose();});
    
  }



  void registerPeerConnectionListener(RTCPeerConnection? peerConnection, int index){
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('SignalingClient state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStreams[index] = stream;
    };
  }

}