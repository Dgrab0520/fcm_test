import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> backgroundHandler(RemoteMessage message) async {
  print(message.data.toString());
  print(message.notification!.title);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Firestore users fields
  final String fName = "name";
  String fToken = "token";
  final String fCreateTime = "createTime";
  final String fPlatform = "platform";
  TextEditingController _titleController = new TextEditingController();
  TextEditingController _bodyController = new TextEditingController();
  final sToken =
      "eyNMDj2ATkSq3hiKFSIEpA:APA91bFI1YrC5ZmhVMkz9uXbqTjPySuYbhodP45Mv1d8kksPbU6o6m2lpTlo1IgaW6uiE4qzHePjrQlzSxfBqGd3S1sexm2E6SxebNh1k66hkGSZIkkO-_pt2BIfOFINrjquWRj9ex24";

  final TextStyle tsTitle = TextStyle(color: Colors.grey, fontSize: 13);
  final TextStyle tsContent = TextStyle(color: Colors.blueGrey, fontSize: 15);

  List<dynamic> idList = [];
  List<dynamic> tokenList = [];
  List<Widget> tokenRadio = [];

  // Cloud Functions

  HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendFCM',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 5)));

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getInitialMessage();

    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        print(message.notification!.body);
        print(message.notification!.title);
        String? title = message.notification!.title;
        String? body = message.notification!.body;
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  content: ListTile(
                    title: Text(title!),
                    subtitle: Text(body!),
                  ),
                ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("OPEN!!!!!");
      print(message);
    });
    FirebaseMessaging.onBackgroundMessage(backgroundHandler);

    FirebaseMessaging.instance.getToken().then((value) => setToken(value!));
  }

  List<bool> c = [];

  @override
  Widget build(BuildContext context) {
    tokenRadio = [];
    for (int i = 0; i < idList.length; i++) {
      c.add(false);
      tokenRadio.add(Container(
        height: 100,
        width: 100,
        child: CheckboxListTile(
          title: Text(idList[i]),
          value: c[i],
          onChanged: (value) {
            setState(() {
              c[i] = value!;
            });
          },
        ),
      ));
    }

    return Scaffold(
      body: Center(
        child: Container(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: tokenRadio,
              ),
              const Text(
                'You have pushed the button this many times:',
              ),
              TextField(
                controller: _titleController,
              ),
              TextField(
                controller: _bodyController,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          sendSampleFCM(_titleController.text, _bodyController.text);
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void sendSampleFCM(String title, String body) async {
    List<String> tList = [];
    for (int i = 0; i < idList.length; i++) {
      if (c[i]) {
        tList.add(tokenList[i]);
      }
    }
    if (tList.length == 0) return;

    final HttpsCallableResult result = await callable.call(
      <String, dynamic>{fToken: tList, "title": title, "body": body},
    );
  }

  setToken(String token) async {
    var url = Uri.parse('http://flunyt.com/test_token.php');
    var result = await http.post(url, body: {
      "token": token,
    });

    getToken();
  }

  getToken() async {
    var url = Uri.parse('http://flunyt.com/test_token_init.php');
    var result = await http.post(url, body: {});
    Map<String, dynamic> body = json.decode(result.body);

    idList = body['id'];
    tokenList = body['token'];

    print("idList : $idList");
    print("tokenList : $tokenList");
    setState(() {});
  }
}
