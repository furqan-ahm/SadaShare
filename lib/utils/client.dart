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
    socket = io('http://$serverAddress:3200', 
    OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Dart VM
      .disableAutoConnect() 
      .build()
    );
  }


  Future initialize() async{
    print('connecting to somewhere idk');
    socket.onConnect((data){

      //candidate handling
      socket.on('candidate-recieved',(data)async{
        connections[data['from']]!.addCandidate(
            RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ),
          );
        print('recieved candidate');
      });

      if(isHost){
        print('HOST HAS JOINED');
        socket.on('student-join',(data)async{  
          final i = data;

          print('oooh its $i');

          connections[i]=await createPeerConnection(configuration);
          registerPeerConnectionListener(connections[i], i);

          localStream?.getTracks().forEach((track) {
            connections[i]!.addTrack(track, localStream!);
            print('have tracks');
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
          await connections[i]!.setLocalDescription(offer);
          socket.emit('send-offer',{
            'from':0,
            'to':i,
            'offer':offer.toMap()
            });        
          }
        );
      }

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

        registerPeerConnectionListener(connections[data['from']], data['from']);

        localStream?.getTracks().forEach((track) {
          connections[data['from']]!.addTrack(track, localStream!);
          print('have tracks');
        });

        connections[data['from']]!.onIceCandidate = (RTCIceCandidate? candidate) {
          if (candidate == null) {
            print('onIceCandidate: complete!');
            return;
          }
          socket.emit('add-candidate',{'to':data['from'],'from':index,'candidate':candidate.toMap()});    
        };


        var offer = RTCSessionDescription(
          data['offer']['sdp'],
          data['offer']['type'],
        );

        await connections[data['from']]!.setRemoteDescription(offer);

        var answer = await connections[data['from']]!.createAnswer();
        
        await connections[data['from']]!.setLocalDescription(answer);


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
              connections[i]!.addTrack(track, localStream!);
              print('have tracks');
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
            await connections[i]!.setLocalDescription(offer);
            socket.emit('send-offer',{
              'from':index,
              'to':i,
              'offer':offer.toMap()
            });
          }
        }
      });
      ///
    });
    if(!isHost){
      //await openUserMedia(localRenderer);
    }
    socket.connect();
    initialized=true;
  }


  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
  ) async {
    var stream;
    try{
      stream = await navigator.mediaDevices
        .getUserMedia({'video': false, 'audio': true,});
    }
    catch(e){
      print(e);
    }
    localVideo.srcObject = stream;
    localVideo.srcObject!.getAudioTracks()[0].enabled=false;
    //remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  late Socket socket;


  Map<int, RTCPeerConnection> connections={};
  Map<int, MediaStream> remoteStreams={}; 

  MediaStream? get localStream=>localRenderer.srcObject;
  String? roomId;
  List clientCandidates=[];
  List hostCandidates=[];
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;


  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();

    localRenderer.srcObject!.getVideoTracks().forEach((element) {
      print('stopping this shit');
      element.stop();
    });

    localStream?.getTracks().forEach((element) {element.stop();});
    tracks.forEach((track) {
      track.stop();
    });

    
    remoteStreams.forEach((key, value) {value.getTracks().forEach((track) => track.stop());});
      
    connections.forEach((key, value) {value.close();});

    socket.emit('hangup');
    socket.disconnect();

    localStream!.dispose();
    remoteStreams.forEach((key, value) {value.dispose();});
    
  }



  void registerPeerConnectionListener(RTCPeerConnection? peerConnection, int index){
    print('registered peerconnection with $index');
    peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection.onSignalingState = (RTCSignalingState state) {
      print('SignalingClient state change: $state');
    };

    peerConnection.onTrack = (RTCTrackEvent event) {
      print('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        print('Add a track to the remoteStream $track');
        remoteStreams[index]?.addTrack(track);
      });
    };

    peerConnection.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStreams[index] = stream;
    };
  }

}