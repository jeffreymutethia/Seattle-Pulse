import logging
import uuid
from flask import Blueprint, request, jsonify, current_app
import boto3
from botocore.exceptions import ClientError
import os
from app.models import ContentReport, ReportReason
from utils.aws_rekognition import moderate_image, start_video_moderation
from app.extensions import db
from botocore.client import Config
from app.constants import ALLOWED_FILE_TYPES

# Initialize logger
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialize the blueprint
upload_v1_blueprint = Blueprint("upload_v1", __name__, url_prefix="/api/v1/upload")

# Initialize the S3 client (this example uses a global instance, but you'll use the one attached to your app)
s3_client = boto3.client('s3')

def validate_file_type(content_type):
    """
    Validate if the content type is in the allowed file types list.
    
    Args:
        content_type (str): The MIME type of the file
        
    Returns:
        bool: True if file type is allowed, False otherwise
    """
    return content_type.lower() in [t.lower() for t in ALLOWED_FILE_TYPES]

def get_post_image_bucket():
    app_env = current_app.config.get("APP_ENV", "local").lower()
    if app_env == "production":
        return "seattlepulse-production-user-post-images"
    elif app_env == "staging":
        return "seattlepulse-staging-user-post-images"
    else:
        return "seattlepulse-user-post-images"


def create_presigned_url(bucket_name, object_name, content_type, expiration=3600):
    s3 = current_app.s3_client
    try:
        return s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': object_name,
                'ContentType': content_type
            },
            ExpiresIn=expiration
        )
    except ClientError as e:
        logger.error(f"Error generating presigned URL: {e}")
        return None
    
    
@upload_v1_blueprint.route('/ping', methods=['GET'])
def upload_ping():
    s3 = current_app.s3_client
    try:
        buckets = [b["Name"] for b in s3.list_buckets().get("Buckets", [])]
        return jsonify({"success": True, "buckets": buckets}), 200
    except Exception as e:
        logger.error(f"Error listing buckets: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


@upload_v1_blueprint.route('/prepare', methods=['POST'])
def upload_prepare():
    data         = request.get_json() or {}
    filename     = data.get('filename')
    content_type = data.get('content_type')
    file_size    = data.get('file_size')

    # Validate inputs
    if not filename or not content_type or not file_size:
        return jsonify({"success": False, "error": "Invalid input"}), 400

    # Validate file type
    if not validate_file_type(content_type):
        return jsonify({
            "success": False, 
            "error": f"File type '{content_type}' is not allowed. Allowed types: {', '.join(ALLOWED_FILE_TYPES)}"
        }), 400

    # Generate S3 key & presigned URL
    s3_key = f"uploads/{uuid.uuid4()}_{filename}"
    bucket_name = get_post_image_bucket()
    presigned  = create_presigned_url(bucket_name, s3_key, content_type)
    if not presigned:
        return jsonify({"success": False, "error": "Could not generate upload URL"}), 500

    # Return key, URL, and carry content_id forward
    region = current_app.config["AWS_REGION"]
    file_url = f"https://{bucket_name}.s3.{region}.amazonaws.com/{s3_key}"
    return jsonify({
        "success"         : True,
        "presigned_url"   : presigned,
        "final_upload_key": s3_key,
        "file_url"        : file_url,
        "s3_bucket"       : bucket_name,
    }), 200
    

@upload_v1_blueprint.route('/complete', methods=['POST'])
def upload_complete():
    data         = request.get_json() or {}
    upload_key   = data.get('upload_key')
    content_id   = data.get('content_id')             # ← from /prepare
    metadata     = data.get('metadata', {})
    content_type = metadata.get('content_type')

    # 1) Validate inputs
    if not upload_key or content_id is None or not content_type:
        return jsonify({
            "success": False,
            "error"  : "Missing upload_key, content_id, or content_type"
        }), 400

    # Validate file type
    if not validate_file_type(content_type):
        return jsonify({
            "success": False, 
            "error": f"File type '{content_type}' is not allowed. Allowed types: {', '.join(ALLOWED_FILE_TYPES)}"
        }), 400

    # 2) Verify file exists in S3
    bucket_name = get_post_image_bucket()
    s3     = current_app.s3_client
    try:
        s3.head_object(Bucket=bucket_name, Key=upload_key)
    except ClientError as e:
        logger.error(f"Error verifying uploaded file: {e}")
        return jsonify({"success": False, "error": "File not found in S3"}), 404

    # 3) Moderate before finalizing
    # 3a) Image moderation
    if content_type.startswith("image/"):
        obj      = s3.get_object(Bucket=bucket_name, Key=upload_key)
        img_bytes= obj['Body'].read()
        
        # ✅ Log how many bytes were read for transparency
        logger.info(f"[Moderation] Read {len(img_bytes)} bytes from S3://{bucket_name}/{upload_key}")

        # ✅ Validate image is non-empty before Rekognition
        if not img_bytes or len(img_bytes) < 1:
            logger.error(f"[Moderation] Empty or unreadable image at S3://{bucket_name}/{upload_key}. Byte size: {len(img_bytes)}")
            return jsonify({
                "success": False,
                "error": "Uploaded file is empty or unreadable from S3"
            }), 400
    
        labels   = moderate_image(img_bytes)
        if labels:
            # Block & record report
            db.session.add(ContentReport(
                content_id   = content_id,
                reporter_id  = None,  # System/AWS-generated report, no human reporter
                reason       = ReportReason.AWS_FLAGGED,
                custom_reason= str(labels),
                aws_flagged  = True,
                aws_labels   = labels
            ))
            db.session.commit()
            return jsonify({
                "success"   : False,
                "message"   : "Image flagged by AWS",
                "aws_labels": labels
            }), 400

    # 3b) Video moderation (async stub)
    
    elif content_type.startswith("video/"):
        job_id = start_video_moderation(bucket_name, upload_key)
        # Persist stub report for later update
        db.session.add(ContentReport(
            content_id   = content_id,
            reporter_id  = None,  # System/AWS-generated report, no human reporter
            reason       = ReportReason.AWS_FLAGGED,
            custom_reason= None,
            aws_flagged  = False,
            aws_labels   = None,
            aws_job_id   = job_id
        ))
        db.session.commit()
        return jsonify({
            "success": True,
            "message": "Video moderation started",
            "job_id" : job_id
        }), 202

    # 4) No issues (or non-media)
    return jsonify({
        "success": True,
        "message": "Upload verified"
    }), 200
    
    
def upload_thumbnail(file_obj, filename):
    """
    Uploads the file to S3 using a dynamic bucket based on the environment.
    Returns the URL to the uploaded file.
    """
    # Determine bucket name based on environment (can be customized or set in config)
    # For this example, we'll assume the bucket is hard-coded for thumbnails.
    bucket_name = get_post_image_bucket()

    # Get the S3 client from the current app context
    s3_client = current_app.s3_client

    # Upload the file using the S3 client
    s3_client.upload_fileobj(file_obj, bucket_name, filename)

    # Depending on environment, build URL.
    # For LocalStack, we assume a local URL; for staging/production, use the standard S3 URL.
    app_env = current_app.config["APP_ENV"]
    if app_env == "local":
        # Example for LocalStack; this should match your LOCAL_S3_ENDPOINT_URL in .env
        base_url = os.getenv("LOCAL_S3_ENDPOINT_URL")
        # Sometimes LocalStack may require "http://" prefix
        file_url = f"{base_url}/{bucket_name}/{filename}"
    else:
        # For staging/production, the URL generally follows the AWS S3 virtual-hosted style
        region = current_app.config["AWS_REGION"]  # Load region from app config
        file_url = f"https://{bucket_name}.s3.{region}.amazonaws.com/{filename}"
    
    return file_url
