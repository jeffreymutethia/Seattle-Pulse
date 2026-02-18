import 'package:flutter/material.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/features/feed/models/content_operation_model.dart';

class ReportContentDialog extends StatefulWidget {
  final int contentId;
  final Function(ReportContentRequest) onReport;

  const ReportContentDialog({
    Key? key,
    required this.contentId,
    required this.onReport,
  }) : super(key: key);

  @override
  State<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  ReportReason? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _showCustomReasonField = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell us why you want to report this post',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            _buildReasonsList(),
            if (_showCustomReasonField) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customReasonController,
                decoration: const InputDecoration(
                  hintText: 'Please specify your reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.color4C68D5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonsList() {
    return SizedBox(
      height: 280,
      child: ListView(
        shrinkWrap: true,
        children: ReportReason.values.map((reason) {
          return RadioListTile<ReportReason>(
            title: Text(reason.label),
            value: reason,
            groupValue: _selectedReason,
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
                _showCustomReasonField = value == ReportReason.OTHER;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  void _submitReport() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for reporting this post'),
        ),
      );
      return;
    }

    if (_selectedReason == ReportReason.OTHER &&
        _customReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide details for your report'),
        ),
      );
      return;
    }

    final request = ReportContentRequest(
      contentId: widget.contentId,
      reason: _selectedReason!.value,
      customReason: _selectedReason == ReportReason.OTHER
          ? _customReasonController.text.trim()
          : null,
    );

    widget.onReport(request);
  }
}
