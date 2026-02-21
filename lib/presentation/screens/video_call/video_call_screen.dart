import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/config/demo_config.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../providers/video_call_provider.dart';
import '../../widgets/rating_modal.dart';

/// Video Call Screen with Agora RTC
/// Handles in-app video calls between user and coach
class VideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String coachId;
  final String coachName;
  final bool isCoach;
  final RatingRepository? ratingRepository;
  final bool autoInitialize;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.coachId,
    required this.coachName,
    this.isCoach = false,
    this.ratingRepository,
    this.autoInitialize = true,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _callTimer;
  int _callDuration = 0; // in seconds

  String? _token;
  String? _channelName;
  int? _uid;
  String? _appId;
  bool _engineInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoInitialize) {
      _initializeVideoCall();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _initializeVideoCall() async {
    final provider = Provider.of<VideoCallProvider>(context, listen: false);
    try {
      // Request permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        setState(() {
          _errorMessage = 'Camera and microphone permissions are required';
          _isLoading = false;
        });
        return;
      }

      // Get call token from backend
      final joinStatus = await provider.canJoinCall(widget.appointmentId);
      if (joinStatus == null || joinStatus['canJoin'] != true) {
        setState(() {
          _errorMessage = joinStatus?['reason'] ?? 'Unable to join call right now';
          _isLoading = false;
        });
        return;
      }
      final callData = await provider.startCall(widget.appointmentId);

      if (callData == null) {
        setState(() {
          _errorMessage = 'Failed to start call. Please try again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _token = callData['token'];
        _channelName = callData['channelName'];
        _uid = callData['uid'];
        _appId = callData['appId'];
      });

      // Initialize Agora
      await _initializeAgora();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    return statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;
  }

  Future<void> _initializeAgora() async {
    try {
      // Create RTC engine
      _engine = createAgoraRtcEngine();
      _engineInitialized = true;

      // Initialize engine
      await _engine.initialize(RtcEngineContext(
        appId: _appId!,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Local user joined: ${connection.localUid}');
            setState(() {
              _localUserJoined = true;
              _isLoading = false;
            });
            _startCallTimer();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user joined: $remoteUid');
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('Remote user offline: $remoteUid');
            setState(() {
              _remoteUid = null;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora error: $err - $msg');
          },
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state, ConnectionChangedReasonType reason) {
            debugPrint('Connection state changed: $state');
          },
        ),
      );

      // Enable video
      await _engine.enableVideo();
      await _engine.enableAudio();
      await _engine.startPreview();

      // Set video encoder configuration
      await _engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 0,
        ),
      );

      // Join channel
      await _engine.joinChannel(
        token: _token!,
        channelId: _channelName!,
        uid: _uid!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      debugPrint('Agora initialization error: $e');
      setState(() {
        _errorMessage = 'Failed to initialize video call: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    await _engine.muteLocalVideoStream(_isCameraOff);
  }

  Future<void> _switchCamera() async {
    await _engine.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  Future<void> _endCall() async {
    final provider = Provider.of<VideoCallProvider>(context, listen: false);
    // Stop timer
    _callTimer?.cancel();

    // Calculate duration in minutes
    final durationMinutes = (_callDuration / 60).ceil();

    // Leave channel
    await _engine.leaveChannel();

    // Send end call to backend
    await provider.endCall(widget.appointmentId, durationMinutes);

    // Navigate back
    if (mounted) {
      Navigator.of(context).pop();

      // Show rating modal for user (not coach)
      if (!widget.isCoach) {
        await Future.delayed(const Duration(milliseconds: 500));
        _showRatingModal();
      }
    }
  }

  void _showRatingModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingModal(
        type: 'video_call',
        onSubmit: (rating, comment) {
          _submitRating(rating, comment);
        },
      ),
    );
  }

  Future<void> _submitRating(int rating, String? comment) async {
    if (DemoConfig.isDemo) {
      return;
    }

    try {
      final repository = widget.ratingRepository ?? RatingRepository();
      await repository.submitVideoCallRating(
        coachId: widget.coachId,
        appointmentId: widget.appointmentId,
        rating: rating,
        feedback: comment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your feedback.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit rating.'),
        ),
      );
    }
  }

  @visibleForTesting
  Future<void> submitRatingForTest(int rating, String? comment) {
    return _submitRating(rating, comment);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    if (_engineInitialized) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Connecting to call...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          _remoteVideo(),

          // Local video (picture-in-picture)
          Positioned(
            top: 50,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Call timer
          Positioned(
            top: 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Other party name
          if (_remoteUid == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    'Waiting for ${widget.coachName} to join...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _channelName),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 80, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                widget.coachName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Unmute' : 'Mute',
            color: _isMuted ? Colors.red : Colors.white,
            backgroundColor: _isMuted ? Colors.white : Colors.black54,
            onPressed: _toggleMute,
          ),

          // Camera toggle button
          _buildControlButton(
            icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
            label: _isCameraOff ? 'Camera Off' : 'Camera On',
            color: _isCameraOff ? Colors.red : Colors.white,
            backgroundColor: _isCameraOff ? Colors.white : Colors.black54,
            onPressed: _toggleCamera,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End Call',
            color: Colors.white,
            backgroundColor: Colors.red,
            onPressed: () => _showEndCallDialog(),
            isLarge: true,
          ),

          // Switch camera button
          _buildControlButton(
            icon: Icons.switch_camera,
            label: 'Switch',
            color: Colors.white,
            backgroundColor: Colors.black54,
            onPressed: _switchCamera,
          ),

          // Speaker button
          _buildControlButton(
            icon: Icons.volume_up,
            label: 'Speaker',
            color: Colors.white,
            backgroundColor: Colors.black54,
            onPressed: () {
              // Toggle speaker (already enabled by default in communication mode)
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    final size = isLarge ? 60.0 : 50.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showEndCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endCall();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }
}
