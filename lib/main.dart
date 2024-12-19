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
  _MyAppState createState() => _MyAppState();
}

// Application state class
class _MyAppState extends State<MyApp> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  // Initialize
  Future<void> initAgora() async {
    // Get permission
    await [Permission.microphone].request();

    // Create an RtcEngine instance
    _engine = await createAgoraRtcEngine();

    // Initialize RtcEngine and set the channel profile
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Handle engine events
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint(
              'local user ' + connection.localUid.toString() + ' joined');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    // Join a channel using a temporary token and channel name
    await _engine.joinChannel(
      token: token,
      channelId: channel,
      options: const ChannelMediaOptions(
          // Automatically subscribe to all audio streams
          autoSubscribeAudio: true,
          // Publish microphone audio
          publishMicrophoneTrack: true,
          // Set user role to clientRoleBroadcaster (broadcaster) or clientRoleAudience (audience)
          clientRoleType: ClientRoleType.clientRoleBroadcaster),
      uid:
          0, // When you set uid to 0, a user name is randomly generated by the engine
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
          child: Text('Have a voice call!'),
        ),
      ),
    );
  }
}
