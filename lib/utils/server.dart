import 'package:socket_io/socket_io.dart';


class MyServer{

    List clients=[];


  MyServer._(){
    _io = Server();
    
   _io!.on('connection', (client) {
      print('connected to $client');


      
      if(clients.length!=0){
        client.to(clients[0].id).emit('student-join', clients.length);
      }


      clients.add(client);
      client.join('dummy');
      
      client.on('disconnect',(_){
        clients.removeWhere((e)=>e.id==client.id);
      });

      client.on('send-offer',(data){

        data['from']=clients.indexOf(client);
        client.to(clients[data['to']].id).emit('offer-recieved',data);
      });

      client.on('send-answer',(data){

        data['from']=clients.indexOf(client);
        client.to(clients[data['to']].id).emit('answer-recieved',data);
      });

      client.on('add-candidate',(data){

        data['from']=clients.indexOf(client);
        client.to(clients[data['to']].id).emit('candidate-recieved',data);
      });

    });
  }
  
  Server? _io;

  static MyServer? _instance;

  static MyServer getInstance(){
    if(_instance!=null)return _instance!;

    _instance=MyServer._();
    
    return _instance!;
  }


  start()async{
    _io!.listen(3200);
  }

  stop(){
    _io!.close();
  }




}