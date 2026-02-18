class ContentOperationResponse {
  final String status;
  final String message;
  final Map<String, dynamic>? data;

  ContentOperationResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ContentOperationResponse.fromJson(Map<String, dynamic> json) {
    return ContentOperationResponse(
      status: json['status'] ?? json['success'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class ReportContentRequest {
  final int contentId;
  final String reason;
  final String? customReason;

  ReportContentRequest({
    required this.contentId,
    required this.reason,
    this.customReason,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'content_id': contentId.toString(),
      'reason': reason,
    };

    if (customReason != null && customReason!.isNotEmpty) {
      data['custom_reason'] = customReason;
    }

    return data;
  }
}

enum ReportReason {
  SPAM,
  HARASSMENT,
  VIOLENCE,
  INAPPROPRIATE_LANGUAGE,
  HATE_SPEECH,
  SEXUAL_CONTENT,
  FALSE_INFORMATION,
  OTHER,
}

extension ReportReasonExtension on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.SPAM:
        return 'Spam';
      case ReportReason.HARASSMENT:
        return 'Harassment';
      case ReportReason.VIOLENCE:
        return 'Violence';
      case ReportReason.INAPPROPRIATE_LANGUAGE:
        return 'Inappropriate Language';
      case ReportReason.HATE_SPEECH:
        return 'Hate Speech';
      case ReportReason.SEXUAL_CONTENT:
        return 'Sexual Content';
      case ReportReason.FALSE_INFORMATION:
        return 'False Information';
      case ReportReason.OTHER:
        return 'Other';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}
