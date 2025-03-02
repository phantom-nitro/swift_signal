import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});
  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _firestore = FirebaseFirestore.instance;
  bool _isAlarmPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
    _subscribeToAlerts();
    _setupAudioPlayerListener();
  }

  void _setupAudioPlayerListener() {
    // Set up a listener to restart the audio when it completes
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isAlarmPlaying) {
        _audioPlayer.play(AssetSource('alert.mp3'));
      }
    });
  }

  Future<void> _setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
   
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _playAlertSound();
    });
  }

  void _subscribeToAlerts() {
    _firestore.collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final latestAlert = snapshot.docs.first;
        final timestamp = latestAlert.data()['timestamp'] as Timestamp;
       
        // Only play sound for alerts within the last minute
        if (timestamp.toDate().isAfter(
          DateTime.now().subtract(const Duration(minutes: 1))
        )) {
          _playAlertSound();
        }
      }
    });
  }

  Future<void> _playAlertSound() async {
    // Only start playing if not already playing
    if (!_isAlarmPlaying) {
      setState(() {
        _isAlarmPlaying = true;
      });
      await _audioPlayer.play(AssetSource('alert.mp3'));
    }
  }

  void _stopAlarm() {
    setState(() {
      _isAlarmPlaying = false;
    });
    _audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        actions: [
          // Show stop button only when alarm is playing
          if (_isAlarmPlaying)
            IconButton(
              icon: const Icon(Icons.volume_off),
              onPressed: _stopAlarm,
              tooltip: 'Stop Alarm',
            ),
        ],
      ),
      body: Column(
        children: [
          // Show a visible alert banner when alarm is playing
          if (_isAlarmPlaying)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'ALERT IN PROGRESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _stopAlarm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('STOP ALARM'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('alerts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading alerts'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No alerts'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final alert = snapshot.data!.docs[index];
                    final data = alert.data() as Map<String, dynamic>;
                    final timestamp = (data['timestamp'] as Timestamp).toDate();
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          data['message'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          timestamp.toString(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}