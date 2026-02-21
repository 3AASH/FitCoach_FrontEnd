import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../providers/quota_provider.dart';
import '../providers/language_provider.dart';

class QuotaIndicator extends StatelessWidget {
  final String type; // 'message' or 'videoCall'
  final bool showDetails;
  
  const QuotaIndicator({
    super.key,
    required this.type,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final quotaProvider = context.watch<QuotaProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final translator = languageProvider.t;
    
    final isMessage = type == 'message';
    final limit = isMessage ? quotaProvider.messagesLimit : quotaProvider.videoCallsLimit;
    final remaining = isMessage ? quotaProvider.messagesRemaining : quotaProvider.videoCallsRemaining;
    final percentage = isMessage
        ? quotaProvider.messagesUsagePercentage
        : quotaProvider.videoCallsUsagePercentage;
    
    // Unlimited messages (Smart Premium)
    if (limit == -1 && isMessage) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.all_inclusive, color: AppColors.success, size: 16),
            const SizedBox(width: 6),
            Text(
              translator('unlimited_messages'),
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    // Determine color based on remaining quota
    Color getColor() {
      if (remaining <= 0) return AppColors.error;
      if (percentage > 0.8) return AppColors.warning;
      return AppColors.success;
    }
    
    final color = getColor();
    
    if (!showDetails) {
      // Compact version
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMessage ? Icons.message : Icons.videocam,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '$remaining / $limit',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    // Detailed version
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMessage ? Icons.message : Icons.videocam,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isMessage
                    ? translator('messages_remaining_label')
                    : translator('video_calls_remaining_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$remaining',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ $limit',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          if (remaining <= 5 && remaining > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    translator(
                      'quota_warning',
                      args: {'remaining': remaining.toString()},
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (remaining <= 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      translator(isMessage ? 'quota_exceeded' : 'video_call_quota_exceeded'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QuotaBanner extends StatelessWidget {
  final String type;
  
  const QuotaBanner({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final quotaProvider = context.watch<QuotaProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final translator = languageProvider.t;
    
    final isMessage = type == 'message';
    final canProceed = isMessage 
        ? quotaProvider.canSendMessage() 
        : quotaProvider.canMakeVideoCall();
    
    if (canProceed) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.block,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translator(isMessage ? 'quota_exceeded' : 'video_call_quota_exceeded'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translator('quota_upgrade_prompt'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to subscription upgrade
            },
            child: Text(translator('upgrade')),
          ),
        ],
      ),
    );
  }
}
