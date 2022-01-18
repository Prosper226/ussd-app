import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ussd_advanced/ussd_advanced.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ussd_service/ussd_service.dart';
import 'package:device_info/device_info.dart';

import 'package:ussd_ws_ex/crypted.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late TextEditingController _controller;
  String? _response;
  var ussdMsg = "";
  var ussdCode = "";
  var phone = "";
  var amount = 0;
  var transaction = "";
  var request = "";
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  IO.Socket socket = IO.io("http://192.168.1.106:5556", <String, dynamic>{
    "transports": ["websocket"],
    "autoConnect" : false,
  });


  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _response = 'System not connected';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  void connect(){

    socket.connect();
    socket.onConnect((_) => print("Connected"));
    socket.emit("/test", "Device __START__ APP {button has click}");

    if(! socket.connected){
      setState(() {
        _response = 'Connected';
        // 'socket listening: #${socket.connected}';
      });
    }else{
      setState(() {
        _response = 'System is already connected';
        // 'socket listening: #${socket.connected}';
      });
    }

    socket.on("ussd", (data) async {

      assert(data != null);
      print(data);
      var decryptData = decryptMyData(data);
      Map<String, dynamic> map = json.decode(decryptData);
      phone = map["phone"];
      amount = map["amount"];
      transaction = map["transaction"];
      request = map["request"];
      const secret = "0000"; // account secret code
      setState(() {
        _response = 'Sending ${amount} FCFA to the phone number ${phone}, for the transaction ${transaction}, and related to the query ${request}';
        print(_response);
      });

      ussdCode = "*555*2*1*${phone}*${amount}*${secret}#";
      // ussdCode = "*555*8*1*${secret}#"; // "*144*9*1*secret#"; // "*144*2*1*57914041*50*secret#"; // "*160#";
      // ussdCode = "*101#";
      String? _res = await UssdAdvanced.sendAdvancedUssd(code: ussdCode, subscriptionId: 1);
      setState(() {
        _response = _res;
      });
      socket.emit("/ussdResponse", "USSDExecute: ${_response}");

      // await UssdAdvanced.sendAdvancedUssd(code: ussdCode, subscriptionId: 1)
      //     .then((value) => [
      //         setState(() {
      //           _response = value;
      //           print(value);
      //         }),
      //         socket.emit("/ussdResponse", "USSDExecute: ${_response}"),
      //       ]
      //     );
      //     // .catchError((onError) => [
      //     //     setState(() {
      //     //       _response = "${onError}"; //'OnError exception throw';
      //     //       print(onError);
      //     //     }),
      //     //     socket.emit("/ussdResponse", "USSDExecute: ${_response}"),
      //     //   ]
      //     // );
      //
    });

    print(socket.connected);

  }

  Future<void> pingServer() async{
    try {
      var deviceData = await deviceInfoPlugin.androidInfo;
      print('Ping from ${deviceData.model}');

      if ( socket.connected) {
        print('${deviceData.model}: ping server');
        socket.emit("/ping", "${deviceData.model} ping server");
        socket.on("pingResponse", (msg){
          setState(() {
            _response =
            '${deviceData.model} : Ping xvision server has been successfully';
          });
        });
      } else {
        print('${deviceData.model}: Cannot ping server');
        setState(() {
          _response = '${deviceData.model}: Cannot ping server (socket listening: #${socket.connected})';
        });
      }
    }catch(e){
      setState(() {
        _response =
        'Cannot get device information';
      });
    }
  }

  void makeMyRequest() async {
    int subscriptionId = 1; // sim card subscription ID
    String code = "*160#"; // ussd code payload
    try {
      String ussdResponseMessage = await UssdService.makeRequest(
        subscriptionId,
        code,
        const Duration(seconds: 10), // timeout (optional) - default is 10 seconds
      );
      print("succes! message: $ussdResponseMessage");
    } catch(e) {
      debugPrint("error! code: $e");
    }
  }

  Future<String> ussdExecute() async{

      String? _res = await UssdAdvanced.sendAdvancedUssd(code: "*160#", subscriptionId: 1);

      setState(() {
        _response = _res;
      });

      // return '${amount} XOF has been succesful transfered to ${phone}';
    return "try to execute ussd code";

  }

  @override
  Widget build(BuildContext context) {
    const title = "Xvision USSD APP";
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [


            // text input
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Ussd code to execute'),
            ),

            // dispaly responce if any
            if (_response != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_response!),
              ),

            // buttons
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    connect();
                  },
                  child: const Text('__START__'),
                ),
                ElevatedButton(
                  onPressed: () {
                    UssdAdvanced.sendUssd(
                        code: _controller.text, subscriptionId: 1);
                  },
                  child: const Text('Front'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String? _res = await UssdAdvanced.sendAdvancedUssd(
                        code: _controller.text, subscriptionId: 1);
                    setState(() {
                      _response = _res;
                    });
                  },
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  // onPressed: () async {
                  //   ussdExecute();
                  // },
                  //////////////////////////////
                  onPressed: () {
                    exit(0);
                  },
                  child: const Text('__CLOSE__'),
                  ////////////////////////////////
                ),
              ],
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await pingServer();
          },
          child: const Icon(Icons.adb),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }
}











// import 'package:flutter/material.dart';
//
// import 'package:flutter/services.dart';
// import 'package:ussd_advanced/ussd_advanced.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   late TextEditingController _controller;
//   String? _response;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = TextEditingController();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('USSD APP Testing'),
//         ),
//         body: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.max,
//           children: [
//             // text input
//             TextField(
//               controller: _controller,
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(labelText: 'Ussd code'),
//             ),
//
//             // dispaly responce if any
//             if (_response != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: Text(_response!),
//               ),
//
//             // buttons
//             Row(
//               mainAxisSize: MainAxisSize.max,
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: () {
//                     UssdAdvanced.sendUssd(
//                         code: _controller.text, subscriptionId: 1);
//                   },
//                   child: const Text('Simple'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     String? _res = await UssdAdvanced.sendAdvancedUssd(
//                         code: "60565103", subscriptionId: 1);
//                     setState(() {
//                       _response = _res;
//                     });
//                   },
//                   child: const Text('advanced'),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

