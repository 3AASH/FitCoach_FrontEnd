import 'package:flutter/material.dart';

import '../messaging/coach_messaging_screen.dart';

class CoachMessageThreadScreen extends StatelessWidget {
  final String clientId;
  final String clientName;

  const CoachMessageThreadScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return CoachMessagingScreen(
      targetClientId: clientId,
      targetClientName: clientName,
    );
  }
}
