from flask import Blueprint, request, jsonify, current_app
from utils.aws_rekognition import (
    moderate_image,
    start_video_moderation,
    get_video_moderation
)
from app.models import ContentReport, ReportReason
from app.extensions import db

media_moderation_v1 = Blueprint('media_moderation_v1', __name__, url_prefix='/api/v1/moderation')

@media_moderation_v1.route('/image', methods=['POST'])
def image_moderate():
    """
    POST /api/v1/moderation/image
    Form-data: file=<image>, optional: content_id=<int>
    """
    file       = request.files.get('file')
    content_id = request.form.get('content_id', type=int)
    img_bytes  = file.read()

    labels = moderate_image(img_bytes)
    flagged = bool(labels)

    if content_id and flagged:
        db.session.add(ContentReport(
            content_id   = content_id,
            reporter_id  = None,
            reason       = ReportReason.AWS_FLAGGED,
            custom_reason= str(labels),
            aws_flagged  = True,
            aws_labels   = labels
        ))
        db.session.commit()

    return jsonify(aws_flagged=flagged, aws_labels=labels), (400 if flagged else 200)


@media_moderation_v1.route('/video', methods=['POST'])
def video_moderate_start():
    """
    POST /api/v1/moderation/video
    JSON: { "s3_bucket": str, "s3_key": str, "content_id": int }
    Kicks off the job, returns job_id, and records a stub report.
    """
    data       = request.get_json()
    bucket     = data['s3_bucket']
    key        = data['s3_key']
    content_id = data.get('content_id')
    if content_id is None:
        return jsonify(error="content_id is required"), 400

    # 1) start the AWS video moderation job
    job_id = start_video_moderation(bucket, key)

    # 2) persist a stub ContentReport so we remember content_id ↔ job_id
    report = ContentReport(
        content_id   = content_id,
        reporter_id  = None,
        reason       = ReportReason.AWS_FLAGGED,
        custom_reason= None,
        aws_flagged  = False,
        aws_labels   = None,
        aws_job_id   = job_id
    )
    db.session.add(report)
    db.session.commit()

    return jsonify(job_id=job_id), 200


@media_moderation_v1.route('/video/<job_id>', methods=['GET'])
def video_moderate_get(job_id):
    """
    GET /api/v1/moderation/video/<job_id>
    Polls for job completion, updates the existing report, and returns labels.
    """
    # 1) Lookup the stub report we created earlier
    report = ContentReport.query.filter_by(aws_job_id=job_id).first()
    if not report:
        return jsonify(error="Unknown job_id"), 404

    # 2) poll AWS for final labels
    labels = get_video_moderation(job_id)
    flagged = bool(labels)

    # 3) update our report row
    report.aws_flagged = flagged
    report.aws_labels = labels
    db.session.commit()

    return jsonify(aws_flagged=flagged, aws_labels=labels), (400 if flagged else 200)
