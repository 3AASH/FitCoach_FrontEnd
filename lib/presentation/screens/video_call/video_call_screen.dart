import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twilio_flutter_video_sdk/twilio_flutter_video_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/config/demo_config.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/video_call_provider.dart';
import '../../widgets/rating_modal.dart';

/// Video Call Screen with Twilio Programmable Video
/// Handles in-app native video calls between user and coach.
///
/// Connects to a Twilio Room using the `token` + `roomName` minted by the
/// backend (`/video-calls/:appointmentId/start`). Twilio identifies the local
/// participant by the `identity` baked into the access-token JWT, so we do not
/// use Agora's numeric `uid` here.
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
  TwilioVideoController? _controller;
  TwilioVideoRoom? _room;

  // Remote participant video tracks, keyed by participantSid. For a 1:1 call
  // there is a single entry, but we track a set to stay robust.
  final Set<String> _remoteSids = {};

  bool _localConnected = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _callTimer;
  int _callDuration = 0; // in seconds

  StreamSubscription<TwilioVideoEvent>? _eventsSub;
  StreamSubscription<VideoTrackInfo>? _trackSub;
  StreamSubscription<String>? _errorsSub;

  // Text on this screen is also reached from async callbacks and from stream handlers,
  // not only from build(), so read the provider without listening.
  String _tr(String key, {Map<String, String>? args}) =>
      Provider.of<LanguageProvider>(context, listen: false)
          .translate(key, args: args);

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
          _errorMessage = _tr('video_call_permission_required');
          _isLoading = false;
        });
        return;
      }

      // Gate check
      final joinStatus = await provider.canJoinCall(widget.appointmentId);
      if (joinStatus == null || joinStatus['canJoin'] != true) {
        setState(() {
          // `reason` comes from the backend already worded for the user.
          _errorMessage =
              joinStatus?['reason'] ?? _tr('video_call_cannot_join_now');
          _isLoading = false;
        });
        return;
      }

      // Create session + get token from backend
      final callData = await provider.startCall(widget.appointmentId);
      if (callData == null) {
        setState(() {
          _errorMessage = _tr('video_call_start_failed');
          _isLoading = false;
        });
        return;
      }

      final token = callData['token'] as String?;
      // Backend sends roomName for Twilio; channelName carries the same value.
      final roomName =
          (callData['roomName'] ?? callData['channelName']) as String?;

      if (token == null || roomName == null) {
        setState(() {
          _errorMessage = _tr('video_call_config_incomplete');
          _isLoading = false;
        });
        return;
      }

      await _connectToRoom(token, roomName);
    } catch (e) {
      // The exception text is for the log, not for the user: it is English, it is not
      // actionable, and this screen is the video call gate.
      debugPrint('Video call initialization error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = _tr('video_call_start_failed');
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final camera = statuses[Permission.camera]!;
    final microphone = statuses[Permission.microphone]!;

    if (camera.isGranted && microphone.isGranted) {
      return true;
    }

    // On iOS, once a permission is denied the system never prompts again, so
    // `.request()` returns immediately without a dialog. In that case deep-link
    // the user to the app's Settings page where they can enable it manually.
    if (camera.isPermanentlyDenied ||
        microphone.isPermanentlyDenied ||
        camera.isDenied ||
        microphone.isDenied) {
      await openAppSettings();
    }

    return false;
  }

  Future<void> _connectToRoom(String token, String roomName) async {
    try {
      final controller = TwilioVideoController();
      final room = controller.createRoom();
      _controller = controller;
      _room = room;

      // Connection lifecycle
      _eventsSub = room.events.listen((event) {
        switch (event) {
          case TwilioVideoEvent.connected:
            if (!mounted) return;
            setState(() {
              _localConnected = true;
              _isLoading = false;
            });
            _startCallTimer();
            break;
          case TwilioVideoEvent.disconnected:
            // Remote/room teardown — clear remote tiles.
            if (!mounted) return;
            setState(() => _remoteSids.clear());
            break;
          case TwilioVideoEvent.connectionFailure:
            if (!mounted) return;
            setState(() {
              _errorMessage = _tr('video_call_connect_failed');
              _isLoading = false;
            });
            break;
          case TwilioVideoEvent.participantDisconnected:
            // Tile removal is driven by videoTrackEvents below.
            break;
          default:
            break;
        }
      });

      // Remote video tile lifecycle: render only when the track is enabled and
      // its native view is ready (per the SDK's guidance).
      _trackSub = room.videoTrackEvents.listen((track) {
        if (!mounted) return;
        setState(() {
          if (track.isEnabled && track.nativeViewReady) {
            _remoteSids.add(track.participantSid);
          } else {
            _remoteSids.remove(track.participantSid);
          }
        });
      });

      _errorsSub = room.errors.listen((err) {
        debugPrint('Twilio video error: $err');
      });

      await room.joinRoom(
        RoomOptions(
          accessToken: token,
          roomName: roomName,
          enableAudio: true,
          enableVideo: true,
          enableFrontCamera: true,
        ),
      );
    } catch (e) {
      debugPrint('Twilio connect error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = _tr('video_call_connect_failed');
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
    final next = !_isMuted;
    setState(() => _isMuted = next);
    await _room?.setMuted(next);
  }

  Future<void> _toggleCamera() async {
    final next = !_isCameraOff;
    setState(() => _isCameraOff = next);
    await _room?.setVideoEnabled(!next);
  }

  Future<void> _switchCamera() async {
    await _room?.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  Future<void> _endCall() async {
    final provider = Provider.of<VideoCallProvider>(context, listen: false);
    _callTimer?.cancel();

    final durationMinutes = (_callDuration / 60).ceil();

    // Leave the Twilio room
    await _room?.disconnect();

    // Notify backend
    await provider.endCall(widget.appointmentId, durationMinutes);

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
        SnackBar(
          content: Text(_tr('video_call_rating_thanks')),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('video_call_rating_failed')),
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
    _eventsSub?.cancel();
    _trackSub?.cancel();
    _errorsSub?.cancel();
    _room?.disconnect();
    _controller?.dispose();
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
                _tr('video_call_connecting'),
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
                child: Text(_tr('back')),
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
                child: (_localConnected && !_isCameraOff)
                    ? const TwilioVideoView(viewId: '0')
                    : Container(
                        color: Colors.grey[900],
                        child: Center(
                          child: _localConnected
                              ? const Icon(Icons.videocam_off,
                                  color: Colors.white54)
                              : const CircularProgressIndicator(
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

          // Waiting-for-remote overlay
          if (_remoteSids.isEmpty)
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
    if (_remoteSids.isNotEmpty) {
      // 1:1 call — render the first remote participant full-screen.
      final sid = _remoteSids.first;
      return SizedBox.expand(
        child: TwilioVideoView(viewId: sid),
      );
    }
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

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? _tr('video_call_unmute') : _tr('video_call_mute'),
            color: _isMuted ? Colors.red : Colors.white,
            backgroundColor: _isMuted ? Colors.white : Colors.black54,
            onPressed: _toggleMute,
          ),

          // Camera toggle button
          _buildControlButton(
            icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
            label: _isCameraOff
                ? _tr('video_call_camera_off')
                : _tr('video_call_camera_on'),
            color: _isCameraOff ? Colors.red : Colors.white,
            backgroundColor: _isCameraOff ? Colors.white : Colors.black54,
            onPressed: _toggleCamera,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            label: _tr('video_call_end'),
            color: Colors.white,
            backgroundColor: Colors.red,
            onPressed: () => _showEndCallDialog(),
            isLarge: true,
          ),

          // Switch camera button
          _buildControlButton(
            icon: Icons.switch_camera,
            label: _tr('video_call_switch_camera'),
            color: Colors.white,
            backgroundColor: Colors.black54,
            onPressed: _switchCamera,
          ),

          // Speaker button
          _buildControlButton(
            icon: Icons.volume_up,
            label: _tr('video_call_speaker'),
            color: Colors.white,
            backgroundColor: Colors.black54,
            onPressed: () {
              // Speaker is enabled by default for video rooms.
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
        title: Text(_tr('video_call_end')),
        content: Text(_tr('video_call_end_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endCall();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_tr('video_call_end')),
          ),
        ],
      ),
    );
  }
}
