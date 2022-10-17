import 'package:flutter/material.dart';
import 'package:sada_share/screens/host.dart';
import 'package:sada_share/utils/server.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController controller = TextEditingController();


  host()async{
    await MyServer.getInstance().start();
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Host()));
  }

  join()async{

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder:(context) => Host(),));
                print('eh');
              },
             child: Text('Host')
            ),
            const SizedBox(height: 50,),
            const Text('OR'),
            const SizedBox(height: 50,),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'IP Address'
              ),
            ),
            const SizedBox(height: 20,),
            ElevatedButton(onPressed: (){}, child: Text('Join')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}