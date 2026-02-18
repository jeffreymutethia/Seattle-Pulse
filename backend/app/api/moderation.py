from flask import Blueprint, request, jsonify, current_app
from utils.aws_moderation import moderate_text
from app.models import UserContent, ContentReport, ReportReason
from app.extensions import db

moderation_v1 = Blueprint('moderation_v1', __name__, url_prefix='/api/v1/moderation')

@moderation_v1.route('/text', methods=['POST'])
def text_moderate():
    """
    Endpoint: POST /api/v1/moderation/text
    Body: { "content_id": <int>, "text": "<the user-submitted text>" }
    Returns: 200 + { aws_flagged: bool, aws_labels: [...] }
    """
    data = request.get_json()
    content_id = data.get('content_id')
    text       = data.get('text', '')

    # 1) run AWS moderation
    aws_labels  = moderate_text(text)
    aws_flagged = bool(aws_labels)

    # 2) if you passed in content_id, record an AWS flag report
    if content_id and aws_flagged:
        report = ContentReport(
            content_id  = content_id,
            reporter_id = None,  # system
            reason      = ReportReason.AWS_FLAGGED,
            custom_reason = str(aws_labels),
            aws_flagged  = True,
            aws_labels   = aws_labels
        )
        db.session.add(report)
        db.session.commit()

    return jsonify({
        "aws_flagged": aws_flagged,
        "aws_labels" : aws_labels
    }), (400 if aws_flagged else 200)
