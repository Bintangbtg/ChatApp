import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _messages =
      FirebaseFirestore.instance.collection('messages');
  bool isOnline = true; // Status online/offline

  // Fungsi untuk mengirim pesan
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    await _messages.add({
      'message': message,
      'sender': 'Anonymous', // Nama pengirim (bisa diganti dengan autentikasi)
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  void initState() {
    super.initState();
    _checkConnection(); // Cek koneksi internet
  }

  Future<void> _checkConnection() async {
    // Simulasi status online/offline
    Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        isOnline = !isOnline; // Ganti status secara periodik (contoh simulasi)
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: isOnline ? Colors.green : Colors.red,
              radius: 6,
            ),
            SizedBox(width: 8),
            Text("Offline Chat"),
          ],
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messages
                  .orderBy('timestamp', descending: true)
                  .snapshots(), // Ambil data terbaru
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages yet."));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(Icons.person, color: Colors.white),
                            backgroundColor: Colors.blueAccent,
                          ),
                          title: Text(
                            doc['message'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(doc['sender']),
                          trailing: Text(
                            doc['timestamp'] != null
                                ? (doc['timestamp'] as Timestamp)
                                    .toDate()
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16)
                                : "Now",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: "Enter your message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_controller.text),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
