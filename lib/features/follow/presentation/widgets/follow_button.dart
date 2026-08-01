import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/follow_provider.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../l10n/app_localizations.dart';

/// Bouton "Suivre" / "Suivi" pour s'abonner ou se désabonner d'un profil.
class FollowButton extends ConsumerStatefulWidget {
  final String targetUserId;
  final VoidCallback? onChanged;

  const FollowButton({super.key, required this.targetUserId, this.onChanged});

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _isSubmitting = false;

  Future<void> _handleTap() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.toggleFollow(widget.targetUserId);
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowingAsync = ref.watch(isFollowingProvider(widget.targetUserId));
    final l10n = AppLocalizations.of(context)!;
    final isFollowing = isFollowingAsync.value ?? false;
    final isLoading = _isSubmitting || isFollowingAsync.isLoading;

    if (isFollowing) {
      return SecondaryButton(
        text: l10n.unfollowButton,
        isLoading: isLoading,
        onPressed: _handleTap,
      );
    }

    return PrimaryButton(
      text: l10n.followButton,
      isLoading: isLoading,
      onPressed: _handleTap,
    );
  }
}
