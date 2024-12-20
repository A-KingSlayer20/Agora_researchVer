import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

// Fill in the app ID obtained from the Agora console
const appId = "7453c8a0ed7d4055996ff1de11459110";
// Fill in the temporary token generated using Agora console
const token =
    "007eJxTYHCQPrOyQv3enGszNtyQr9ytUNMQeEj7lo5bn0j5BcF75QwKDOYmpsbJFokGqSnmKSYGpqaWlmZpaYYpqYaGJqaWhoYGi7lS0hsCGRm+7i9jZWSAQBCfjSEktbikzICBAQBdrR84";
// Fill in the channel name
const channel = "Testv0";

// Application class
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

// Application state class
class _MyAppState extends State<MyApp> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false; // For mute toggle
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  // Initialize Agora
  Future<void> initAgora() async {
  // Request microphone permission
  await [Permission.microphone].request();

  // Create an RtcEngine instance
  _engine = await createAgoraRtcEngine();

  // Initialize RtcEngine and set the channel profile
  await _engine.initialize(const RtcEngineContext(
    appId: appId,
    channelProfile: ChannelProfileType.channelProfileCommunication,
  ));

  // Enable volume indication
  await _engine.enableAudioVolumeIndication(
    interval: 200, // Report volume every 200ms
    smooth: 3,     // Smoothing factor for volume levels
    reportVad: true, // Enable voice activity detection (VAD)
  );

  double _lastTotalVolume = 0; // Track the last reported volume
  const double _volumeThreshold = 10; // Set a threshold for significant change

  // Register engine event handlers
  _engine.registerEventHandler(
    RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint('local user ${connection.localUid} joined');
        setState(() => _localUserJoined = true);
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("remote user $remoteUid joined");
        setState(() => _remoteUid = remoteUid);
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint("remote user $remoteUid left the channel");
        setState(() => _remoteUid = null);
      },
      onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int vad) {
        // Check if the volume change is significant
        if ((totalVolume.toDouble() - _lastTotalVolume).abs() > _volumeThreshold) {
          debugPrint("Significant volume change detected!");
          debugPrint("Total volume: $totalVolume");
          for (var speaker in speakers) {
            debugPrint("UID: ${speaker.uid}, Volume: ${speaker.volume}");
          }
        }
        _lastTotalVolume = totalVolume.toDouble(); // Update the last recorded volume
      },
    ),
  );

  // Join the channel
  await _engine.joinChannel(
    token: token,
    channelId: channel,
    options: const ChannelMediaOptions(
      autoSubscribeAudio: true, // Subscribe to audio streams
      publishMicrophoneTrack: true, // Publish microphone audio
      clientRoleType: ClientRoleType.clientRoleBroadcaster, // User role: broadcaster
    ),
    uid: 0, // Let Agora assign a random UID
  );
}


  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel(); // Leave the channel
    await _engine.release(); // Release resources
  }

  // Mute Toggle
  void _toggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteLocalAudioStream(_muted);
  }

  // Leave Channel
  Future<void> _leaveChannel() async {
    try {
      await _engine.leaveChannel();
      setState(() {
        _localUserJoined = false;
        _remoteUid = null;
      });
      debugPrint("Left the channel successfully");
    } catch (e) {
      debugPrint("Error leaving the channel: $e");
    }
  }

  // Build the UI
  // Build the UI
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Agora Voice Call',
    home: Scaffold(
      appBar: AppBar(
        title: Text('Agora Voice Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _localUserJoined
                  ? "Local user joined the channel"
                  : "Joining channel...",
              style: TextStyle(fontSize: 16),
            ),
            if (_remoteUid != null)
              Text(
                "Remote user $_remoteUid joined",
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _muted = !_muted; // Toggle the mute state
                });
                _engine.muteLocalAudioStream(_muted); // Enable/Disable microphone
              },
              child: Text(_muted ? "Unmute" : "Mute"), // Update button text
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _leaveChannel,
              child: Text("Leave Channel"),
            ),
          ],
        ),
      ),
    ),
  );
}
}
