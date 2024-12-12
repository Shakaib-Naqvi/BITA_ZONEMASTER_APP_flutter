import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:testappbita/Device/pannel.dart';
import 'package:testappbita/Device/qr_code_scanner_page.dart';

// class Device extends StatelessWidget {
//   final String scannedData;

//   const Device({super.key, required this.scannedData});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Device Information'),
//       ),
//       body: Center(
//         child: Container(
//           margin: EdgeInsets.all(16),
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.grey[200],
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 "S: ${scannedData.split('\n')[0]}",
//                 style: TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 8),
//               Text(
//                 "P: ${scannedData.split('\n')[1]}",
//                 style: TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
class DevicesPage extends StatefulWidget {
  String email;
  // const DevicesPage({super.key});
  DevicesPage({required this.email});

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  int _selectedIndex = 0;

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
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SettingsScreen(
                email: widget.email)), // Replace with your target screen
      );
    }
  }

  // Function to get the stream of devices from Firestore
  Stream<QuerySnapshot> getDevices() {
    return FirebaseFirestore.instance.collection(widget.email).snapshots();
  }

  // Function to navigate to another screen (for example, DeviceDetailsPage)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Devices"),
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 204, 241, 162),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getDevices(), // Listening to the stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
              // bottomNavigationBar: BottomNavigationBar(
              //   currentIndex: _selectedIndex,
              //   onTap: _onItemTapped,
              //   items: const <BottomNavigationBarItem>[
              //     BottomNavigationBarItem(
              //       icon: Icon(Icons.home),
              //       // icon: Icon(Icons.settings),
              //       label: 'Home',
              //     ),
              //     BottomNavigationBarItem(
              //       icon: Icon(Icons.devices),
              //       label: 'Add Device',
              //     ),
              //     BottomNavigationBarItem(
              //       icon: Icon(Icons.settings),
              //       label: 'Settings',
              //     ),
              //   ],
              // ),
            ); // Show loading indicator while waiting
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // return Center(child: Text('No devices found.'));
            return Scaffold(
              body: Container(
                color:
                    Colors.lightGreenAccent, // Optional: Set a background color
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Image.asset(
                        "assets/images/device.png", // Replace with your image path
                        width: 300, // Adjust width as needed
                        height: 300, // Adjust height as needed
                        fit: BoxFit.cover, // Adjust how the image fits
                      ),
                      const SizedBox(
                          height:
                              40), // Add some spacing between the image and the button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                30.0), // Rounded rectangle shape
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15), // Button padding
                        ),
                        onPressed: () {
                          // Navigate to the next screen (replace with your target screen)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QRCodeScanner(
                                    email: widget
                                        .email)), // Replace with your target screen
                          );
                        },
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18, // Adjust the text size
                            color: Colors.white, // Text color
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
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
            );
          }

          // Get the documents from the snapshot
          var devices = snapshot.data!.docs;

          return Scaffold(
            body: GridView.builder(
              // shrinkWrap: true,
              itemCount: devices.length,

              itemBuilder: (context, index) {
                var device = devices[index];
                return Column(
                  children: [
                    SingleChildScrollView(
                      child: Container(
                        height: 250,
                        width: 250,
                        // color: const Color.fromARGB(255, 219, 248, 218),
                        padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                        child: Card(
                          color: const Color.fromARGB(255, 226, 226, 226),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 5),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Pannel(
                                          topicssid: (device["device name"] ??
                                              'No name'),
                                        )), // Replace with your target screen
                              );
                              // _showConnectionDialog(
                              // context,
                              // connection['ssid'] ??
                              //     ''); // Ensure a valid string
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Center(
                                child: Column(
                                  // mainAxisAlignment: MainAxisAlignment.center,
                                  // crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(device["device name"] ?? 'No name'),
                                    // style: const TextStyle(fontWeight: FontWeight.bold),

                                    Text(
                                        'device id: ${device['device id'] ?? 'Unknown'}'),
                                  ],
                                  // trailing: const Icon(Icons.wifi),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                // Assuming 'name' and 'status' fields exist in the document
                // return ListTile(
                //   title: Text(device["device name"] ?? 'No name'),
                //   subtitle:
                //       Text('device id: ${device['device id'] ?? 'Unknown'}'),
                // );
              },
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.7),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: 0,
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
          );
        },
      ),
    );
  }
}

// class Work extends StatelessWidget {
//   String email;
//   Work({required this.email});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Home Screen"),
//         backgroundColor: Colors.lightGreen,
//         leading: SizedBox.shrink(), // Removes the back icon
//       ),
//       body: Container(
//         color: Colors.lightGreenAccent, // Optional: Set a background color
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 '',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),
//               Image.asset(
//                 "assets/images/device.png", // Replace with your image path
//                 width: 300, // Adjust width as needed
//                 height: 300, // Adjust height as needed
//                 fit: BoxFit.cover, // Adjust how the image fits
//               ),
//               const SizedBox(
//                   height:
//                       40), // Add some spacing between the image and the button
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green, // Button color
//                   shape: RoundedRectangleBorder(
//                     borderRadius:
//                         BorderRadius.circular(30.0), // Rounded rectangle shape
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 50, vertical: 15), // Button padding
//                 ),
//                 onPressed: () {
//                   // Navigate to the next screen (replace with your target screen)
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => QRCodeScanner(
//                             email: email)), // Replace with your target screen
//                   );
//                 },
//                 child: const Text(
//                   'Get Started',
//                   style: TextStyle(
//                     fontSize: 18, // Adjust the text size
//                     color: Colors.white, // Text color
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
