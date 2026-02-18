import time
from flask import current_app

def get_rekognition_client():
    return current_app.rekognition_client

def moderate_image(image_bytes, min_confidence=80):
    """
    Sync image moderation via DetectModerationLabels.
    Returns list of labels ≥ min_confidence.
    """
    client = get_rekognition_client()
    resp = client.detect_moderation_labels(
        Image={'Bytes': image_bytes},
        MinConfidence=min_confidence
    )
    return resp.get('ModerationLabels', [])

def start_video_moderation(s3_bucket, s3_key, min_confidence=80):
    """
    Kicks off an async video job (no SNS).
    Returns the JobId.
    """
    client = get_rekognition_client()
    resp = client.start_content_moderation(
        Video={'S3Object': {'Bucket': s3_bucket, 'Name': s3_key}},
        MinConfidence=min_confidence
    )
    return resp['JobId']

def get_video_moderation(job_id):
    """
    Polls GetContentModeration until job completes.
    Returns the full list of ModerationLabels.
    """
    client = get_rekognition_client()
    while True:
        resp = client.get_content_moderation(JobId=job_id, SortBy='TIMESTAMP')
        status = resp.get('JobStatus')
        if status in ('SUCCEEDED', 'FAILED'):
            break
        time.sleep(5)
    return resp.get('ModerationLabels', [])
