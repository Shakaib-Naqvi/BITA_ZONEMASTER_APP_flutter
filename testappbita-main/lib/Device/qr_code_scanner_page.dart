import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:testappbita/Device/device.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:testappbita/Device/pannel.dart';
import 'package:testappbita/open_folder/singin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const MyApp());
}

Future<void> saveDevice(String email, String deviceId, String IP,
    String macaddress, String name, String ssiddd) async {
  await FirebaseFirestore.instance.collection(email).doc(ssiddd).set({
    'device id': deviceId,
    'device ip': IP,
    'device mac': macaddress,
    'device name': name,
    'lastUpdated': FieldValue.serverTimestamp(),
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // home: QRCodeScanner(),
    );
  }
}

class QRCodeScanner extends StatefulWidget {
  String email;
  QRCodeScanner({required this.email});

  @override
  _QRCodeScannerState createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends State<QRCodeScanner> {
  bool isScanning = true;
  MobileScannerController cameraController = MobileScannerController();
  List<Map<String, String>> scannedConnections = [];
  String? _previousSSID;
  int _selectedIndex = 1;
  int id = 0;
  // String email = widget.email;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _getCurrentSSID();

    // SigninState email = email;
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.location.request();
  }

  Future<void> _getCurrentSSID() async {
    _previousSSID = await WiFiForIoTPlugin.getSSID();
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty && isScanning) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isScanning = false;
          cameraController.stop();
        });

        _parseQRCode(code);
      }
    }
  }

  void _parseQRCode(String code) {
    final wifiRegex = RegExp(
        r'WIFI:T:[^;]*;S:(?<ssid>[^;]*);P:(?<password>[^;]*);H:(?:true|false|);');

    final wifiMatch = wifiRegex.firstMatch(code);

    if (wifiMatch != null) {
      final ssid = wifiMatch.namedGroup('ssid');
      final password = wifiMatch.namedGroup('password');
      if (ssid != null && password != null) {
        // saveDevice("1", widget.email, ssid, password);
        // saveDevice(ssid.toString(), ssid, password, "12313");

        // _connectToWiFi(ssid, password);
        //  _showWiFiDialog(ssid);
        _showWiFiDialog(ssid, password);
        _showdevicenameDialog(ssid, password);
      }
    } else {
      _navigateToResultScreen("Non-Wi-Fi QR code scanned: $code");
    }
  }

  void _showConnectionDialog(String ssid, String defaultPassword) {
    TextEditingController nameController = TextEditingController();
    TextEditingController passwordController =
        TextEditingController(text: defaultPassword);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connect to Wi-Fi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Connection Name'),
                ),
                TextField(
                  controller: TextEditingController(text: ssid),
                  decoration: const InputDecoration(labelText: 'SSID'),
                  readOnly: true,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Connect'),
              onPressed: () {
                final name = nameController.text;
                final password = passwordController.text;
                if (name.isNotEmpty) {
                  _connectToWiFi(ssid, password);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please provide a name.")),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                disconnectwifi();
                // if (_previousSSID != null) {
                //   String placeholderPassword = '';
                //   _connectToWiFi(
                //           _previousSSID!, placeholderPassword, "Main Wi-Fi")
                //       .then((success) {
                //     if (success) {
                //       Navigator.of(context).pop();
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (context) => const Pannel()),
                //       );
                //     } else {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //             content: Text("Failed to connect to Main Wi-Fi.")),
                //       );
                //     }
                //   });
                // } else {
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     const SnackBar(
                //         content: Text("No previous Wi-Fi connection found.")),
                //   );
                // }
              },
            ),
          ],
        );
      },
    );
  }

  void diconnectwifi() async {
    final disconnectedd = await WiFiForIoTPlugin.disconnect();
    if (disconnectedd) {
      print("Disconnected");
    } else {
      print("Not Disconnected");
    }
  }

  Future<bool> _connectToWiFi(String ssid, String password) async {
    bool result =
        await WiFiForIoTPlugin.findAndConnect(ssid, password: password);

    String connectionStatus =
        result ? 'Connected to $ssid' : 'Failed to connect to $ssid';

    _navigateToResultScreen(connectionStatus, ssid, password);
    if (result) {
      _showWiFiDialog(ssid, password);
    } else {
      print("Not Connected  with Damper");
    }
    return result;
  }

  void _navigateToResultScreen(String result,
      [String? ssid, String? password, String? name]) {
    setState(() {
      if (ssid != null && password != null && name != null) {
        scannedConnections
            .add({'ssid': ssid, 'password': password, 'name': name});
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectionResultScreen(
            result: result, connections: scannedConnections),
      ),
    ).then((_) {
      setState(() {
        isScanning = true;
        cameraController.start();
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DevicesPage(
                  email: widget.email)), // Replace with your target screen
        );
      } else if (_selectedIndex == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SettingsScreen(email: widget.email),
          ),
        );
      }
    });
  }

  void _showWiFiDialog(String ssid, String password) {
    TextEditingController nameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connect Damper to Wi-Fi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Connection Name'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // TextButton(
            //   child: const Text('Connect'),
            //   onPressed: () {
            //     final ssidd = nameController.text;
            //     final pass = passwordController.text;
            //     if (ssidd.isNotEmpty) {
            //       _connectToWiFi(ssid, password);
            //     } else {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(content: Text("Please provide a name.")),
            //       );
            //     }
            //     Navigator.of(context).pop();
            //   },
            // ),
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                final ssidd = nameController.text;
                final pass = passwordController.text;
                final ip = passwordController.text;

                if (ssidd != null) {
                  // String placeholderPassword =
                  //     ''; // Placeholder, could be customized
                  diconnectwifi();
                  String connectionStatus = true
                      ? 'Connected to $ssid'
                      : 'Failed to connect to $ssid';

                  // _navigateToResultScreen(connectionStatus, ssid, password);

                  // _connectToWiFi(ssid, placeholderPassword);
                }
                // id++;
                // saveDevice(ssid.toString(), ssidd, pass, ip);
                // saveDevice(widget.email, id, ip, ip,ssidd);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showdevicenameDialog(String ssid, String password) {
    TextEditingController nameController = TextEditingController();
    TextEditingController macController = TextEditingController();
    TextEditingController IPController = TextEditingController();
    TextEditingController IDController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connect Damper to Wi-Fi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Device Name'),
                ),
                TextField(
                  controller: IDController,
                  decoration: const InputDecoration(labelText: 'ID'),
                  obscureText: true,
                ),
                TextField(
                  controller: IPController,
                  decoration: const InputDecoration(labelText: 'IP'),
                  obscureText: true,
                ),
                TextField(
                  controller: macController,
                  decoration: const InputDecoration(labelText: 'Mac Address'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // TextButton(
            //   child: const Text('Connect'),
            //   onPressed: () {
            //     final ssidd = nameController.text;
            //     final pass = passwordController.text;
            //     if (ssidd.isNotEmpty) {
            //       _connectToWiFi(ssid, password);
            //     } else {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(content: Text("Please provide a name.")),
            //       );
            //     }
            //     Navigator.of(context).pop();
            //   },
            // ),
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                final ssidd = nameController.text;
                final id = IDController.text;
                final ip = IPController.text;
                final mac = macController.text;

                if (ssidd != null) {
                  // String placeholderPassword =
                  //     ''; // Placeholder, could be customized
                  diconnectwifi();
                  String connectionStatus = true
                      ? 'Connected to $ssid'
                      : 'Failed to connect to $ssid';

                  // _navigateToResultScreen(connectionStatus, ssid, password);

                  // _connectToWiFi(ssid, placeholderPassword);
                }
                // id++;
                // saveDevice(ssid.toString(), ssidd, pass, ip);
                String deviceid = ssid;
                saveDevice(widget.email, deviceid, ip, mac, ssidd, ssid);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DevicesPage(email: widget.email),
          ),
          (route) => false, // Remove all routes from the stack
        );
        return false; // Prevent the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('QR Code Scanner'),
          actions: [
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => cameraController.switchCamera(),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isScanning
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MobileScanner(
                        controller: cameraController,
                        onDetect: _onDetect,
                      ),
                    )
                  : const Center(child: Text('Scanning stopped')),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: 'Add Device',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

void disconnectwifi() async {
  final disconnectedd = await WiFiForIoTPlugin.disconnect();
  if (disconnectedd) {
    print("Disconnected");
  } else {
    print("Not Disconnected");
  }
}

// void _navigateToAddDevicePage(BuildContext context) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//         builder: (context) => DevicesPage(
//             email: widget.email)), // Replace with your target screen
//   );
// }

// class DevicesPage extends StatelessWidget {
//   String email;
//   DevicesPage({required this.email});

//   // Function to get the stream of devices from Firestore
//   Stream<QuerySnapshot> getDevices() {
//     return FirebaseFirestore.instance.collection(email).snapshots();
//   }

//   // Function to navigate to another screen (for example, DeviceDetailsPage)

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Devices")),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: getDevices(), // Listening to the stream
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//                 child:
//                     CircularProgressIndicator()); // Show loading indicator while waiting
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No devices found.'));
//           }

//           // Get the documents from the snapshot
//           var devices = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: devices.length,
//             itemBuilder: (context, index) {
//               var device = devices[index];
//               // Assuming 'name' and 'status' fields exist in the document
//               return ListTile(
//                 title: Text(device["device name"] ?? 'No name'),
//                 subtitle:
//                     Text('device id: ${device['device id'] ?? 'Unknown'}'),
//               );
//             },
//           );
//         },
//       ),
//       // Floating action button to trigger navigation
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => QRCodeScanner(email: email),
//         child: Icon(Icons.add), // Icon for the button
//         tooltip: 'Add Device',
//       ),
//     );
//   }
// }

class ConnectionResultScreen extends StatefulWidget {
  final String result;
  final List<Map<String, String>> connections;

  const ConnectionResultScreen(
      {super.key, required this.result, required this.connections});

  @override
  _ConnectionResultScreenState createState() => _ConnectionResultScreenState();
}

class _ConnectionResultScreenState extends State<ConnectionResultScreen> {
  String ssid = "";
  String password = "";
  String? connectionStatus = 'Not Connected';

  @override
  void initState() {
    super.initState();
    _parseResult();
  }

  void _parseResult() {
    final wifiRegex =
        RegExp(r'Connected to (?<ssid>[^\n;]+)(?:;P:(?<password>[^\n]+))?');
    final match = wifiRegex.firstMatch(widget.result);

    if (match != null) {
      setState(() {
        ssid = match.namedGroup('ssid')!;
        password = match.namedGroup('password')!;
      });
    } else {
      setState(() {
        ssid = "";
        password = ""; // No password detected
      });
    }
  }

  void diconnectwifi() async {
    final disconnectedd = await WiFiForIoTPlugin.disconnect();
    if (disconnectedd) {
      print("Disconnected");
    } else {
      print("Not Disconnected");
    }
  }

  // Future<void> _connectToWiFi(String ssid, String password) async {
  //   bool result =
  //       await WiFiForIoTPlugin.findAndConnect(ssid, password: password);
  //   String connectionStatusMessage =
  //       result ? 'Connected to $ssid' : 'Failed to connect to $ssid';

  //   setState(() {
  //     connectionStatus = connectionStatusMessage;
  //   });

  //   if (result) {
  //     // Navigate to the Pannel screen directly upon a successful connection
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => Pannel(topicssid: ssid)),
  //     );
  //   } else {
  //     _showConnectionStatusDialog(context, connectionStatusMessage);
  //   }
  // }

  void _showConnectionStatusDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.contains('Failed') ? 'Failure' : 'Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWiFiDialog(String ssid) {
    TextEditingController nameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connect to Existing Wi-Fi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Connection Name'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Connect'),
              onPressed: () {
                final name = nameController.text;
                final password = passwordController.text;
                if (name.isNotEmpty) {
                  // _connectToWiFi(ssid, password);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please provide a name.")),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Switch to Main Wi-Fi'),
              onPressed: () {
                if (ssid != null) {
                  String placeholderPassword =
                      ''; // Placeholder, could be customized
                  diconnectwifi();
                  // _connectToWiFi(ssid, placeholderPassword);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(1),
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Pannel(topicssid: ssid)),
                  );
                },
                child: Align(
                  alignment:
                      Alignment.centerLeft, // Aligns the container to the left
                  child: Container(
                    height: 250,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      color: Colors.grey, // Add a background color
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Align children to the start
                      children: [
                        if (ssid != null)
                          Container(
                            alignment: Alignment
                                .center, // Centers the content inside the container
                            child: Text(
                              '$ssid',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16), // Spacing between widgets
                        Center(
                          child: const Text(
                            'Damper',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // Additional spacing
                      ],
                    ),
                  ),
                ),
              ),

              // Displaying the list of connections
              Expanded(
                child: ListView.builder(
                  itemCount: widget.connections.length,
                  itemBuilder: (context, index) {
                    final connection = widget.connections[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          connection['name'] ?? 'Unknown Connection',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(connection['ssid'] ?? 'Unknown SSID'),
                        trailing: const Icon(Icons.wifi),
                        onTap: () {
                          // _showConnectionDialog(
                          // context,
                          // connection['ssid'] ??
                          //     ''); // Ensure a valid string
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  String email;
  // const SettingsScreen({super.key});
  SettingsScreen({required this.email});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _sliderValue1 = 0.5;
  double _sliderValue2 = 0.5;
  double _sliderValue3 = 0.5;
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DevicesPage(
                email: widget.email)), // Replace with your target screen
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => QRCodeScanner(
                email: widget.email)), // Replace with your target screen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DevicesPage(email: widget.email),
          ),
          (route) => false, // Remove all routes from the stack
        );
        return false; // Prevent the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard item opacity',
                            style: TextStyle(fontSize: 18),
                          ),
                          Slider(
                            value: _sliderValue1,
                            min: 0,
                            max: 1,
                            onChanged: (value) {
                              setState(() {
                                _sliderValue1 = value;
                              });
                            },
                          ),
                          Text('Value: ${_sliderValue1.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.brightness_6),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device item opacity',
                            style: TextStyle(fontSize: 18),
                          ),
                          Slider(
                            value: _sliderValue2,
                            min: 0,
                            max: 1,
                            onChanged: (value) {
                              setState(() {
                                _sliderValue2 = value;
                              });
                            },
                          ),
                          Text('Value: ${_sliderValue2.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data interval',
                          style: TextStyle(fontSize: 18),
                        ),
                        Slider(
                          value: _sliderValue3,
                          min: 0,
                          max: 1,
                          onChanged: (value) {
                            setState(() {
                              _sliderValue3 = value;
                            });
                          },
                        ),
                        Text('Value: ${_sliderValue3.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 32.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Signin()),
                    );
                  },
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 2,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              // icon: Icon(Icons.settings),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: 'Add Device',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
