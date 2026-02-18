import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/features/feed/models/content_operation_model.dart';
import 'package:seattle_pulse_mobile/src/features/feed/widgets/report_content_dialog.dart';
import 'package:seattle_pulse_mobile/src/features/feed/providers/content_operations_provider.dart';

class PostOptionsMenu extends ConsumerWidget {
  final int contentId;
  final bool isOwner;
  final void Function()? onCopyLink;
  final Function(String) onSuccess;
  final Function(String) onError;

  const PostOptionsMenu({
    Key? key,
    required this.contentId,
    required this.isOwner,
    this.onCopyLink,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operationsState = ref.watch(contentOperationsProvider);
    final operationsNotifier = ref.read(contentOperationsProvider.notifier);

    // Debug info
    debugPrint(
        "PostOptionsMenu: contentId=$contentId, isOwner=$isOwner, isOwner type=${isOwner.runtimeType}");

    // List of menu items to show based on conditions
    final List<Widget> menuItems = [
      // Copy link - always shown
      _buildOption(
        context,
        icon: Icons.link,
        label: 'Copy link',
        onTap: () {
          Navigator.pop(context);
          if (onCopyLink != null) {
            onCopyLink!();
          }
        },
      ),
      _buildDivider(),
    ];

    // Delete option - only for post owners
    if (isOwner == true) {
      debugPrint("PostOptionsMenu: Adding DELETE option for owner");
      menuItems.add(
        _buildOption(
          context,
          icon: Icons.delete_outline,
          label: 'Delete Post',
          textColor: Colors.red,
          iconColor: Colors.red,
          onTap: () {
            Navigator.pop(context);
            _showDeleteConfirmation(context, operationsNotifier);
          },
        ),
      );
    } else {
      // Options for non-owners
      debugPrint("PostOptionsMenu: Adding HIDE option for non-owner");
      menuItems.add(
        _buildOption(
          context,
          icon: Icons.visibility_off_outlined,
          label: 'Hide Post',
          onTap: () {
            Navigator.pop(context);
            _hideContent(operationsNotifier);
          },
        ),
      );

      menuItems.add(_buildDivider());

      debugPrint("PostOptionsMenu: Adding REPORT option for non-owner");
      menuItems.add(
        _buildOption(
          context,
          icon: Icons.flag_outlined,
          label: 'Report Post',
          textColor: Colors.red,
          iconColor: Colors.red,
          onTap: () {
            Navigator.pop(context);
            _showReportDialog(context, operationsNotifier);
          },
        ),
      );
    }

    // Show error or success message if they exist
    if (operationsState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onError(operationsState.errorMessage!);
        operationsNotifier.clearMessages();
      });
    }

    if (operationsState.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSuccess(operationsState.successMessage!);
        operationsNotifier.clearMessages();
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: menuItems,
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Function onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColor.color0C1024,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor ?? AppColor.color0C1024,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFEEEEEE),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, ContentOperationsNotifier operationsNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContent(operationsNotifier);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteContent(ContentOperationsNotifier operationsNotifier) async {
    await operationsNotifier.deleteStory(contentId);
  }

  void _hideContent(ContentOperationsNotifier operationsNotifier) async {
    await operationsNotifier.hideContent(contentId);
  }

  void _showReportDialog(
      BuildContext context, ContentOperationsNotifier operationsNotifier) {
    showDialog(
      context: context,
      builder: (context) => ReportContentDialog(
        contentId: contentId,
        onReport: (request) async {
          Navigator.pop(context);
          await operationsNotifier.reportContent(request);
        },
      ),
    );
  }
}
